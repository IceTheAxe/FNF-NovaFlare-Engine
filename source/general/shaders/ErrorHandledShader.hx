package general.shaders;

import lime.graphics.opengl.GLProgram;
import lime.app.Application;

import flixel.addons.display.FlxRuntimeShader;

class ErrorHandledShader extends FlxShader implements IErrorHandler
{
	public var shaderName:String = '';

	public dynamic function onError(error:Dynamic):Void
	{
	}

	public function new(?shaderName:String)
	{
		this.shaderName = shaderName;
		super();
	}

	override function __createGLProgram(vertexSource:String, fragmentSource:String):GLProgram
	{
		try
		{
			final res = super.__createGLProgram(vertexSource, fragmentSource);
			return res;
		}
		catch (error)
		{
			ErrorHandledShader.crashSave(this.shaderName, error, onError, vertexSource, fragmentSource);
			return null;
		}
	}

	public static inline var SHADER_SOURCE_PREVIEW_LINES:Int = 5;

	public static function crashSave(shaderName:String, error:Dynamic, onError:Dynamic, ?vertexSource:String,
			?fragmentSource:String)
	{
		if (shaderName == null)
			shaderName = 'unnamed';

		trace(error);

		var detail:String = error == null ? '' : Std.string(error);

		#if !debug
		// Save a crash log on Release builds
		var dateNow:String = StringTools.replace(StringTools.replace(Date.now().toString(), " ", "_"), ":", "'");

		if (!FileSystem.exists('./logs/'))
			FileSystem.createDirectory('./logs/');

		var crashLogPath:String = './logs/shader_${shaderName}_${dateNow}.txt';
		File.saveContent(crashLogPath,
			'shader=$shaderName\n\n[error]\n$detail\n\n[vertex]\n$vertexSource\n\n[fragment]\n$fragmentSource');
		#end

		var message:String = 'Shader Compile Error!\nshader: $shaderName';

		var errorHead:String = headLines(detail, SHADER_SOURCE_PREVIEW_LINES);
		if (errorHead.length > 0)
			message += '\n\n[error]\n' + errorHead;

		var sourcePreview:String = headLines(fragmentSource != null ? fragmentSource : vertexSource, SHADER_SOURCE_PREVIEW_LINES);
		if (sourcePreview.length > 0)
			message += '\n\n[source]\n' + sourcePreview;

		#if sys
		try
			mobile.backend.SUtil.showPopUp(message, 'Shader Compile Error!')
		catch (_:Dynamic)
			trace(message);
		#else
		try
			Application.current.window.alert(message, 'Shader Compile Error!')
		catch (_:Dynamic)
			trace(message);
		#end

		onError(error);
	}

	private static function headLines(value:String, limit:Int):String
	{
		if (value == null || value.length == 0)
			return '';

		var normalized:String = StringTools.replace(StringTools.replace(value, '\r\n', '\n'), '\r', '\n');
		var lines:Array<String> = normalized.split('\n');
		if (lines.length > limit)
			lines = lines.slice(0, limit);
		return lines.join('\n');
	}
}

class ErrorHandledRuntimeShader extends FlxRuntimeShader implements IErrorHandler
{
	public var shaderName:String = '';

	public dynamic function onError(error:Dynamic):Void
	{
	}

	public function new(?shaderName:String, ?fragmentSource:String, ?vertexSource:String)
	{
		this.shaderName = shaderName;
		super(fragmentSource, vertexSource);
	}

	override function __createGLProgram(vertexSource:String, fragmentSource:String):GLProgram
	{
		try
		{
			final res = super.__createGLProgram(vertexSource, fragmentSource);
			return res;
		}
		catch (error)
		{
			ErrorHandledShader.crashSave(this.shaderName, error, onError, vertexSource, fragmentSource);
			return null;
		}
	}
}

interface IErrorHandler
{
	public var shaderName:String;
	public dynamic function onError(error:Dynamic):Void;
}
