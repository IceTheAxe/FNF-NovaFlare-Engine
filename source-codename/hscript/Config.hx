package hscript;

class Config {
	// Runs support for custom classes in these
	public static final ALLOWED_CUSTOM_CLASSES = [
		#if !DOCUMENTATION
		"flixel",

		"codename.funkin",
		#if MODCHARTING_FEATURES
		"modchart.engine",
		"modchart.backend.standalone",
		#end
		#end
	];

	// Runs support for abstract support in these
	public static final ALLOWED_ABSTRACT_AND_ENUM = [
		#if !DOCUMENTATION
		#if CODENAME_ENGINE_COMPAT
		// --- haxe stdlib ---
		"haxe.xml.Access",
		"haxe.CallStack",
		// --- flixel abstracts ---
		"flixel.graphics.atlas.AseAtlasColor",
		"flixel.graphics.atlas.AseAtlasTagRepeat",
		"flixel.graphics.atlas.HashOrArray",
		"flixel.graphics.frames.bmfont.BMFontXml",
		"flixel.system.FlxAngelCodeAsset",
		"flixel.system.FlxJsonAsset",
		"flixel.system.FlxXmlAsset",
		"flixel.util.FlxAxes",
		"flixel.util.FlxColor",
		"flixel.util.FlxTypedSignal",
		"flixel.util.PoolFactory",
		"flixel.util.UnicodeBuffer",
		"flixel.util.typeLimit.InitialState",
		"flixel.util.typeLimit.NextState",
		"flixel.util.typeLimit.OneOfFour",
		"flixel.util.typeLimit.OneOfThree",
		"flixel.util.typeLimit.OneOfTwo",
		"flixel.math.FlxPoint",
		"flixel.FlxObject",
		// --- openfl abstracts ---
		"openfl.Vector",
		"openfl.display.BlendMode",
		"openfl.display.ChildAccess",
		"openfl.display.ShaderData",
		"openfl.events.EventType",
		"openfl.net.URLVariables",
		"openfl.utils.ByteArray",
		"openfl.utils.Dictionary",
		"openfl.utils.JSON",
		"openfl.utils.Object",
		"openfl.xml.XML",
		"openfl.xml.XMLList",
		// --- lime abstracts ---
		"lime.graphics.CairoRenderContext",
		"lime.graphics.WebGL2RenderContext",
		"lime.graphics.WebGLRenderContext",
		"lime.graphics.opengl.GLTexture",
		"lime.math.ARGB",
		"lime.math.BGRA",
		"lime.math.ColorMatrix",
		"lime.math.Matrix3",
		"lime.math.Matrix4",
		"lime.math.RGBA",
		"lime.math.Vector2",
		"lime.math.Vector4",
		"lime.text.Glyph",
		"lime.text.UTF8String",
		"lime.utils.ArrayBuffer",
		"lime.utils.ArrayBufferView",
		"lime.utils.BytePointer",
		"lime.utils.Bytes",
		"lime.utils.DataPointer",
		"lime.utils.DataView",
		"lime.utils.Float32Array",
		"lime.utils.Float64Array",
		"lime.utils.Int16Array",
		"lime.utils.Int32Array",
		"lime.utils.Int8Array",
		"lime.utils.Resource",
		"lime.utils.TypedArrayType",
		"lime.utils.UInt16Array",
		"lime.utils.UInt32Array",
		"lime.utils.UInt8Array",
		"lime.utils.UInt8ClampedArray",
		// --- CNE abstracts ---
		"codename.funkin.backend.assets.AssetSource",
		#else
		"flixel",
		"openfl",
		"haxe.xml",
		"haxe.CallStack",
		"codename.funkin",
		#end
		#end
	];

	// Incase any of your files fail
	// These are the module names
	public static final DISALLOW_CUSTOM_CLASSES = [
		"flixel.addons", // flixel-addons/flixel-ui — static inline vars in default params break @:build macro
	];

	public static final DISALLOW_ABSTRACT_AND_ENUM = [
		"codename.funkin.backend.scripting.events.sprite.PlayAnimContext", // Error: expected member name or ';' after declaration specifiers, Due to define macro from math.h
		"flixel.input.keyboard.FlxKey", // NONE/DELETE collide with native macros; use the hand-written FlxKey_HSC wrapper
		"flixel.util.FlxDestroyUtil", // IFlxDestroyable in same file — not ready to be accessed
	];

	@:unreflective
	public static final IMPORT_BLACKLIST:Array<String> = [

	];
}
