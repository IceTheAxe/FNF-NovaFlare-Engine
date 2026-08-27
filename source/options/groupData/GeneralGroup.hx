package options.groupData;

import general.shaders.ColorblindFilter;

#if mobile
import general.objects.screen.MouseEffect;
#end
class GeneralGroup extends OptionCata
{
	public function new(X:Float, Y:Float, width:Float, height:Float)
	{
		super(X, Y, width, height);

		var option:Option = new Option(this, 'General', TITLE);
		addOption(option);

		
		#if mobile
		var option:Option = new Option(this, 'mouseTrailEffect', BOOL);
		addOption(option);
		option.onChange = onChangeMouseEffects;
		#end

		var option:Option = new Option(this, 'autoPause', BOOL);
		addOption(option);
		option.onChange = onChangePause;

		var colorblindFilterArray:Array<String> = [
			'None',
			'Protanopia',
			'Protanomaly',
			'Deuteranopia',
			'Deuteranomaly',
			'Tritanopia',
			'Tritanomaly',
			'Achromatopsia',
			'Achromatomaly'
		];
		var colorblindDisplayArray:Array<String> = [
			'None',
			'Protanopia',
			'Protanomaly',
			'Deuteranopia',
			'Deuteranomaly',
			'Tritanopia',
			'Tritanomaly',
			'Achromatopsia',
			'Achromatomaly'
		];

		var option:Option = new Option(this, 'colorblindMode', STRING, [colorblindFilterArray, colorblindDisplayArray]);
		addOption(option);
		option.onChange = onChangeFilter;

		changeHeight(0);
	}

	///////////////////////////////////////////////////////////////////////////


	///////////////////////////////////////////////////////////////

	function onChangeFilter()
	{
		ColorblindFilter.UpdateColors();
	}

	function onChangePause()
	{
		FlxG.autoPause = ClientPrefs.data.autoPause;
	}

	#if mobile
	function onChangeMouseEffects()
	{
		MouseEffect.setUserEffectsEnabled(ClientPrefs.data.mouseTrailEffect);
	}
	#end
}
