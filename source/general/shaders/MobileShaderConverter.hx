package general.shaders;

/** Sources prepared for the OpenFL GL program cache and compiler. */
typedef MobileShaderProgramSources =
{
	var vertex:String;
	var fragment:String;
	var cacheKey:String;
	var targetVersion:Int;
	var diagnostics:Array<MobileShaderDiagnostic>;
}

typedef MobileShaderDiagnostic =
{
	var stage:String;
	var line:Int;
	var message:String;
}

private typedef MobileShaderStageResult =
{
	var source:String;
	var diagnostics:Array<MobileShaderDiagnostic>;
}

private typedef MobileShaderToken =
{
	var text:String;
	var replacement:Null<String>;
	var kind:Int;
	var line:Int;
	var preprocessor:Bool;
	var removed:Bool;
	var braceDepth:Int;
	var parenDepth:Int;
	var bracketDepth:Int;
}

private typedef MobileShaderGlobalInitializer =
{
	var name:String;
	var equalsIndex:Int;
	var semicolonIndex:Int;
	var expressionStart:Int;
	var line:Int;
}

private typedef MobileShaderEntryPoint =
{
	var nameIndex:Int;
	var conditionalDepth:Int;
}

private typedef MobileShaderEntryPointAnalysis =
{
	var entryPoints:Array<MobileShaderEntryPoint>;
	var ambiguous:Bool;
}

private typedef MobileShaderGlobalInitLowering =
{
	var initializers:Array<MobileShaderGlobalInitializer>;
	var helperNames:Array<String>;
	var guardNames:Array<String>;
}

/**
 * Converts OpenFL's final, pragma-expanded GLSL program to the ESSL version
 * accepted by the current mobile GL context.
 *
 * This is deliberately a strict lexical/declaration converter. It converts
 * syntax only when the target has equivalent semantics. Unsupported desktop
 * features are left visible to the driver and accompanied by precise source
 * diagnostics instead of being approximated into a visually wrong shader.
 */
class MobileShaderConverter
{
	public static inline var ABI_VERSION:Int = 3;

	public static var enabled(default, null):Bool = true;
	public static var revision(default, null):Int = 1;

	private static inline var IDENTIFIER:Int = 0;
	private static inline var NUMBER:Int = 1;
	private static inline var SYMBOL:Int = 2;
	private static inline var WHITESPACE:Int = 3;
	private static inline var COMMENT:Int = 4;
	private static inline var STRING:Int = 5;

	private static var contextSignature:String = '';
	private static var contextObject:Dynamic;
	private static var contextVersion:Float = 0;
	private static var fragmentHighp:Bool = true;
	private static var extensions:Map<String, Bool> = new Map();

	public static function setEnabled(value:Bool):Void
	{
		if (enabled == value) return;
		enabled = value;
		revision++;
	}

	public static function hasContextCapabilities(version:Float):Bool
	{
		return contextSignature.length > 0 && contextVersion == version;
	}

	public static function setContextCapabilities(version:Float, supportedExtensions:Array<String>, supportsFragmentHighp:Bool):Void
	{
		var normalized:Array<String> = [];
		if (supportedExtensions != null)
		{
			for (extension in supportedExtensions)
			{
				if (extension == null || extension.length == 0) continue;
				var extensionName = normalizeExtensionName(extension);
				if (extensionName.length == 0 || normalized.contains(extensionName)) continue;
				normalized.push(extensionName);
			}
		}
		normalized.sort(function(a:String, b:String):Int return a < b ? -1 : (a > b ? 1 : 0));

		var signature = version + '|' + supportsFragmentHighp + '|' + normalized.join(',');
		if (signature == contextSignature) return;

		contextSignature = signature;
		contextVersion = version;
		fragmentHighp = supportsFragmentHighp;
		extensions = new Map();
		for (extension in normalized)
			extensions.set(extension, true);
		revision++;
	}

	/** Capture capabilities once for the active Lime GL context. */
	public static function configureFromGL(gl:Dynamic):Float
	{
		if (gl == null) return contextVersion > 0 ? contextVersion : 2;
		var glVersion = readContextVersion(gl);
		if (contextObject == gl && hasContextCapabilities(glVersion)) return glVersion;
		var contextChanged = contextObject != gl;
		contextObject = gl;

		var supportedExtensions:Array<String> = [];
		try
		{
			supportedExtensions = gl.getSupportedExtensions();
		}
		catch (_:Dynamic) {}

		var supportsFragmentHighp = glVersion >= 3;
		if (!supportsFragmentHighp)
		{
			try
			{
				var format:Dynamic = gl.getShaderPrecisionFormat(gl.FRAGMENT_SHADER, gl.HIGH_FLOAT);
				supportsFragmentHighp = format != null && format.precision > 0;
			}
			catch (_:Dynamic) {}
		}

		var previousSignature = contextSignature;
		setContextCapabilities(glVersion, supportedExtensions, supportsFragmentHighp);
		// A recreated GL context can expose the same version/extensions but all
		// native Program objects still belong to the old context.
		if (contextChanged && contextSignature == previousSignature) revision++;
		return glVersion;
	}

	private static function readContextVersion(gl:Dynamic):Float
	{
		var result = Math.NaN;
		try
		{
			var value:Dynamic = Reflect.field(gl, 'version');
			if (value != null) result = Std.parseFloat(Std.string(value));
		}
		catch (_:Dynamic) {}

		if (Math.isNaN(result) || result <= 0)
		{
			try
			{
				var versionString = Std.string(gl.getParameter(gl.VERSION));
				var versionPattern = ~/[0-9]+(?:\.[0-9]+)?/;
				if (versionPattern.match(versionString)) result = Std.parseFloat(versionPattern.matched(0));
			}
			catch (_:Dynamic) {}
		}
		return Math.isNaN(result) || result <= 0 ? 2 : result;
	}

	public static function prepareProgram(vertexSource:String, fragmentSource:String, glVersion:Float):MobileShaderProgramSources
	{
		if (!enabled)
		{
			return {
				vertex: vertexSource,
				fragment: fragmentSource,
				cacheKey: 'novaflare-glsl-raw-v$ABI_VERSION',
				targetVersion: 0,
				diagnostics: []
			};
		}

		var targetVersion:Int = glVersion >= 3 ? 300 : 100;
		var vertex = convertStage(vertexSource, false, targetVersion);
		var fragment = convertStage(fragmentSource, true, targetVersion);
		var diagnostics = vertex.diagnostics.concat(fragment.diagnostics);

		return {
			vertex: vertex.source,
			fragment: fragment.source,
			cacheKey: 'novaflare-glsl-es-$targetVersion-v$ABI_VERSION-hp' + (fragmentHighp ? '1' : '0'),
			targetVersion: targetVersion,
			diagnostics: diagnostics
		};
	}

	private static function convertStage(source:String, isFragment:Bool, targetVersion:Int):MobileShaderStageResult
	{
		if (source == null) source = '';
		source = StringTools.replace(StringTools.replace(source, '\r\n', '\n'), '\r', '\n');
		if (source.length > 0 && StringTools.fastCodeAt(source, 0) == 0xFEFF)
			source = source.substr(1);
		var targetDirective = targetVersion >= 300 ? '#version 300 es\n' : '#version 100\n';
		var convertedMarker = '// NovaFlare mobile GLSL ABI $ABI_VERSION target $targetVersion\n';
		if (StringTools.startsWith(source, targetDirective + convertedMarker))
			return {source: source, diagnostics: []};

		var stage = isFragment ? 'fragment' : 'vertex';
		var diagnostics:Array<MobileShaderDiagnostic> = [];
		var tokens = tokenize(source);
		assignDepths(tokens);
		var macroNames = collectMacroNames(tokens);
		diagnoseMacroGeneratedGlobalDeclarations(tokens, targetVersion, stage, diagnostics);
		var entryPointAnalysis = collectEntryPoints(tokens);
		var entryPoints = entryPointAnalysis.entryPoints;
		var canWrapEntryPoint = !entryPointAnalysis.ambiguous && entryPoints.length == 1
			&& entryPoints[0].conditionalDepth == 0;
		var globalInitializers = collectGlobalRuntimeInitializers(tokens, macroNames, stage, diagnostics);

		var extensionLines = extractVersionAndExtensions(tokens, targetVersion, stage, diagnostics);
		var generatedHeader:Array<String> = [];
		var generatedFooter:Array<String> = [];

		var es100FragmentOutput:Null<String> = null;
		if (targetVersion >= 300)
			convertToES300(tokens, isFragment, macroNames, generatedHeader, diagnostics);
		else
			es100FragmentOutput = convertToES100(tokens, isFragment, macroNames, extensionLines, generatedHeader,
				canWrapEntryPoint, diagnostics);

		var loweredInitializers = lowerGlobalRuntimeInitializers(tokens, globalInitializers, entryPoints, canWrapEntryPoint,
			stage, diagnostics);
		emitEntryPointWrapper(tokens, entryPoints, canWrapEntryPoint, loweredInitializers, es100FragmentOutput,
			generatedFooter, stage, diagnostics);

		var output = new StringBuf();
		output.add(targetDirective);
		output.add(convertedMarker);
		for (line in extensionLines)
			output.add(line + '\n');

		var precision = targetVersion >= 300 || !isFragment || fragmentHighp ? 'highp' : 'mediump';
		output.add('precision $precision float;\n');
		output.add('precision $precision int;\n');
		output.add('precision lowp sampler2D;\n');
		output.add('precision lowp samplerCube;\n');

		for (line in generatedHeader)
			output.add(line + '\n');

		for (diagnostic in diagnostics)
			output.add('// NovaFlare ES conversion [${diagnostic.stage}:${diagnostic.line}]: ${sanitizeComment(diagnostic.message)}\n');

		// Keep driver diagnostics aligned with the pragma-expanded input.
		output.add('#line 1\n');
		output.add(render(tokens));
		for (line in generatedFooter)
			output.add(line + '\n');

		return {source: output.toString(), diagnostics: diagnostics};
	}

	private static function collectEntryPoints(tokens:Array<MobileShaderToken>):MobileShaderEntryPointAnalysis
	{
		var result:Array<MobileShaderEntryPoint> = [];
		var ambiguous = false;
		var macroTargets:Map<String, Array<String>> = new Map();
		var macroMayBeUndefined:Map<String, Bool> = new Map();
		var conditionalDepth = 0;

		for (i in 0...tokens.length)
		{
			var token = tokens[i];
			if (token.preprocessor && token.kind == SYMBOL && token.text == '#')
			{
				var directiveIndex = nextSignificantInDirective(tokens, i);
				if (directiveIndex < 0) continue;
				var directive = tokenValue(tokens[directiveIndex]);
				if (directive == 'endif')
				{
					if (conditionalDepth > 0) conditionalDepth--;
					continue;
				}

				if (directive == 'define' || directive == 'undef')
				{
					var nameIndex = nextSignificantInDirective(tokens, directiveIndex);
					if (nameIndex >= 0 && tokens[nameIndex].kind == IDENTIFIER)
					{
						var name = tokenValue(tokens[nameIndex]);
						if (directive == 'undef')
						{
							if (conditionalDepth == 0) macroTargets.remove(name);
							macroMayBeUndefined.set(name, true);
						}
						else
						{
							var bodyIndex = nextSignificantInDirective(tokens, nameIndex);
							var functionLike = bodyIndex >= 0 && bodyIndex == nameIndex + 1
								&& tokenValue(tokens[bodyIndex]) == '(';
							var simpleTarget:Null<String> = null;
							if (!functionLike && bodyIndex >= 0 && tokens[bodyIndex].kind == IDENTIFIER
								&& nextSignificantInDirective(tokens, bodyIndex) < 0)
								simpleTarget = tokenValue(tokens[bodyIndex]);

							if (conditionalDepth == 0)
							{
								if (simpleTarget == null)
									macroTargets.set(name, []);
								else
									macroTargets.set(name, [simpleTarget]);
								macroMayBeUndefined.set(name, false);
							}
							else
							{
								var hadKnownState = macroTargets.exists(name) || macroMayBeUndefined.exists(name);
								if (simpleTarget != null)
								{
									var targets = macroTargets.get(name);
									if (targets == null)
									{
										targets = [];
										macroTargets.set(name, targets);
									}
									if (!targets.contains(simpleTarget)) targets.push(simpleTarget);
								}
								if (!hadKnownState) macroMayBeUndefined.set(name, true);
							}
						}
					}
				}

				if (directive == 'if' || directive == 'ifdef' || directive == 'ifndef') conditionalDepth++;
				continue;
			}

			if (token.removed || token.preprocessor || token.kind != IDENTIFIER
				|| token.braceDepth != 0 || token.parenDepth != 0) continue;
			var returnType = previousSignificant(tokens, i);
			var open = nextSignificant(tokens, i);
			if (returnType < 0 || tokenValue(tokens[returnType]) != 'void' || open < 0 || tokenValue(tokens[open]) != '(') continue;
			var close = findMatching(tokens, open, '(', ')');
			var parameter = close >= 0 ? nextSignificant(tokens, open) : -1;
			if (close < 0 || (parameter != close && (parameter < 0 || tokenValue(tokens[parameter]) != 'void'
				|| nextSignificant(tokens, parameter) != close))) continue;
			var body = close >= 0 ? nextSignificant(tokens, close) : -1;
			if (body < 0 || tokenValue(tokens[body]) != '{'
				|| !canExpandToMain(token.text, macroTargets, macroMayBeUndefined, new Map())) continue;
			if (!expandsOnlyToMain(token.text, macroTargets, macroMayBeUndefined, new Map()))
			{
				ambiguous = true;
				continue;
			}
			result.push({nameIndex: i, conditionalDepth: conditionalDepth});
		}
		return {entryPoints: result, ambiguous: ambiguous};
	}

	private static function canExpandToMain(name:String, macroTargets:Map<String, Array<String>>,
		macroMayBeUndefined:Map<String, Bool>, visiting:Map<String, Bool>):Bool
	{
		if (visiting.exists(name)) return false;
		visiting.set(name, true);
		var targets = macroTargets.get(name);
		var mayRemain = targets == null || macroMayBeUndefined.get(name) == true;
		if (mayRemain && name == 'main') return true;
		if (targets != null)
		{
			for (target in targets)
				if (canExpandToMain(target, macroTargets, macroMayBeUndefined, visiting)) return true;
		}
		visiting.remove(name);
		return false;
	}

	private static function expandsOnlyToMain(name:String, macroTargets:Map<String, Array<String>>,
		macroMayBeUndefined:Map<String, Bool>, visiting:Map<String, Bool>):Bool
	{
		if (visiting.exists(name)) return false;
		visiting.set(name, true);
		var targets = macroTargets.get(name);
		var mayRemain = targets == null || macroMayBeUndefined.get(name) == true;
		if (mayRemain && name != 'main') return false;
		if (!mayRemain && (targets == null || targets.length == 0)) return false;
		if (targets != null)
		{
			for (target in targets)
				if (!expandsOnlyToMain(target, macroTargets, macroMayBeUndefined, visiting)) return false;
		}
		visiting.remove(name);
		return true;
	}

	private static function collectConditionalDepths(tokens:Array<MobileShaderToken>):Array<Int>
	{
		var result = [for (_ in 0...tokens.length) 0];
		var depth = 0;
		for (i in 0...tokens.length)
		{
			var token = tokens[i];
			if (token.preprocessor && token.kind == SYMBOL && token.text == '#')
			{
				var directiveIndex = nextSignificantInDirective(tokens, i);
				var directive = directiveIndex >= 0 ? tokenValue(tokens[directiveIndex]) : '';
				if (directive == 'endif' && depth > 0) depth--;
				result[i] = depth;
				if (directive == 'if' || directive == 'ifdef' || directive == 'ifndef') depth++;
			}
			else
				result[i] = depth;
		}
		return result;
	}

	private static function collectGlobalRuntimeInitializers(tokens:Array<MobileShaderToken>, macroNames:Map<String, Bool>, stage:String,
		diagnostics:Array<MobileShaderDiagnostic>):Array<MobileShaderGlobalInitializer>
	{
		var result:Array<MobileShaderGlobalInitializer> = [];
		var i = 0;
		while (i < tokens.length)
		{
			var token = tokens[i];
			if (token.removed || token.preprocessor || token.kind != SYMBOL || token.text != '='
				|| token.braceDepth != 0 || token.parenDepth != 0 || token.bracketDepth != 0)
			{
				i++;
				continue;
			}

			var previous = previousSignificant(tokens, i);
			var next = nextSignificant(tokens, i);
			if ((previous >= 0 && tokenValue(tokens[previous]) == '=') || (next >= 0 && tokenValue(tokens[next]) == '='))
			{
				i++;
				continue;
			}

			var semicolon = findGlobalStatementEnd(tokens, i);
			if (semicolon < 0) break;
			var conditionalExpression = false;
			for (j in (i + 1)...semicolon)
			{
				if (!tokens[j].preprocessor || tokens[j].kind != SYMBOL || tokens[j].text != '#') continue;
				var directiveIndex = nextSignificantInDirective(tokens, j);
				var directive = directiveIndex >= 0 ? tokenValue(tokens[directiveIndex]) : '';
				if (directive == 'if' || directive == 'ifdef' || directive == 'ifndef' || directive == 'elif'
					|| directive == 'else' || directive == 'endif')
				{
					conditionalExpression = true;
					break;
				}
			}
			if (conditionalExpression)
			{
				addDiagnostic(diagnostics, stage, token.line,
					'Conditional preprocessor branches inside a global initializer cannot be lowered atomically');
				i = semicolon + 1;
				continue;
			}
			var nameIndex = previous;
			var statementStart = findGlobalStatementStart(tokens, i);
			var declarationStarted = false;
			var fragmentedDeclaration = false;
			for (j in statementStart...i)
			{
				var declarationToken = tokens[j];
				if (declarationToken.preprocessor)
				{
					if (declarationToken.kind != SYMBOL || declarationToken.text != '#') continue;
					var directiveIndex = nextSignificantInDirective(tokens, j);
					var directive = directiveIndex >= 0 ? tokenValue(tokens[directiveIndex]) : '';
					if (declarationStarted && (directive == 'if' || directive == 'ifdef' || directive == 'ifndef'
						|| directive == 'elif' || directive == 'else' || directive == 'endif'))
					{
						fragmentedDeclaration = true;
						break;
					}
				}
				else if (!declarationToken.removed && declarationToken.kind != WHITESPACE && declarationToken.kind != COMMENT)
					declarationStarted = true;
			}
			if (fragmentedDeclaration)
			{
				addDiagnostic(diagnostics, stage, token.line,
					'Preprocessor branches that split a global declaration cannot be lowered atomically');
				i = semicolon + 1;
				continue;
			}
			if (nameIndex < statementStart || nameIndex < 0 || tokens[nameIndex].kind != IDENTIFIER)
			{
				var previousValue = nameIndex >= 0 ? tokenValue(tokens[nameIndex]) : '';
				addDiagnostic(diagnostics, stage, token.line, previousValue == ']'
					? 'Global array runtime initializers cannot be lowered exactly on both ES 2 and ES 3'
					: 'Could not parse this global runtime initializer safely');
				i = semicolon + 1;
				continue;
			}

			var declarationIdentifierCount = 0;
			var blockedStorage = false;
			var macroQualifiedDeclaration = false;
			var complexDeclaration = false;
			for (j in statementStart...(nameIndex + 1))
			{
				var declarationToken = tokens[j];
				if (declarationToken.preprocessor || declarationToken.removed) continue;
				var value = tokenValue(declarationToken);
				if (declarationToken.kind == IDENTIFIER)
				{
					if (j < nameIndex && macroNames.exists(declarationToken.text)) macroQualifiedDeclaration = true;
					if (value == 'const' || value == 'uniform' || value == 'attribute' || value == 'varying' || value == 'in'
						|| value == 'buffer' || value == 'shared' || value == 'readonly' || value == 'writeonly') blockedStorage = true;
					if (!isPrecision(value) && value != 'invariant' && value != 'precise' && value != 'centroid'
						&& value != 'flat' && value != 'smooth' && value != 'noperspective' && value != 'layout') declarationIdentifierCount++;
				}
			}
			for (j in statementStart...semicolon)
			{
				var declarationToken = tokens[j];
				if (!declarationToken.preprocessor && !declarationToken.removed && declarationToken.kind == SYMBOL
					&& tokenValue(declarationToken) == ',' && declarationToken.braceDepth == 0
					&& declarationToken.parenDepth == 0 && declarationToken.bracketDepth == 0)
					complexDeclaration = true;
			}

			if (!blockedStorage && declarationIdentifierCount >= 2)
			{
				if (macroQualifiedDeclaration)
				{
					addDiagnostic(diagnostics, stage, token.line,
						'Macro-qualified global declarations cannot be lowered without changing storage semantics');
				}
				else if (complexDeclaration)
				{
					addDiagnostic(diagnostics, stage, token.line,
						'Multiple global declarators with runtime initializers cannot be lowered safely');
				}
				else if (next >= 0 && next < semicolon)
				{
					result.push({
						name: tokenValue(tokens[nameIndex]),
						equalsIndex: i,
						semicolonIndex: semicolon,
						expressionStart: i + 1,
						line: token.line
					});
				}
			}
			i = semicolon + 1;
		}
		return result;
	}

	private static function findGlobalStatementStart(tokens:Array<MobileShaderToken>, index:Int):Int
	{
		var i = index - 1;
		while (i >= 0)
		{
			var token = tokens[i];
			if (!token.preprocessor && token.kind == SYMBOL)
			{
				if (token.text == ';' && token.braceDepth == 0 && token.parenDepth == 0) return i + 1;
				if (token.text == '}' && token.braceDepth == 1 && token.parenDepth == 0) return i + 1;
			}
			i--;
		}
		return 0;
	}

	private static function findGlobalStatementEnd(tokens:Array<MobileShaderToken>, index:Int):Int
	{
		for (i in (index + 1)...tokens.length)
		{
			var token = tokens[i];
			if (!token.preprocessor && !token.removed && token.kind == SYMBOL && token.text == ';'
				&& token.braceDepth == 0 && token.parenDepth == 0 && token.bracketDepth == 0) return i;
		}
		return -1;
	}

	private static function lowerGlobalRuntimeInitializers(tokens:Array<MobileShaderToken>,
		initializers:Array<MobileShaderGlobalInitializer>, entryPoints:Array<MobileShaderEntryPoint>, canWrapEntryPoint:Bool,
		stage:String, diagnostics:Array<MobileShaderDiagnostic>):MobileShaderGlobalInitLowering
	{
		var empty:MobileShaderGlobalInitLowering = {initializers: [], helperNames: [], guardNames: []};
		if (initializers.length == 0) return empty;
		if (!canWrapEntryPoint)
		{
			addDiagnostic(diagnostics, stage, initializers[0].line,
				'Runtime global initializers require one unconditional, unambiguous `main` entry point');
			return empty;
		}

		var lowered:Array<MobileShaderGlobalInitializer> = [];
		var helperNames:Array<String> = [];
		var guardNames:Array<String> = [];
		for (index in 0...initializers.length)
		{
			var initializer = initializers[index];
			var expression = renderRange(tokens, initializer.expressionStart, initializer.semicolonIndex);
			if (StringTools.trim(expression).length == 0) continue;
			var helperName = uniqueIdentifier(tokens, 'novaflare_global_init_$index');
			var guardName = uniqueIdentifier(tokens, 'NOVAFLARE_GLOBAL_INIT_$index');

			var definition = new StringBuf();
			definition.add('\nvoid $helperName(void)\n{\n');
			definition.add('#line ${initializer.line}\n');
			definition.add('${initializer.name} =\n');
			definition.add('#line ${initializer.line}\n');
			definition.add(expression);
			if (!StringTools.endsWith(expression, '\n')) definition.add('\n');
			definition.add(';\n}\n');
			definition.add('#define $guardName 1\n');

			var declarationResume = nextSignificant(tokens, initializer.semicolonIndex);
			if (declarationResume >= 0)
			{
				definition.add('#line ${tokens[declarationResume].line}\n');
				tokens[declarationResume].replacement = definition.toString() + tokenValue(tokens[declarationResume]);
			}
			else
				tokens[initializer.semicolonIndex].replacement = tokenValue(tokens[initializer.semicolonIndex]) + definition.toString();

			lowered.push(initializer);
			helperNames.push(helperName);
			guardNames.push(guardName);
		}

		for (initializer in lowered)
			for (i in initializer.equalsIndex...initializer.semicolonIndex)
				tokens[i].removed = true;
		return {initializers: lowered, helperNames: helperNames, guardNames: guardNames};
	}

	private static function emitEntryPointWrapper(tokens:Array<MobileShaderToken>, entryPoints:Array<MobileShaderEntryPoint>,
		canWrapEntryPoint:Bool, lowering:MobileShaderGlobalInitLowering, es100FragmentOutput:Null<String>,
		generatedFooter:Array<String>, stage:String, diagnostics:Array<MobileShaderDiagnostic>):Void
	{
		if (lowering.initializers.length == 0 && es100FragmentOutput == null) return;
		if (!canWrapEntryPoint) return;
		var originalMain = uniqueIdentifier(tokens, 'novaflare_original_main');
		if (!renameEntryPoints(tokens, entryPoints, originalMain))
		{
			addDiagnostic(diagnostics, stage, 1, 'Could not wrap the converted `main` entry point safely');
			return;
		}

		generatedFooter.push('');
		// A source macro named `main` must not rewrite the generated canonical entry.
		generatedFooter.push('#undef main');
		generatedFooter.push('void main(void)');
		generatedFooter.push('{');
		for (index in 0...lowering.initializers.length)
		{
			generatedFooter.push('#ifdef ${lowering.guardNames[index]}');
			generatedFooter.push('    ${lowering.helperNames[index]}();');
			generatedFooter.push('#endif');
		}
		generatedFooter.push('    $originalMain();');
		if (es100FragmentOutput != null)
			generatedFooter.push('    gl_FragColor = $es100FragmentOutput;');
		generatedFooter.push('}');
	}

	private static function convertToES300(tokens:Array<MobileShaderToken>, isFragment:Bool, macroNames:Map<String, Bool>,
		generatedHeader:Array<String>, diagnostics:Array<MobileShaderDiagnostic>):Void
	{
		diagnoseES300Layouts(tokens, isFragment, diagnostics);
		var fragmentOutputName:String = null;
		var explicitFragmentOutputCount = isFragment ? countGlobalFragmentOutputs(tokens) : 0;
		var hasExplicitFragmentOutput = explicitFragmentOutputCount > 0;
		if (explicitFragmentOutputCount > 1)
			addDiagnostic(diagnostics, 'fragment', 1,
				'OpenFL exposes one color attachment; multiple explicit fragment outputs cannot be preserved');
		var textureMap:Map<String, String> = [
			'texture2D' => 'texture',
			'textureCube' => 'texture',
			'texture2DProj' => 'textureProj',
			'texture2DLod' => 'textureLod',
			'textureCubeLod' => 'textureLod',
			'texture2DProjLod' => 'textureProjLod',
			'texture2DLodEXT' => 'textureLod',
			'textureCubeLodEXT' => 'textureLod',
			'texture2DProjLodEXT' => 'textureProjLod',
			'texture2DGradEXT' => 'textureGrad',
			'textureCubeGradEXT' => 'textureGrad',
			'texture2DProjGradEXT' => 'textureProjGrad'
		];

		for (i in 0...tokens.length)
		{
			var token = tokens[i];
			if (token.removed || token.kind != IDENTIFIER || !canTransform(tokens, i)) continue;

			switch (token.text)
			{
				case 'in', 'out':
					if (token.braceDepth == 0 && token.parenDepth == 0 && isInterfaceBlockQualifier(tokens, i))
						addDiagnostic(diagnostics, isFragment ? 'fragment' : 'vertex', token.line,
							'GLSL ES 3.00 has no shader input/output interface-block equivalent');

				case 'attribute':
					if (isFragment)
						addDiagnostic(diagnostics, 'fragment', token.line, '`attribute` is only valid in a vertex shader');
					else
						token.replacement = 'in';

				case 'varying':
					token.replacement = isFragment ? 'in' : 'out';

				case 'gl_FragColor':
					if (!isFragment)
					{
						addDiagnostic(diagnostics, 'vertex', token.line, '`gl_FragColor` is not available in a vertex shader');
					}
					else if (hasExplicitFragmentOutput)
					{
						addDiagnostic(diagnostics, 'fragment', token.line,
							'Legacy `gl_FragColor` and an explicit fragment output cannot be mixed safely');
					}
					else
					{
						if (fragmentOutputName == null)
							fragmentOutputName = uniqueIdentifier(tokens, 'novaflare_FragColor');
						token.replacement = fragmentOutputName;
					}

				case 'gl_FragData':
					if (!isFragment)
						addDiagnostic(diagnostics, 'vertex', token.line, '`gl_FragData` is not available in a vertex shader');
					else if (hasExplicitFragmentOutput)
						addDiagnostic(diagnostics, 'fragment', token.line,
							'Legacy `gl_FragData` and an explicit fragment output cannot be mixed safely');
					else if (isConstantFragDataZero(tokens, i))
					{
						if (fragmentOutputName == null)
							fragmentOutputName = uniqueIdentifier(tokens, 'novaflare_FragColor');
						token.replacement = fragmentOutputName;
						removeFragDataZeroIndex(tokens, i);
					}
					else
						addDiagnostic(diagnostics, 'fragment', token.line,
							'OpenFL exposes one color attachment; only constant `gl_FragData[0]` can be converted');

				case 'gl_FragDepthEXT':
					if (isFragment) token.replacement = 'gl_FragDepth';

				case 'noperspective':
					addDiagnostic(diagnostics, isFragment ? 'fragment' : 'vertex', token.line,
						'GLSL ES 3.00 has no core `noperspective` equivalent');

				case 'sampler1D', 'sampler1DShadow', 'sampler2DRect', 'sampler2DRectShadow', 'samplerBuffer', 'sampler2DMS',
					'double', 'dvec2', 'dvec3', 'dvec4', 'dmat2', 'dmat3', 'dmat4':
					addDiagnostic(diagnostics, isFragment ? 'fragment' : 'vertex', token.line,
						'`${token.text}` has no equivalent type in GLSL ES 3.00');

				case 'shadow1D', 'shadow2D', 'shadow1DProj', 'shadow2DProj', 'texture1D', 'texture1DProj', 'texture2DRect':
					addDiagnostic(diagnostics, isFragment ? 'fragment' : 'vertex', token.line,
						'`${token.text}` has no exact GLSL ES 3.00 texture-function equivalent');

				case 'gl_Vertex', 'gl_Normal', 'gl_Color', 'gl_SecondaryColor', 'gl_MultiTexCoord0', 'gl_MultiTexCoord1',
					'gl_MultiTexCoord2', 'gl_MultiTexCoord3', 'gl_MultiTexCoord4', 'gl_MultiTexCoord5', 'gl_MultiTexCoord6',
					'gl_MultiTexCoord7', 'gl_ModelViewMatrix', 'gl_ProjectionMatrix', 'gl_ModelViewProjectionMatrix',
					'gl_NormalMatrix', 'gl_TextureMatrix', 'gl_TexCoord', 'gl_FrontColor', 'gl_BackColor', 'ftransform':
					addDiagnostic(diagnostics, isFragment ? 'fragment' : 'vertex', token.line,
						'Desktop fixed-function builtin `${token.text}` has no automatic OpenFL ES binding');

				default:
					if (textureMap.exists(token.text) && !macroNames.exists(token.text) && isFunctionCall(tokens, i))
						token.replacement = textureMap.get(token.text);
			}
		}

		if (fragmentOutputName != null)
			generatedHeader.push('layout(location = 0) out vec4 $fragmentOutputName;');
	}

	private static function diagnoseES300Layouts(tokens:Array<MobileShaderToken>, isFragment:Bool,
		diagnostics:Array<MobileShaderDiagnostic>):Void
	{
		for (i in 0...tokens.length)
		{
			var token = tokens[i];
			if (token.removed || token.preprocessor || token.kind != IDENTIFIER || token.text != 'layout'
				|| token.braceDepth != 0 || token.parenDepth != 0) continue;
			var open = nextSignificant(tokens, i);
			if (open < 0 || tokenValue(tokens[open]) != '(') continue;
			var close = findMatching(tokens, open, '(', ')');
			var qualifier = close >= 0 ? nextSignificant(tokens, close) : -1;
			if (close < 0 || qualifier < 0) continue;
			var storage = tokenValue(tokens[qualifier]);
			var location = parseLocationLayout(renderRange(tokens, open + 1, close));
			var supported = location != null && ((!isFragment && storage == 'in') || (isFragment && storage == 'out'));
			if (!supported)
				addDiagnostic(diagnostics, isFragment ? 'fragment' : 'vertex', token.line,
					'This desktop `layout(...)` qualifier has no exact GLSL ES 3.00 stage equivalent');
		}
	}

	private static function convertToES100(tokens:Array<MobileShaderToken>, isFragment:Bool, macroNames:Map<String, Bool>,
		extensionLines:Array<String>, generatedHeader:Array<String>, canWrapEntryPoint:Bool,
		diagnostics:Array<MobileShaderDiagnostic>):Null<String>
	{
		removeSafeES100Layouts(tokens, isFragment, diagnostics);

		var usesTexture = false;
		var usesTextureProj = false;
		var usesTextureLod = false;
		var usesTextureGrad = false;
		var usesDerivatives = false;
		var hasLegacyFragmentOutput = isFragment && (containsTransformableIdentifier(tokens, 'gl_FragColor')
			|| containsTransformableIdentifier(tokens, 'gl_FragData'));
		var explicitOutputNames:Array<String> = [];
		var explicitOutputSetUnsafe = false;
		var conditionalDepths = collectConditionalDepths(tokens);
		if (isFragment)
		{
			for (i in 0...tokens.length)
			{
				var token = tokens[i];
				if (token.removed || token.kind != IDENTIFIER || token.text != 'out' || !canTransform(tokens, i)
					|| token.braceDepth != 0 || token.parenDepth != 0
					|| (token.preprocessor && !isStandaloneGlobalStorageMacroToken(tokens, i))) continue;
				if (isInterfaceBlockQualifier(tokens, i))
				{
					explicitOutputSetUnsafe = true;
					continue;
				}
				var declarationIndex = token.preprocessor ? findMacroFragmentOutputUse(tokens, i) : i;
				var output = token.preprocessor ? parseMacroFragmentOutput(tokens, i) : parseSingleFragmentOutput(tokens, i);
				if (declarationIndex < 0 || conditionalDepths[declarationIndex] > 0
					|| (token.preprocessor && conditionalDepths[i] > 0)) explicitOutputSetUnsafe = true;
				if (declarationIndex >= 0)
				{
					var statementStart = findGlobalStatementStart(tokens, declarationIndex);
					for (j in statementStart...declarationIndex)
					{
						var qualifier = tokens[j];
						if (!qualifier.removed && !qualifier.preprocessor && qualifier.kind == IDENTIFIER
							&& macroNames.exists(qualifier.text)) explicitOutputSetUnsafe = true;
					}
				}
				if (output == null)
					explicitOutputSetUnsafe = true;
				else
				{
					if (macroNames.exists(output)) explicitOutputSetUnsafe = true;
					if (!explicitOutputNames.contains(output)) explicitOutputNames.push(output);
				}
			}
		}
		if (explicitOutputNames.length > 1) explicitOutputSetUnsafe = true;
		var explicitFragmentOutput:Null<String> = !hasLegacyFragmentOutput && !explicitOutputSetUnsafe
			&& explicitOutputNames.length == 1 && canWrapEntryPoint ? explicitOutputNames[0] : null;
		var interfacePrecision = fragmentHighp ? 'highp' : 'mediump';
		var textureHelper = uniqueIdentifier(tokens, 'novaflare_texture');
		var textureProjHelper = uniqueIdentifier(tokens, 'novaflare_textureProj');
		var textureLodHelper = uniqueIdentifier(tokens, 'novaflare_textureLod');
		var textureGradHelper = uniqueIdentifier(tokens, 'novaflare_textureGrad');

		for (i in 0...tokens.length)
		{
			var token = tokens[i];
			if (token.removed || token.kind != IDENTIFIER || !canTransform(tokens, i)) continue;

			var globalStorageToken = token.braceDepth == 0 && token.parenDepth == 0
				&& (!token.preprocessor || isStandaloneGlobalStorageMacroToken(tokens, i));
			if (globalStorageToken)
			{
				switch (token.text)
				{
					case 'in':
						if (isInterfaceBlockQualifier(tokens, i))
							addDiagnostic(diagnostics, isFragment ? 'fragment' : 'vertex', token.line,
								'GLSL ES 1.00 has no shader input/output interface-block equivalent');
						else
							token.replacement = isFragment ? 'varying' : 'attribute';

					case 'out':
						if (isInterfaceBlockQualifier(tokens, i))
							addDiagnostic(diagnostics, isFragment ? 'fragment' : 'vertex', token.line,
								'GLSL ES 1.00 has no shader input/output interface-block equivalent');
						else if (!isFragment)
							token.replacement = 'varying';
						else
						{
							var output = token.preprocessor ? parseMacroFragmentOutput(tokens, i) : parseSingleFragmentOutput(tokens, i);
							if (hasLegacyFragmentOutput)
								addDiagnostic(diagnostics, 'fragment', token.line,
									'Legacy `gl_FragColor` and an explicit fragment output cannot be mixed safely');
							else if (output == null)
								addDiagnostic(diagnostics, 'fragment', token.line,
									'GLSL ES 1.00 can only lower one top-level `out vec4 name` to `gl_FragColor`');
							else if (!canWrapEntryPoint)
								addDiagnostic(diagnostics, 'fragment', token.line,
									'Explicit fragment output lowering requires one unconditional, unambiguous `main` entry point');
							else if (explicitFragmentOutput == null || explicitFragmentOutput != output)
								addDiagnostic(diagnostics, 'fragment', token.line,
									'OpenFL exposes one color attachment; this fragment output set cannot be converted atomically to ES 2');
							else
							{
								token.replacement = '';
							}
						}

					case 'flat', 'noperspective', 'centroid':
						addDiagnostic(diagnostics, isFragment ? 'fragment' : 'vertex', token.line,
							'`${token.text}` interpolation cannot be represented exactly by GLSL ES 1.00');

					case 'smooth':
						// Smooth interpolation is the ES 2 default.
						token.replacement = '';
				}
			}

			switch (token.text)
			{
				case 'texture':
					if (!macroNames.exists(token.text) && isFunctionCall(tokens, i))
					{
						token.replacement = textureHelper;
						usesTexture = true;
					}

				case 'textureProj':
					if (!macroNames.exists(token.text) && isFunctionCall(tokens, i))
					{
						token.replacement = textureProjHelper;
						usesTextureProj = true;
					}

				case 'textureLod':
					if (!macroNames.exists(token.text) && isFunctionCall(tokens, i))
					{
						token.replacement = textureLodHelper;
						usesTextureLod = true;
					}

				case 'textureGrad':
					if (!macroNames.exists(token.text) && isFunctionCall(tokens, i))
					{
						if (isFragment)
						{
							token.replacement = textureGradHelper;
							usesTextureGrad = true;
						}
						else
							addDiagnostic(diagnostics, 'vertex', token.line,
								'`textureGrad` has no GLSL ES 1.00 vertex-stage equivalent');
					}

				case 'dFdx', 'dFdy', 'fwidth':
					if (isFunctionCall(tokens, i))
					{
						if (isFragment) usesDerivatives = true;
						else addDiagnostic(diagnostics, 'vertex', token.line,
							'Derivative functions have no GLSL ES 1.00 vertex-stage equivalent');
					}

				case 'gl_FragData':
					if (!isFragment)
						addDiagnostic(diagnostics, 'vertex', token.line, '`gl_FragData` is not available in a vertex shader');
					else if (isConstantFragDataZero(tokens, i))
					{
						token.replacement = 'gl_FragColor';
						removeFragDataZeroIndex(tokens, i);
					}
					else
						addDiagnostic(diagnostics, 'fragment', token.line,
							'OpenFL exposes one color attachment; only constant `gl_FragData[0]` can be converted');

				case 'gl_FragDepth':
					if (isFragment)
					{
						if (hasExtension('GL_EXT_frag_depth'))
						{
							token.replacement = 'gl_FragDepthEXT';
							addExtension(extensionLines, '#extension GL_EXT_frag_depth : enable');
						}
						else
							addDiagnostic(diagnostics, 'fragment', token.line,
								'`gl_FragDepth` requires GL_EXT_frag_depth on this ES 2 context');
					}

				case 'gl_FragDepthEXT':
					if (isFragment)
					{
						if (hasExtension('GL_EXT_frag_depth'))
							addExtension(extensionLines, '#extension GL_EXT_frag_depth : enable');
						else
							addDiagnostic(diagnostics, 'fragment', token.line,
								'`gl_FragDepthEXT` requires GL_EXT_frag_depth on this ES 2 context');
					}

				case 'texture2DLodEXT', 'textureCubeLodEXT', 'texture2DProjLodEXT':
					if (isFunctionCall(tokens, i))
					{
						if (!isFragment)
							token.replacement = switch (token.text)
							{
								case 'texture2DLodEXT': 'texture2DLod';
								case 'textureCubeLodEXT': 'textureCubeLod';
								default: 'texture2DProjLod';
							};
						else if (hasExtension('GL_EXT_shader_texture_lod'))
							addExtension(extensionLines, '#extension GL_EXT_shader_texture_lod : enable');
						else
							addDiagnostic(diagnostics, 'fragment', token.line,
								'`${token.text}` requires GL_EXT_shader_texture_lod on this ES 2 context');
					}

				case 'texture2DGradEXT', 'textureCubeGradEXT', 'texture2DProjGradEXT':
					if (isFunctionCall(tokens, i))
					{
						if (!isFragment)
							addDiagnostic(diagnostics, 'vertex', token.line,
								'`${token.text}` has no GLSL ES 1.00 vertex-stage equivalent');
						else if (hasExtension('GL_EXT_shader_texture_lod'))
							addExtension(extensionLines, '#extension GL_EXT_shader_texture_lod : enable');
						else
							addDiagnostic(diagnostics, 'fragment', token.line,
								'`${token.text}` requires GL_EXT_shader_texture_lod on this ES 2 context');
					}

				case 'uint', 'uvec2', 'uvec3', 'uvec4', 'isampler2D', 'isamplerCube', 'usampler2D', 'usamplerCube',
					'sampler2DShadow', 'samplerCubeShadow', 'sampler3D', 'sampler2DArray', 'sampler2DArrayShadow',
					'mat2x3', 'mat2x4', 'mat3x2', 'mat3x4', 'mat4x2', 'mat4x3':
					addDiagnostic(diagnostics, isFragment ? 'fragment' : 'vertex', token.line,
						'`${token.text}` has no exact GLSL ES 1.00 equivalent');

				case 'texelFetch', 'textureSize', 'textureOffset', 'textureProjOffset', 'textureLodOffset', 'textureGradOffset',
					'textureGather', 'bitfieldExtract', 'bitfieldInsert', 'bitCount', 'findLSB', 'findMSB':
					addDiagnostic(diagnostics, isFragment ? 'fragment' : 'vertex', token.line,
						'`${token.text}` cannot be lowered exactly to GLSL ES 1.00');

				case 'switch':
					addDiagnostic(diagnostics, isFragment ? 'fragment' : 'vertex', token.line,
						'`switch` is not available in GLSL ES 1.00');

				case 'gl_Vertex', 'gl_Normal', 'gl_Color', 'gl_SecondaryColor', 'gl_MultiTexCoord0', 'gl_MultiTexCoord1',
					'gl_MultiTexCoord2', 'gl_MultiTexCoord3', 'gl_MultiTexCoord4', 'gl_MultiTexCoord5', 'gl_MultiTexCoord6',
					'gl_MultiTexCoord7', 'gl_ModelViewMatrix', 'gl_ProjectionMatrix', 'gl_ModelViewProjectionMatrix',
					'gl_NormalMatrix', 'gl_TextureMatrix', 'gl_TexCoord', 'gl_FrontColor', 'gl_BackColor', 'ftransform':
					addDiagnostic(diagnostics, isFragment ? 'fragment' : 'vertex', token.line,
						'Desktop fixed-function builtin `${token.text}` has no automatic OpenFL ES binding');
			}
		}

		applyES100VaryingPrecision(tokens, interfacePrecision, diagnostics, isFragment);
		diagnoseES100Operators(tokens, isFragment, diagnostics);

		if (usesDerivatives)
		{
			if (hasExtension('GL_OES_standard_derivatives'))
				addExtension(extensionLines, '#extension GL_OES_standard_derivatives : enable');
			else
				addDiagnostic(diagnostics, isFragment ? 'fragment' : 'vertex', 1,
					'Derivative functions require GL_OES_standard_derivatives on this ES 2 context');
		}

		if (usesTexture)
		{
			generatedHeader.push('vec4 $textureHelper(sampler2D s, vec2 p) { return texture2D(s, p); }');
			generatedHeader.push('vec4 $textureHelper(samplerCube s, vec3 p) { return textureCube(s, p); }');
			if (isFragment)
			{
				generatedHeader.push('vec4 $textureHelper(sampler2D s, vec2 p, float bias) { return texture2D(s, p, bias); }');
				generatedHeader.push('vec4 $textureHelper(samplerCube s, vec3 p, float bias) { return textureCube(s, p, bias); }');
			}
		}

		if (usesTextureProj)
		{
			generatedHeader.push('vec4 $textureProjHelper(sampler2D s, vec3 p) { return texture2DProj(s, p); }');
			generatedHeader.push('vec4 $textureProjHelper(sampler2D s, vec4 p) { return texture2DProj(s, p); }');
			if (isFragment)
			{
				generatedHeader.push('vec4 $textureProjHelper(sampler2D s, vec3 p, float bias) { return texture2DProj(s, p, bias); }');
				generatedHeader.push('vec4 $textureProjHelper(sampler2D s, vec4 p, float bias) { return texture2DProj(s, p, bias); }');
			}
		}

		if (usesTextureLod)
		{
			if (!isFragment)
			{
				generatedHeader.push('vec4 $textureLodHelper(sampler2D s, vec2 p, float lod) { return texture2DLod(s, p, lod); }');
				generatedHeader.push('vec4 $textureLodHelper(samplerCube s, vec3 p, float lod) { return textureCubeLod(s, p, lod); }');
			}
			else if (hasExtension('GL_EXT_shader_texture_lod'))
			{
				addExtension(extensionLines, '#extension GL_EXT_shader_texture_lod : enable');
				generatedHeader.push('vec4 $textureLodHelper(sampler2D s, vec2 p, float lod) { return texture2DLodEXT(s, p, lod); }');
				generatedHeader.push('vec4 $textureLodHelper(samplerCube s, vec3 p, float lod) { return textureCubeLodEXT(s, p, lod); }');
			}
			else
				addDiagnostic(diagnostics, 'fragment', 1,
					'Fragment `textureLod` requires GL_EXT_shader_texture_lod on this ES 2 context');
		}

		if (usesTextureGrad)
		{
			if (hasExtension('GL_EXT_shader_texture_lod'))
			{
				addExtension(extensionLines, '#extension GL_EXT_shader_texture_lod : enable');
				generatedHeader.push('vec4 $textureGradHelper(sampler2D s, vec2 p, vec2 dx, vec2 dy) { return texture2DGradEXT(s, p, dx, dy); }');
				generatedHeader.push('vec4 $textureGradHelper(samplerCube s, vec3 p, vec3 dx, vec3 dy) { return textureCubeGradEXT(s, p, dx, dy); }');
			}
			else
				addDiagnostic(diagnostics, isFragment ? 'fragment' : 'vertex', 1,
					'`textureGrad` requires GL_EXT_shader_texture_lod on this ES 2 context');
		}

		return explicitFragmentOutput;
	}

	private static function removeSafeES100Layouts(tokens:Array<MobileShaderToken>, isFragment:Bool,
		diagnostics:Array<MobileShaderDiagnostic>):Void
	{
		for (i in 0...tokens.length)
		{
			var token = tokens[i];
			if (token.removed || token.preprocessor || token.kind != IDENTIFIER || token.text != 'layout'
				|| token.braceDepth != 0 || token.parenDepth != 0) continue;

			var open = nextSignificant(tokens, i);
			if (open < 0 || tokenValue(tokens[open]) != '(') continue;
			var close = findMatching(tokens, open, '(', ')');
			if (close < 0) continue;
			var qualifierIndex = nextSignificant(tokens, close);
			if (qualifierIndex < 0) continue;
			var qualifier = tokenValue(tokens[qualifierIndex]);
			if (qualifier != 'in' && qualifier != 'out')
			{
				addDiagnostic(diagnostics, isFragment ? 'fragment' : 'vertex', token.line,
					'Only input/output `layout(...)` qualifiers can be lowered to GLSL ES 1.00');
				continue;
			}

			var layoutText = renderRange(tokens, open + 1, close);
			var location = parseLocationLayout(layoutText);
			var safe = location != null && ((!isFragment && qualifier == 'in')
				|| (isFragment && qualifier == 'out' && location == 0));
			if (!safe)
			{
				addDiagnostic(diagnostics, isFragment ? 'fragment' : 'vertex', token.line,
					'Only a vertex attribute location or the single fragment output `location = 0` can be lowered exactly to ES 2');
				continue;
			}

			for (j in i...close + 1)
				tokens[j].removed = true;
		}
	}

	private static function applyES100VaryingPrecision(tokens:Array<MobileShaderToken>, precision:String,
		diagnostics:Array<MobileShaderDiagnostic>, isFragment:Bool):Void
	{
		for (i in 0...tokens.length)
		{
			var token = tokens[i];
			if (token.removed || token.preprocessor || token.braceDepth != 0 || token.parenDepth != 0
				|| tokenValue(token) != 'varying') continue;

			var next = nextSignificant(tokens, i);
			if (next < 0) continue;
			var value = tokenValue(tokens[next]);
			if (value == 'lowp' || value == 'mediump' || value == 'highp')
			{
				if (!fragmentHighp && value == 'highp')
					addDiagnostic(diagnostics, isFragment ? 'fragment' : 'vertex', tokens[next].line,
						'Fragment highp is unavailable; an explicitly highp varying cannot be linked exactly on this ES 2 device');
				continue;
			}
			token.replacement = 'varying $precision';
		}
	}

	private static function parseSingleFragmentOutput(tokens:Array<MobileShaderToken>, outIndex:Int):Null<String>
	{
		var index = nextSignificant(tokens, outIndex);
		while (index >= 0 && isPrecision(tokenValue(tokens[index])))
			index = nextSignificant(tokens, index);
		if (index < 0 || tokenValue(tokens[index]) != 'vec4') return null;

		index = nextSignificant(tokens, index);
		if (index < 0 || tokens[index].kind != IDENTIFIER) return null;
		var name = tokenValue(tokens[index]);

		var end = nextSignificant(tokens, index);
		if (end < 0) return null;
		if (tokenValue(tokens[end]) == '=')
		{
			var semicolon = findGlobalStatementEnd(tokens, end);
			if (semicolon < 0) return null;
			for (i in (end + 1)...semicolon)
			{
				var token = tokens[i];
				if (!token.preprocessor && !token.removed && token.kind == SYMBOL && tokenValue(token) == ','
					&& token.braceDepth == 0 && token.parenDepth == 0 && token.bracketDepth == 0) return null;
			}
		}
		else if (tokenValue(tokens[end]) != ';') return null;
		return name;
	}

	private static function parseMacroFragmentOutput(tokens:Array<MobileShaderToken>, outIndex:Int):Null<String>
	{
		var use = findMacroFragmentOutputUse(tokens, outIndex);
		return use >= 0 ? parseSingleFragmentOutput(tokens, use) : null;
	}

	private static function findMacroFragmentOutputUse(tokens:Array<MobileShaderToken>, outIndex:Int):Int
	{
		var hash = outIndex;
		while (hash >= 0 && tokens[hash].preprocessor)
		{
			if (tokens[hash].kind == SYMBOL && tokens[hash].text == '#') break;
			hash--;
		}
		if (hash < 0 || tokens[hash].text != '#') return -1;
		var directive = nextSignificantInDirective(tokens, hash);
		var nameIndex = directive >= 0 ? nextSignificantInDirective(tokens, directive) : -1;
		if (directive < 0 || tokenValue(tokens[directive]) != 'define' || nameIndex < 0) return -1;
		var name = tokenValue(tokens[nameIndex]);

		var use = -1;
		for (i in 0...tokens.length)
		{
			var token = tokens[i];
			if (token.preprocessor || token.removed || token.kind != IDENTIFIER || token.text != name
				|| token.braceDepth != 0 || token.parenDepth != 0) continue;
			if (use >= 0) return -1;
			use = i;
		}
		return use;
	}

	private static function diagnoseES100Operators(tokens:Array<MobileShaderToken>, isFragment:Bool,
		diagnostics:Array<MobileShaderDiagnostic>):Void
	{
		for (i in 0...tokens.length)
		{
			var token = tokens[i];
			if (token.removed || token.preprocessor || token.kind != SYMBOL) continue;
			var value = tokenValue(token);
			var previous = previousSignificant(tokens, i);
			var next = nextSignificant(tokens, i);
			var previousValue = previous >= 0 ? tokenValue(tokens[previous]) : '';
			var nextValue = next >= 0 ? tokenValue(tokens[next]) : '';
			var unsupported = value == '~' || value == '%'
				|| (value == '&' && previousValue != '&' && nextValue != '&')
				|| (value == '|' && previousValue != '|' && nextValue != '|')
				|| (value == '^' && previousValue != '^' && nextValue != '^')
				|| (value == '<' && nextValue == '<') || (value == '>' && nextValue == '>');
			if (unsupported)
				addDiagnostic(diagnostics, isFragment ? 'fragment' : 'vertex', token.line,
					'Bitwise/integer operator `$value` has no exact GLSL ES 1.00 equivalent');
		}
	}

	private static function renameEntryPoints(tokens:Array<MobileShaderToken>, entryPoints:Array<MobileShaderEntryPoint>,
		replacement:String):Bool
	{
		if (entryPoints.length == 0) return false;
		var renamed = false;
		for (entryPoint in entryPoints)
		{
			var token = tokens[entryPoint.nameIndex];
			if (token.removed || token.preprocessor || token.kind != IDENTIFIER) continue;
			token.replacement = replacement;
			renamed = true;
		}
		return renamed;
	}

	private static function extractVersionAndExtensions(tokens:Array<MobileShaderToken>, targetVersion:Int, stage:String,
		diagnostics:Array<MobileShaderDiagnostic>):Array<String>
	{
		var result:Array<String> = [];
		var i = 0;
		while (i < tokens.length)
		{
			var token = tokens[i];
			if (!token.preprocessor || token.kind != SYMBOL || token.text != '#')
			{
				i++;
				continue;
			}

			var end = i;
			while (end + 1 < tokens.length && tokens[end + 1].line == token.line)
				end++;
			var directive = nextSignificantOnLine(tokens, i, token.line);
			if (directive < 0)
			{
				i = end + 1;
				continue;
			}

			var name = tokenValue(tokens[directive]);
			if (name == 'version' || name == 'extension')
			{
				var directiveText = renderRange(tokens, i, end + 1);
				if (name == 'extension')
				{
					var extensionName = parseExtensionName(directiveText);
					var coreInES300 = extensionName == 'GL_OES_standard_derivatives'
						|| extensionName == 'GL_EXT_shader_texture_lod' || extensionName == 'GL_EXT_frag_depth';
					if (!(targetVersion >= 300 && coreInES300))
					{
						addExtension(result, StringTools.trim(directiveText));
						if (extensionName != null && extensionName != 'all' && !hasExtension(extensionName))
							addDiagnostic(diagnostics, stage, token.line,
								'Requested extension `$extensionName` is not reported by this GL context');
					}
				}

				for (j in i...end + 1)
					if (tokens[j].text.indexOf('\n') < 0)
						tokens[j].removed = true;
			}
			i = end + 1;
		}
		return result;
	}

	private static function diagnoseMacroGeneratedGlobalDeclarations(tokens:Array<MobileShaderToken>, targetVersion:Int,
		stage:String, diagnostics:Array<MobileShaderDiagnostic>):Void
	{
		var suspect:Map<String, Bool> = new Map();
		var functionLikeMacros:Map<String, Bool> = new Map();
		var dependencies:Map<String, Array<String>> = new Map();
		for (i in 0...tokens.length)
		{
			if (!tokens[i].preprocessor || tokens[i].kind != SYMBOL || tokens[i].text != '#') continue;
			var directive = nextSignificantInDirective(tokens, i);
			if (directive < 0 || tokenValue(tokens[directive]) != 'define') continue;
			var nameIndex = nextSignificantInDirective(tokens, directive);
			if (nameIndex < 0 || tokens[nameIndex].kind != IDENTIFIER) continue;
			var name = tokenValue(tokens[nameIndex]);
			var bodyStart = nextSignificantInDirective(tokens, nameIndex);
			if (bodyStart < 0) continue;
			var functionLike = bodyStart == nameIndex + 1 && tokenValue(tokens[bodyStart]) == '(';
			var macroParameters:Array<String> = [];
			if (functionLike)
			{
				functionLikeMacros.set(name, true);
				var close = findMatching(tokens, bodyStart, '(', ')');
				if (close >= 0)
				{
					for (parameterIndex in (bodyStart + 1)...close)
					{
						var parameter = tokens[parameterIndex];
						if (parameter.kind == IDENTIFIER && !macroParameters.contains(parameter.text))
							macroParameters.push(parameter.text);
					}
				}
				bodyStart = close >= 0 ? nextSignificantInDirective(tokens, close) : -1;
				if (bodyStart < 0) continue;
			}

			var significantCount = 0;
			var hasAssignment = false;
			var hasStorage = false;
			var macroDependencies:Array<String> = [];
			var j = bodyStart;
			while (j >= 0 && j < tokens.length && tokens[j].preprocessor)
			{
				var bodyToken = tokens[j];
				if (!bodyToken.removed && bodyToken.kind != WHITESPACE && bodyToken.kind != COMMENT)
				{
					significantCount++;
					var value = tokenValue(bodyToken);
					if (bodyToken.kind == IDENTIFIER && !macroParameters.contains(value)
						&& !macroDependencies.contains(value)) macroDependencies.push(value);
					if (bodyToken.kind == IDENTIFIER && !macroParameters.contains(value)
						&& (targetVersion >= 300 ? (value == 'attribute' || value == 'varying') : (value == 'in' || value == 'out')))
						hasStorage = true;
					if (bodyToken.kind == SYMBOL && value == '=')
					{
						var previous = previousSignificant(tokens, j);
						var next = nextSignificantInDirective(tokens, j);
						var previousValue = previous >= bodyStart ? tokenValue(tokens[previous]) : '';
						var nextValue = next >= 0 ? tokenValue(tokens[next]) : '';
						if (previousValue != '=' && previousValue != '!' && previousValue != '<' && previousValue != '>'
							&& nextValue != '=') hasAssignment = true;
					}
				}
				j++;
			}
			dependencies.set(name, macroDependencies);
			if (hasAssignment || (hasStorage && (functionLike || significantCount > 1))) suspect.set(name, true);
		}

		var changed = true;
		while (changed)
		{
			changed = false;
			for (name => dependencyNames in dependencies)
			{
				if (suspect.exists(name)) continue;
				for (dependency in dependencyNames)
				{
					if (!suspect.exists(dependency)) continue;
					suspect.set(name, true);
					changed = true;
					break;
				}
			}
		}

		for (i in 0...tokens.length)
		{
			var token = tokens[i];
			if (token.removed || token.preprocessor || token.kind != IDENTIFIER || !suspect.exists(token.text)
				|| token.braceDepth != 0 || token.parenDepth != 0 || token.bracketDepth != 0) continue;
			if (functionLikeMacros.exists(token.text))
			{
				var open = nextSignificant(tokens, i);
				if (open < 0 || tokenValue(tokens[open]) != '(') continue;
			}
			var statementStart = findGlobalStatementStart(tokens, i);
			var insideInitializer = false;
			for (j in statementStart...i)
			{
				var prefix = tokens[j];
				if (!prefix.preprocessor && !prefix.removed && prefix.kind == SYMBOL && tokenValue(prefix) == '='
					&& prefix.braceDepth == 0 && prefix.parenDepth == 0 && prefix.bracketDepth == 0)
				{
					insideInitializer = true;
					break;
				}
			}
			if (insideInitializer) continue;
			addDiagnostic(diagnostics, stage, token.line,
				'Macro-generated global declaration bypasses structural lowering; expand it before GLSL ES $targetVersion conversion');
		}
	}

	private static function collectMacroNames(tokens:Array<MobileShaderToken>):Map<String, Bool>
	{
		var result:Map<String, Bool> = new Map();
		for (i in 0...tokens.length)
		{
			if (!tokens[i].preprocessor || tokens[i].kind != SYMBOL || tokens[i].text != '#') continue;
			var directive = nextSignificantInDirective(tokens, i);
			if (directive < 0 || tokenValue(tokens[directive]) != 'define') continue;
			var name = nextSignificantInDirective(tokens, directive);
			if (name >= 0 && tokens[name].kind == IDENTIFIER)
				result.set(tokenValue(tokens[name]), true);
		}
		return result;
	}

	private static function canTransform(tokens:Array<MobileShaderToken>, index:Int):Bool
	{
		var token = tokens[index];
		if (!token.preprocessor) return true;

		var hash = -1;
		var search = index;
		while (search >= 0 && tokens[search].preprocessor)
		{
			if (tokens[search].kind == SYMBOL && tokens[search].text == '#')
			{
				hash = search;
				break;
			}
			search--;
		}
		if (hash < 0) return false;

		var directive = nextSignificantInDirective(tokens, hash);
		if (directive < 0 || tokenValue(tokens[directive]) != 'define') return false;
		var macroName = nextSignificantInDirective(tokens, directive);
		if (macroName < 0 || index <= macroName) return false;

		var next = nextSignificantInDirective(tokens, macroName);
		if (next == macroName + 1 && tokenValue(tokens[next]) == '(')
		{
			var close = findMatching(tokens, next, '(', ')');
			return close >= 0 && index > close;
		}
		return index > macroName;
	}

	/**
	 * `in` and `out` are also legal function-parameter qualifiers in ES 1.00.
	 * Only rewrite them inside a macro when the replacement is exactly that
	 * one token and every real use of the macro is at global declaration scope.
	 */
	private static function isStandaloneGlobalStorageMacroToken(tokens:Array<MobileShaderToken>, index:Int):Bool
	{
		var hash = index;
		while (hash >= 0 && tokens[hash].preprocessor)
		{
			if (tokens[hash].kind == SYMBOL && tokens[hash].text == '#') break;
			hash--;
		}
		if (hash < 0 || tokens[hash].text != '#') return false;

		var directive = nextSignificantInDirective(tokens, hash);
		var macroName = directive >= 0 ? nextSignificantInDirective(tokens, directive) : -1;
		if (directive < 0 || tokenValue(tokens[directive]) != 'define' || macroName < 0) return false;

		var bodyStart = nextSignificantInDirective(tokens, macroName);
		if (bodyStart == macroName + 1 && bodyStart >= 0 && tokenValue(tokens[bodyStart]) == '(')
		{
			var close = findMatching(tokens, bodyStart, '(', ')');
			bodyStart = close >= 0 ? nextSignificantInDirective(tokens, close) : -1;
		}
		if (bodyStart != index) return false;

		var after = nextSignificantInDirective(tokens, index);
		while (after >= 0 && tokenValue(tokens[after]) == '\\')
			after = nextSignificantInDirective(tokens, after);
		if (after >= 0) return false;

		var name = tokenValue(tokens[macroName]);
		var foundUse = false;
		for (token in tokens)
		{
			if (token.preprocessor || token.removed || token.kind != IDENTIFIER || token.text != name) continue;
			foundUse = true;
			if (token.braceDepth != 0 || token.parenDepth != 0) return false;
		}
		return foundUse;
	}

	private static function isFunctionCall(tokens:Array<MobileShaderToken>, index:Int):Bool
	{
		var next = nextSignificant(tokens, index);
		if (next < 0 || tokenValue(tokens[next]) != '(') return false;
		var previous = previousSignificant(tokens, index);
		return previous < 0 || tokenValue(tokens[previous]) != '.';
	}

	private static function isConstantFragDataZero(tokens:Array<MobileShaderToken>, index:Int):Bool
	{
		var open = nextSignificant(tokens, index);
		var value = open >= 0 ? nextSignificant(tokens, open) : -1;
		var close = value >= 0 ? nextSignificant(tokens, value) : -1;
		return open >= 0 && value >= 0 && close >= 0 && tokenValue(tokens[open]) == '['
			&& tokenValue(tokens[value]) == '0' && tokenValue(tokens[close]) == ']';
	}

	private static function removeFragDataZeroIndex(tokens:Array<MobileShaderToken>, index:Int):Void
	{
		var open = nextSignificant(tokens, index);
		var value = nextSignificant(tokens, open);
		var close = nextSignificant(tokens, value);
		for (i in open...close + 1) tokens[i].removed = true;
	}

	private static function uniqueIdentifier(tokens:Array<MobileShaderToken>, base:String):String
	{
		var candidate = base;
		var suffix = 0;
		while (containsIdentifier(tokens, candidate))
		{
			suffix++;
			candidate = base + suffix;
		}
		return candidate;
	}

	private static function containsIdentifier(tokens:Array<MobileShaderToken>, name:String):Bool
	{
		for (token in tokens)
			if (token.kind == IDENTIFIER && token.text == name) return true;
		return false;
	}

	private static function containsTransformableIdentifier(tokens:Array<MobileShaderToken>, name:String):Bool
	{
		for (i in 0...tokens.length)
		{
			var token = tokens[i];
			if (!token.removed && token.kind == IDENTIFIER && token.text == name && canTransform(tokens, i)) return true;
		}
		return false;
	}

	private static function countGlobalFragmentOutputs(tokens:Array<MobileShaderToken>):Int
	{
		var count = 0;
		for (i in 0...tokens.length)
		{
			var token = tokens[i];
			if (!token.removed && !token.preprocessor && token.kind == IDENTIFIER && token.text == 'out'
				&& token.braceDepth == 0 && token.parenDepth == 0 && !isInterfaceBlockQualifier(tokens, i)
				&& parseSingleFragmentOutput(tokens, i) != null) count++;
		}
		return count;
	}

	private static function isInterfaceBlockQualifier(tokens:Array<MobileShaderToken>, qualifierIndex:Int):Bool
	{
		var next = nextSignificant(tokens, qualifierIndex);
		while (next >= 0 && (isPrecision(tokenValue(tokens[next])) || tokenValue(tokens[next]) == 'flat'
			|| tokenValue(tokens[next]) == 'smooth' || tokenValue(tokens[next]) == 'centroid'
			|| tokenValue(tokens[next]) == 'noperspective'))
			next = nextSignificant(tokens, next);
		if (next < 0) return false;
		if (tokenValue(tokens[next]) == '{') return true;
		var open = nextSignificant(tokens, next);
		return tokens[next].kind == IDENTIFIER && open >= 0 && tokenValue(tokens[open]) == '{';
	}

	private static function assignDepths(tokens:Array<MobileShaderToken>):Void
	{
		var brace = 0;
		var paren = 0;
		var bracket = 0;
		for (token in tokens)
		{
			token.braceDepth = brace;
			token.parenDepth = paren;
			token.bracketDepth = bracket;
			if (token.preprocessor || token.kind != SYMBOL) continue;
			switch (token.text)
			{
				case '{': brace++;
				case '}': if (brace > 0) brace--;
				case '(': paren++;
				case ')': if (paren > 0) paren--;
				case '[': bracket++;
				case ']': if (bracket > 0) bracket--;
			}
		}
	}

	private static function tokenize(source:String):Array<MobileShaderToken>
	{
		var result:Array<MobileShaderToken> = [];
		var index = 0;
		var line = 1;
		var lineStart = true;
		var inPreprocessor = false;

		while (index < source.length)
		{
			var start = index;
			var startLine = line;
			var code = StringTools.fastCodeAt(source, index);
			var kind = SYMBOL;

			if (code == 10)
			{
				var continued = false;
				if (inPreprocessor)
				{
					var previous = result.length - 1;
					while (previous >= 0 && result[previous].kind == WHITESPACE
						&& result[previous].line == startLine && result[previous].text.indexOf('\n') < 0) previous--;
					continued = previous >= 0 && result[previous].line == startLine && result[previous].text == '\\';
				}
				index++;
				result.push(makeToken('\n', WHITESPACE, startLine, inPreprocessor));
				line++;
				lineStart = !continued;
				inPreprocessor = continued;
				continue;
			}

			if (isHorizontalWhitespace(code))
			{
				kind = WHITESPACE;
				while (index < source.length && isHorizontalWhitespace(StringTools.fastCodeAt(source, index))) index++;
			}
			else if (code == 47 && index + 1 < source.length && StringTools.fastCodeAt(source, index + 1) == 47)
			{
				kind = COMMENT;
				index += 2;
				while (index < source.length && StringTools.fastCodeAt(source, index) != 10) index++;
			}
			else if (code == 47 && index + 1 < source.length && StringTools.fastCodeAt(source, index + 1) == 42)
			{
				kind = COMMENT;
				var commentHadNewline = false;
				index += 2;
				while (index < source.length)
				{
					if (StringTools.fastCodeAt(source, index) == 10)
					{
						line++;
						commentHadNewline = true;
					}
					if (StringTools.fastCodeAt(source, index) == 42 && index + 1 < source.length
						&& StringTools.fastCodeAt(source, index + 1) == 47)
					{
						index += 2;
						break;
					}
					index++;
				}
				if (commentHadNewline)
				{
					lineStart = true;
					inPreprocessor = false;
				}
			}
			else if (isIdentifierStart(code))
			{
				kind = IDENTIFIER;
				index++;
				while (index < source.length && isIdentifierPart(StringTools.fastCodeAt(source, index))) index++;
				lineStart = false;
			}
			else if (isDigit(code) || (code == 46 && index + 1 < source.length && isDigit(StringTools.fastCodeAt(source, index + 1))))
			{
				kind = NUMBER;
				index = scanNumber(source, index);
				lineStart = false;
			}
			else if (code == 34 || code == 39)
			{
				kind = STRING;
				var quote = code;
				index++;
				while (index < source.length)
				{
					var stringCode = StringTools.fastCodeAt(source, index++);
					if (stringCode == 92 && index < source.length) index++;
					else if (stringCode == quote) break;
					else if (stringCode == 10) line++;
				}
				lineStart = false;
			}
			else
			{
				index++;
				if (lineStart && code == 35) inPreprocessor = true;
				lineStart = false;
			}

			result.push(makeToken(source.substring(start, index), kind, startLine, inPreprocessor));
		}
		return result;
	}

	private static inline function makeToken(text:String, kind:Int, line:Int, preprocessor:Bool):MobileShaderToken
	{
		return {
			text: text,
			replacement: null,
			kind: kind,
			line: line,
			preprocessor: preprocessor,
			removed: false,
			braceDepth: 0,
			parenDepth: 0,
			bracketDepth: 0
		};
	}

	private static function render(tokens:Array<MobileShaderToken>):String
	{
		var output = new StringBuf();
		for (token in tokens)
		{
			if (token.removed)
			{
				for (i in 0...countNewlines(token.text)) output.add('\n');
				continue;
			}
			output.add(token.replacement != null ? token.replacement : token.text);
		}
		return output.toString();
	}

	private static function renderRange(tokens:Array<MobileShaderToken>, start:Int, end:Int):String
	{
		var output = new StringBuf();
		for (i in start...end)
			if (!tokens[i].removed) output.add(tokenValue(tokens[i]));
		return output.toString();
	}

	private static inline function tokenValue(token:MobileShaderToken):String
	{
		return token.replacement != null ? token.replacement : token.text;
	}

	private static function nextSignificant(tokens:Array<MobileShaderToken>, index:Int):Int
	{
		var i = index + 1;
		while (i < tokens.length)
		{
			if (!tokens[i].removed && tokens[i].kind != WHITESPACE && tokens[i].kind != COMMENT) return i;
			i++;
		}
		return -1;
	}

	private static function previousSignificant(tokens:Array<MobileShaderToken>, index:Int):Int
	{
		var i = index - 1;
		while (i >= 0)
		{
			if (!tokens[i].removed && tokens[i].kind != WHITESPACE && tokens[i].kind != COMMENT) return i;
			i--;
		}
		return -1;
	}

	private static function nextSignificantOnLine(tokens:Array<MobileShaderToken>, index:Int, line:Int):Int
	{
		var i = index + 1;
		while (i < tokens.length && tokens[i].line == line)
		{
			if (!tokens[i].removed && tokens[i].kind != WHITESPACE && tokens[i].kind != COMMENT) return i;
			i++;
		}
		return -1;
	}

	private static function nextSignificantInDirective(tokens:Array<MobileShaderToken>, index:Int):Int
	{
		var i = index + 1;
		while (i < tokens.length && tokens[i].preprocessor)
		{
			if (!tokens[i].removed && tokens[i].kind != WHITESPACE && tokens[i].kind != COMMENT) return i;
			i++;
		}
		return -1;
	}

	private static function findMatching(tokens:Array<MobileShaderToken>, openIndex:Int, open:String, close:String):Int
	{
		var depth = 0;
		for (i in openIndex...tokens.length)
		{
			if (tokens[i].removed || tokens[i].kind != SYMBOL) continue;
			var value = tokenValue(tokens[i]);
			if (value == open) depth++;
			else if (value == close && --depth == 0) return i;
		}
		return -1;
	}

	private static function parseLocationLayout(layout:String):Null<Int>
	{
		var regex = ~/^\s*location\s*=\s*([0-9]+)\s*$/;
		return regex.match(layout) ? Std.parseInt(regex.matched(1)) : null;
	}

	private static function parseExtensionName(line:String):Null<String>
	{
		var regex = ~/#\s*extension\s+([A-Za-z0-9_]+)/;
		return regex.match(line) ? regex.matched(1) : null;
	}

	private static function hasExtension(name:String):Bool
	{
		return extensions.exists(normalizeExtensionName(name));
	}

	private static function normalizeExtensionName(name:String):String
	{
		if (name == null) return '';
		name = StringTools.trim(name);
		return StringTools.startsWith(name, 'GL_') ? name.substr(3) : name;
	}

	private static function addExtension(output:Array<String>, line:String):Void
	{
		for (existing in output)
			if (StringTools.trim(existing) == StringTools.trim(line)) return;
		output.push(line);
	}

	private static function addDiagnostic(output:Array<MobileShaderDiagnostic>, stage:String, line:Int, message:String):Void
	{
		for (diagnostic in output)
			if (diagnostic.stage == stage && diagnostic.line == line && diagnostic.message == message) return;
		output.push({stage: stage, line: line, message: message});
	}

	private static function sanitizeComment(value:String):String
	{
		return StringTools.replace(StringTools.replace(value, '\r', ' '), '\n', ' ');
	}

	private static function countNewlines(value:String):Int
	{
		var result = 0;
		for (i in 0...value.length)
			if (StringTools.fastCodeAt(value, i) == 10) result++;
		return result;
	}

	private static inline function isPrecision(value:String):Bool
	{
		return value == 'lowp' || value == 'mediump' || value == 'highp';
	}

	private static inline function isHorizontalWhitespace(code:Int):Bool
	{
		return code == 9 || code == 11 || code == 12 || code == 32;
	}

	private static inline function isIdentifierStart(code:Int):Bool
	{
		return (code >= 65 && code <= 90) || (code >= 97 && code <= 122) || code == 95;
	}

	private static inline function isIdentifierPart(code:Int):Bool
	{
		return isIdentifierStart(code) || isDigit(code);
	}

	private static inline function isDigit(code:Int):Bool
	{
		return code >= 48 && code <= 57;
	}

	private static inline function isHexDigit(code:Int):Bool
	{
		return isDigit(code) || (code >= 65 && code <= 70) || (code >= 97 && code <= 102);
	}

	private static function scanNumber(source:String, start:Int):Int
	{
		var index = start;
		var length = source.length;
		var hexadecimal = index + 1 < length && StringTools.fastCodeAt(source, index) == 48
			&& (StringTools.fastCodeAt(source, index + 1) == 88 || StringTools.fastCodeAt(source, index + 1) == 120);

		if (hexadecimal)
		{
			index += 2;
			while (index < length && isHexDigit(StringTools.fastCodeAt(source, index))) index++;
			if (index < length && StringTools.fastCodeAt(source, index) == 46)
			{
				index++;
				while (index < length && isHexDigit(StringTools.fastCodeAt(source, index))) index++;
			}
			if (index < length && (StringTools.fastCodeAt(source, index) == 80 || StringTools.fastCodeAt(source, index) == 112))
			{
				index++;
				if (index < length && (StringTools.fastCodeAt(source, index) == 43 || StringTools.fastCodeAt(source, index) == 45)) index++;
				while (index < length && isDigit(StringTools.fastCodeAt(source, index))) index++;
			}
		}
		else
		{
			if (StringTools.fastCodeAt(source, index) == 46) index++;
			while (index < length && isDigit(StringTools.fastCodeAt(source, index))) index++;
			if (index < length && StringTools.fastCodeAt(source, index) == 46)
			{
				index++;
				while (index < length && isDigit(StringTools.fastCodeAt(source, index))) index++;
			}
			if (index < length && (StringTools.fastCodeAt(source, index) == 69 || StringTools.fastCodeAt(source, index) == 101))
			{
				index++;
				if (index < length && (StringTools.fastCodeAt(source, index) == 43 || StringTools.fastCodeAt(source, index) == 45)) index++;
				while (index < length && isDigit(StringTools.fastCodeAt(source, index))) index++;
			}
		}

		// Preserve standard scalar suffixes without ever consuming an arbitrary
		// identifier or the following operator/function name.
		if (index < length)
		{
			var suffix = StringTools.fastCodeAt(source, index);
			if (suffix == 70 || suffix == 102 || suffix == 85 || suffix == 117) index++;
			else if ((suffix == 76 || suffix == 108) && index + 1 < length)
			{
				var next = StringTools.fastCodeAt(source, index + 1);
				if (next == 70 || next == 102) index += 2;
			}
		}
		return index;
	}
}
