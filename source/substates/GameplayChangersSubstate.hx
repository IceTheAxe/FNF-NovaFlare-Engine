package substates;

import general.objects.AttachedText;
import general.objects.CheckboxThingie;

class GameplayChangersSubstate extends MusicBeatSubstate
{
	private var curOption:GameplayOption = null;
	private var curSelected:Int = 0;
	private var optionsArray:Array<Dynamic> = [];

	private var grpOptions:FlxTypedGroup<Alphabet>;
	private var checkboxGroup:FlxTypedGroup<CheckboxThingie>;
	private var grpTexts:FlxTypedGroup<AttachedText>;

	// 鼠标控制相关变量
	var allowMouse:Bool = true;
	var timeNotMoving:Float = 0;
	var mouseOverItem:Int = -1;

	function getOptions()
	{
		var goption:GameplayOption = new GameplayOption('Scroll Type', 'scrolltype', 'string', 'multiplicative', ["multiplicative", "constant"]);
		optionsArray.push(goption);

		var option:GameplayOption = new GameplayOption('Scroll Speed', 'scrollspeed', 'float', 1);
		option.scrollSpeed = 2.0;
		option.minValue = 0.35;
		option.changeValue = 0.05;
		option.decimals = 2;
		if (goption.getValue() != "constant")
		{
			option.displayFormat = '%vX';
			option.maxValue = 3;
		}
		else
		{
			option.displayFormat = "%v";
			option.maxValue = 6;
		}
		optionsArray.push(option);

		#if FLX_PITCH
		var option:GameplayOption = new GameplayOption('Playback Rate', 'songspeed', 'float', 1);
		option.scrollSpeed = 1;
		option.minValue = 0.5;
		option.maxValue = 3.0;
		option.changeValue = 0.05;
		option.displayFormat = '%vX';
		option.decimals = 2;
		optionsArray.push(option);
		#end

		var option:GameplayOption = new GameplayOption('Health Gain Multiplier', 'healthgain', 'float', 1);
		option.scrollSpeed = 2.5;
		option.minValue = 0;
		option.maxValue = 5;
		option.changeValue = 0.1;
		option.displayFormat = '%vX';
		optionsArray.push(option);

		var option:GameplayOption = new GameplayOption('Health Loss Multiplier', 'healthloss', 'float', 1);
		option.scrollSpeed = 2.5;
		option.minValue = 0.5;
		option.maxValue = 5;
		option.changeValue = 0.1;
		option.displayFormat = '%vX';
		optionsArray.push(option);

		optionsArray.push(new GameplayOption('Instakill on Miss', 'instakill', 'bool', false));
		optionsArray.push(new GameplayOption('Practice Mode', 'practice', 'bool', false));
		optionsArray.push(new GameplayOption('Botplay', 'botplay', 'bool', false));
	}

	public function getOptionByName(name:String)
	{
		for (i in optionsArray)
		{
			var opt:GameplayOption = i;
			if (opt.name == name)
				return opt;
		}
		return null;
	}

	public function new()
	{
		super();

		var bg:FlxSprite = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, FlxColor.BLACK);
		bg.alpha = 0.6;
		add(bg);

		// avoids lagspikes while scrolling through menus!
		grpOptions = new FlxTypedGroup<Alphabet>();
		add(grpOptions);

		grpTexts = new FlxTypedGroup<AttachedText>();
		add(grpTexts);

		checkboxGroup = new FlxTypedGroup<CheckboxThingie>();
		add(checkboxGroup);

		getOptions();

		for (i in 0...optionsArray.length)
		{
			var optionText:Alphabet = new Alphabet(200, 360, optionsArray[i].name, true);
			optionText.isMenuItem = true;
			optionText.setScale(0.8);
			optionText.targetY = i;
			grpOptions.add(optionText);

			if (optionsArray[i].type == 'bool')
			{
				optionText.x += 90;
				optionText.startPosition.x += 90;
				optionText.snapToPosition();
				var checkbox:CheckboxThingie = new CheckboxThingie(optionText.x - 105, optionText.y, optionsArray[i].getValue() == true);
				checkbox.sprTracker = optionText;
				checkbox.offsetX -= 20;
				checkbox.offsetY = -52;
				checkbox.ID = i;
				checkboxGroup.add(checkbox);
			}
			else
			{
				optionText.snapToPosition();
				var valueText:AttachedText = new AttachedText(Std.string(optionsArray[i].getValue()), optionText.width + 40, 0, true, 0.8);
				valueText.sprTracker = optionText;
				valueText.copyAlpha = true;
				valueText.ID = i;
				grpTexts.add(valueText);
				optionsArray[i].setChild(valueText);
			}
			updateTextFrom(optionsArray[i]);
		}

		addVirtualPad(LEFT_FULL, A_B_C);
		addVirtualPadCamera(false);

		virtualPad.y -= FlxG.height * 0.1;

		changeSelection();
		reloadCheckboxes();

		cameras = [FlxG.cameras.list[FlxG.cameras.list.length - 1]];
	}

	var nextAccept:Int = 5;
	var holdTime:Float = 0;
	var holdValue:Float = 0;

	override function update(elapsed:Float)
	{
		// 鼠标控制逻辑
		if (FlxG.mouse.deltaScreenX != 0 || FlxG.mouse.deltaScreenY != 0)
		{
			FlxG.mouse.visible = true;
			timeNotMoving = 0;
			
			// 检查鼠标悬停
			checkMouseOver();
		}
		
		// 鼠标滚轮逻辑
		if (FlxG.mouse.wheel != 0)
		{
			FlxG.mouse.visible = true;
			timeNotMoving = 0;
			
			if (mouseOverItem != -1 && mouseOverItem == curSelected)
			{
				// 鼠标悬停在当前选中的选项上：调整数值
				var usesCheckbox:Bool = (curOption.type == 'bool');
				if (!usesCheckbox && nextAccept <= 0)
				{
					var wheelValue:Float = FlxG.mouse.wheel * (FlxG.keys.pressed.SHIFT ? 3 : 1);
					
					switch(curOption.type)
					{
						case 'int', 'float', 'percent':
							var add:Dynamic = wheelValue * curOption.changeValue;
							holdValue = curOption.getValue() + add;
							if(holdValue < curOption.minValue) holdValue = curOption.minValue;
							else if (holdValue > curOption.maxValue) holdValue = curOption.maxValue;

							switch(curOption.type)
							{
								case 'int':
									holdValue = Math.round(holdValue);
									curOption.setValue(holdValue);

								case 'float', 'percent':
									holdValue = FlxMath.roundDecimal(holdValue, curOption.decimals);
									curOption.setValue(holdValue);

								default:
							}
							FlxG.sound.play(Paths.sound('scrollMenu'));

						case 'string':
							var num:Int = curOption.curOption;
							if(wheelValue < 0) --num;
							else num++;

							if(num < 0)
								num = curOption.options.length - 1;
							else if(num >= curOption.options.length)
								num = 0;

							curOption.curOption = num;
							curOption.setValue(curOption.options[num]);
							
							if (curOption.name == "Scroll Type")
							{
								var oOption:GameplayOption = getOptionByName("Scroll Speed");
								if (oOption != null)
								{
									if (curOption.getValue() == "constant")
									{
										oOption.displayFormat = "%v";
										oOption.maxValue = 6;
									}
									else
									{
										oOption.displayFormat = "%vX";
										oOption.maxValue = 3;
										if(oOption.getValue() > 3) oOption.setValue(3);
									}
									updateTextFrom(oOption);
								}
							}
							FlxG.sound.play(Paths.sound('scrollMenu'));

						default:
					}
					updateTextFrom(curOption);
					curOption.change();
				}
			}
			else
			{
				// 鼠标不在选项上或不在当前选中的选项上：上下滚动选择
				var shiftMult:Int = FlxG.keys.pressed.SHIFT ? 3 : 1;
				changeSelection(-shiftMult * FlxG.mouse.wheel);
			}
		}

		// 键盘控制 - UP/DOWN
		if (controls.UI_UP_P)
		{
			changeSelection(-1);
		}
		if (controls.UI_DOWN_P)
		{
			changeSelection(1);
		}

		// 键盘控制 - 长按加速
		if(controls.UI_DOWN || controls.UI_UP)
		{
			var checkLastHold:Int = Math.floor((holdTime - 0.5) * 10);
			holdTime += elapsed;
			var checkNewHold:Int = Math.floor((holdTime - 0.5) * 10);

			if(holdTime > 0.5 && checkNewHold - checkLastHold > 0)
			{
				changeSelection((checkNewHold - checkLastHold) * (controls.UI_UP ? -1 : 1));
			}
		}

		// 鼠标点击选择选项
		if (FlxG.mouse.justPressed)
		{
			// 先检查鼠标悬停状态
			checkMouseOver();
			
			if (mouseOverItem != -1)
			{
				if (curSelected != mouseOverItem)
				{
					// 左键点击未选中的选项：选择它
					curSelected = mouseOverItem;
					changeSelection();
				}
				else
				{
					// 左键点击已选中的选项：如果是复选框则切换
					var usesCheckbox:Bool = (curOption.type == 'bool');
					if (usesCheckbox && nextAccept <= 0)
					{
						FlxG.sound.play(Paths.sound('scrollMenu'));
						curOption.setValue((curOption.getValue() == true) ? false : true);
						curOption.change();
						reloadCheckboxes();
					}
				}
			}
		}

		if (controls.BACK)
		{
			ClientPrefs.saveSettings();
			close();
			FlxG.sound.play(Paths.sound('cancelMenu'));
		}
		
		// 鼠标拖动调整数值（非布尔类型和非字符串类型）
		if (FlxG.mouse.pressed && mouseOverItem != -1 && mouseOverItem == curSelected && 
			!(curOption.type == 'bool') && curOption.type != 'string' && nextAccept <= 0)
		{
			var mouseDelta:Float = FlxG.mouse.deltaScreenX;
			if (Math.abs(mouseDelta) > 2)
			{
				var add:Dynamic = mouseDelta * curOption.changeValue * 0.5;
				holdValue = curOption.getValue() + add;
				if(holdValue < curOption.minValue) holdValue = curOption.minValue;
				else if (holdValue > curOption.maxValue) holdValue = curOption.maxValue;

				switch(curOption.type)
				{
					case 'int':
						holdValue = Math.round(holdValue);
						curOption.setValue(holdValue);

					case 'float', 'percent':
						holdValue = FlxMath.roundDecimal(holdValue, curOption.decimals);
						curOption.setValue(holdValue);

					default:
				}
				
				updateTextFrom(curOption);
				curOption.change();
				
				timeNotMoving = 0;
			}
		}

		if (nextAccept <= 0)
		{
			var usesCheckbox = true;
			if (curOption.type != 'bool')
			{
				usesCheckbox = false;
			}

			if (usesCheckbox)
			{
				if (controls.ACCEPT)
				{
					FlxG.sound.play(Paths.sound('scrollMenu'));
					curOption.setValue((curOption.getValue() == true) ? false : true);
					curOption.change();
					reloadCheckboxes();
				}
			}
			else
			{
				if (controls.UI_LEFT || controls.UI_RIGHT)
				{
					var pressed = (controls.UI_LEFT_P || controls.UI_RIGHT_P);
					if (holdTime > 0.5 || pressed)
					{
						if (pressed)
						{
							var add:Dynamic = null;
							if (curOption.type != 'string')
							{
								add = controls.UI_LEFT ? -curOption.changeValue : curOption.changeValue;
							}

							switch (curOption.type)
							{
								case 'int' | 'float' | 'percent':
									holdValue = curOption.getValue() + add;
									if (holdValue < curOption.minValue)
										holdValue = curOption.minValue;
									else if (holdValue > curOption.maxValue)
										holdValue = curOption.maxValue;

									switch (curOption.type)
									{
										case 'int':
											holdValue = Math.round(holdValue);
											curOption.setValue(holdValue);

										case 'float' | 'percent':
											holdValue = FlxMath.roundDecimal(holdValue, curOption.decimals);
											curOption.setValue(holdValue);
									}

								case 'string':
									var num:Int = curOption.curOption;
									if (controls.UI_LEFT_P)
										--num;
									else
										num++;

									if (num < 0)
									{
										num = curOption.options.length - 1;
									}
									else if (num >= curOption.options.length)
									{
										num = 0;
									}

									curOption.curOption = num;
									curOption.setValue(curOption.options[num]);

									if (curOption.name == "Scroll Type")
									{
										var oOption:GameplayOption = getOptionByName("Scroll Speed");
										if (oOption != null)
										{
											if (curOption.getValue() == "constant")
											{
												oOption.displayFormat = "%v";
												oOption.maxValue = 6;
											}
											else
											{
												oOption.displayFormat = "%vX";
												oOption.maxValue = 3;
												if (oOption.getValue() > 3)
													oOption.setValue(3);
											}
											updateTextFrom(oOption);
										}
									}
							}
							updateTextFrom(curOption);
							curOption.change();
							FlxG.sound.play(Paths.sound('scrollMenu'));
						}
						else if (curOption.type != 'string')
						{
							holdValue = Math.max(curOption.minValue,
								Math.min(curOption.maxValue, holdValue + curOption.scrollSpeed * elapsed * (controls.UI_LEFT ? -1 : 1)));

							switch (curOption.type)
							{
								case 'int':
									curOption.setValue(Math.round(holdValue));

								case 'float' | 'percent':
									var blah:Float = Math.max(curOption.minValue,
										Math.min(curOption.maxValue, holdValue + curOption.changeValue - (holdValue % curOption.changeValue)));
									curOption.setValue(FlxMath.roundDecimal(blah, curOption.decimals));
							}
							updateTextFrom(curOption);
							curOption.change();
						}
					}

					if (curOption.type != 'string')
					{
						holdTime += elapsed;
					}
				}
				else if (controls.UI_LEFT_R || controls.UI_RIGHT_R)
				{
					clearHold();
				}
			}

			if (controls.RESET || virtualPad.buttonC.justPressed)
			{
				for (i in 0...optionsArray.length)
				{
					var leOption:GameplayOption = optionsArray[i];
					leOption.setValue(leOption.defaultValue);
					if (leOption.type != 'bool')
					{
						if (leOption.type == 'string')
						{
							leOption.curOption = leOption.options.indexOf(leOption.getValue());
						}
						updateTextFrom(leOption);
					}

					if (leOption.name == 'Scroll Speed')
					{
						leOption.displayFormat = "%vX";
						leOption.maxValue = 3;
						if (leOption.getValue() > 3)
						{
							leOption.setValue(3);
						}
						updateTextFrom(leOption);
					}
					leOption.change();
				}
				FlxG.sound.play(Paths.sound('cancelMenu'));
				reloadCheckboxes();
			}
		}

		if (nextAccept > 0)
		{
			nextAccept -= 1;
		}
		if (virtualPad == null)
		{
			addVirtualPad(LEFT_FULL, A_B_C);
			addVirtualPadCamera(false);
		}
		super.update(elapsed);
	}

	// 检查鼠标悬停
	function checkMouseOver():Void
	{
		var newMouseOverItem:Int = -1;
		
		// 检查选项文本
		for (i in 0...grpOptions.length)
		{
			var item:Alphabet = grpOptions.members[i];
			if (item != null && FlxG.mouse.overlaps(item))
			{
				newMouseOverItem = i;
				break;
			}
		}
		
		// 如果没找到，检查复选框
		if (newMouseOverItem == -1)
		{
			for (checkbox in checkboxGroup)
			{
				if (checkbox != null && FlxG.mouse.overlaps(checkbox))
				{
					newMouseOverItem = checkbox.ID;
					break;
				}
			}
		}
		
		// 如果还没找到，检查值文本
		if (newMouseOverItem == -1)
		{
			for (text in grpTexts)
			{
				if (text != null && FlxG.mouse.overlaps(text))
				{
					newMouseOverItem = text.ID;
					break;
				}
			}
		}
		
		if (newMouseOverItem != mouseOverItem)
		{
			mouseOverItem = newMouseOverItem;
			updateMouseHover();
			timeNotMoving = 0;
		}
	}
	
	function updateMouseHover()
	{
		for (num => item in grpOptions.members)
		{
			if (item != null)
			{
				item.alpha = 0.6;
				if (item.targetY == 0)
					item.alpha = 1;
				else if (mouseOverItem == num)
					item.alpha = 0.8;
			}
		}
		for (text in grpTexts)
		{
			if (text != null)
			{
				text.alpha = 0.6;
				if(text.ID == curSelected)
					text.alpha = 1;
				else if(mouseOverItem == text.ID)
					text.alpha = 0.8;
			}
		}
	}

	function updateTextFrom(option:GameplayOption)
	{
		var text:String = option.displayFormat;
		var val:Dynamic = option.getValue();
		if (option.type == 'percent')
			val *= 100;
		var def:Dynamic = option.defaultValue;
		option.text = text.replace('%v', val).replace('%d', def);
	}

	function clearHold()
	{
		if (holdTime > 0.5)
		{
			FlxG.sound.play(Paths.sound('scrollMenu'));
		}
		holdTime = 0;
	}

	function changeSelection(change:Int = 0)
	{
		curSelected += change;
		if (curSelected < 0)
			curSelected = optionsArray.length - 1;
		if (curSelected >= optionsArray.length)
			curSelected = 0;

		var bullShit:Int = 0;

		for (item in grpOptions.members)
		{
			item.targetY = bullShit - curSelected;
			bullShit++;

			item.alpha = 0.6;
			if (item.targetY == 0)
			{
				item.alpha = 1;
			}
		}
		for (text in grpTexts)
		{
			text.alpha = 0.6;
			if (text.ID == curSelected)
			{
				text.alpha = 1;
			}
		}
		
		// 重置鼠标悬停状态
		mouseOverItem = -1;
		updateMouseHover();
		
		curOption = optionsArray[curSelected];
		FlxG.sound.play(Paths.sound('scrollMenu'));
	}

	function reloadCheckboxes()
	{
		for (checkbox in checkboxGroup)
		{
			checkbox.daValue = (optionsArray[checkbox.ID].getValue() == true);
		}
	}
}

class GameplayOption
{
	private var child:Alphabet;

	public var text(get, set):String;
	public var onChange:Void->Void = null;

	public var type(get, default):String = 'bool';

	public var showBoyfriend:Bool = false;
	public var scrollSpeed:Float = 50;

	private var variable:String = null;

	public var defaultValue:Dynamic = null;

	public var curOption:Int = 0;
	public var options:Array<String> = null;
	public var changeValue:Dynamic = 1;
	public var minValue:Dynamic = null;
	public var maxValue:Dynamic = null;
	public var decimals:Int = 1;

	public var displayFormat:String = '%v';
	public var name:String = 'Unknown';

	public function new(name:String, variable:String, type:String = 'bool', defaultValue:Dynamic = 'null variable value', ?options:Array<String> = null)
	{
		this.name = name;
		this.variable = variable;
		this.type = type;
		this.defaultValue = defaultValue;
		this.options = options;

		if (defaultValue == 'null variable value')
		{
			switch (type)
			{
				case 'bool':
					defaultValue = false;
				case 'int' | 'float':
					defaultValue = 0;
				case 'percent':
					defaultValue = 1;
				case 'string':
					defaultValue = '';
					if (options.length > 0)
					{
						defaultValue = options[0];
					}
			}
		}

		if (getValue() == null)
		{
			setValue(defaultValue);
		}

		switch (type)
		{
			case 'string':
				var num:Int = options.indexOf(getValue());
				if (num > -1)
				{
					curOption = num;
				}

			case 'percent':
				displayFormat = '%v%';
				changeValue = 0.01;
				minValue = 0;
				maxValue = 1;
				scrollSpeed = 0.5;
				decimals = 2;
		}
	}

	public function change()
	{
		if (onChange != null)
		{
			onChange();
		}
	}

	public function getValue():Dynamic
	{
		return ClientPrefs.data.gameplaySettings.get(variable);
	}

	public function setValue(value:Dynamic)
	{
		ClientPrefs.data.gameplaySettings.set(variable, value);
	}

	public function setChild(child:Alphabet)
	{
		this.child = child;
	}

	private function get_text()
	{
		if (child != null)
		{
			return child.text;
		}
		return null;
	}

	private function set_text(newValue:String = '')
	{
		if (child != null)
		{
			child.text = newValue;
		}
		return null;
	}

	private function get_type()
	{
		var newValue:String = 'bool';
		switch (type.toLowerCase().trim())
		{
			case 'int' | 'float' | 'percent' | 'string':
				newValue = type;
			case 'integer':
				newValue = 'int';
			case 'str':
				newValue = 'string';
			case 'fl':
				newValue = 'float';
		}
		type = newValue;
		return type;
	}
}