package general.objects.state.relaxState;
#if RELAX_ALLOWED

import flixel.util.FlxSpriteUtil;

class TopButtons extends FlxSpriteGroup
{
	public var settingButton:FlxSprite;
	public var listButton:FlxSprite;
	public var lockButton:FlxSprite;
	
	public var settingBg:FlxSprite;
	public var listBg:FlxSprite;
	public var lockBg:FlxSprite;

	public var isSettingActive:Bool = false;
	public var isListActive:Bool = false;
	public var isLockActive:Bool = false;

	public var clickList:Bool = false;
	public var clickOption:Bool = false;
	public var clickLock:Bool = false;

	public function new()
	{
		super();
		createTopButtons();
	}

	private function createTopButtons():Void
	{
		// 按钮大小和间距
		var buttonSize:Int = 40;
		var buttonSpacing:Int = 80;
		var buttonY:Float = 0;
		var buttonY2:Float = buttonY + 5;

		// 创建按钮背景
		var bgColor:FlxColor = FlxColor.WHITE;
		bgColor.alphaFloat = 0.3;

		// 设置按钮（居中）
		settingButton = new FlxSprite((FlxG.width - buttonSize) / 2, buttonY2);
		settingButton.loadGraphic('assets/shared/images/menuExtend/RelaxState/setting.png');
		settingButton.scrollFactor.set();
		settingButton.scale.set(0.5, 0.5);
		settingButton.updateHitbox();
		settingButton.x = (FlxG.width - buttonSize) / 2;
		settingButton.y = buttonY2;

		settingBg = new FlxSprite(settingButton.x - buttonSize + settingButton.width / 2, buttonY);
		settingBg.makeGraphic(buttonSize * 2, buttonSize, bgColor);
		add(settingBg);
		add(settingButton);

		// 歌单按钮（设置按钮左侧）
		listButton = new FlxSprite(settingButton.x - buttonSize - buttonSpacing, buttonY2);
		listButton.loadGraphic('assets/shared/images/menuExtend/RelaxState/list.png');
		listButton.scrollFactor.set();
		listButton.scale.set(0.5, 0.5);
		listButton.updateHitbox();
		listButton.x = settingButton.x - buttonSize - buttonSpacing;
		listButton.y = buttonY2;
		
		listBg = new FlxSprite(settingButton.x - buttonSize * 2 - buttonSpacing + settingButton.width / 2, buttonY);
		listBg.makeGraphic(buttonSize * 2, buttonSize, bgColor);
		listBg.scrollFactor.set();
		add(listBg);
		add(listButton);

		// 锁定按钮（设置按钮右侧）
		lockButton = new FlxSprite(settingButton.x + buttonSize + buttonSpacing, buttonY2);
		lockButton.loadGraphic('assets/shared/images/menuExtend/RelaxState/rock.png');
		lockButton.scrollFactor.set();
		lockButton.scale.set(0.5, 0.5);
		lockButton.updateHitbox();
		lockButton.x = settingButton.x + buttonSize + buttonSpacing;
		lockButton.y = buttonY2;

		lockBg = new FlxSprite(settingButton.x + buttonSpacing + lockButton.width / 2, buttonY);
		lockBg.makeGraphic(buttonSize * 2, buttonSize, bgColor);
		lockBg.scrollFactor.set();
		add(lockBg);
		add(lockButton);
	}

	public function updateButtons(mousePos:FlxPoint):Void
	{
		var isOverList = listBg.overlapsPoint(mousePos, true);
		var isOverSetting = settingBg.overlapsPoint(mousePos, true);
		var isOverRock = lockBg.overlapsPoint(mousePos, true);
		
		listBg.alpha = isOverList ? 1 : (clickList ? 0.5 : 0.1);
		settingBg.alpha = isOverSetting ? 1: (clickOption ? 0.5 : 0.1);
		lockBg.alpha = isOverRock ? 1 : (clickLock ? 0.5 : 0.1);
	}
	
	/**
	 * 检查鼠标是否悬停在列表按钮上
	 * @param mousePos 鼠标位置
	 * @return 是否悬停
	 */
	public function isMouseOverListButton(mousePos:FlxPoint):Bool
	{
		return listBg.overlapsPoint(mousePos, true);
	}
	
	/**
	 * 检查鼠标是否悬停在设置按钮上
	 * @param mousePos 鼠标位置
	 * @return 是否悬停
	 */
	public function isMouseOverSettingButton(mousePos:FlxPoint):Bool
	{
		return settingBg.overlapsPoint(mousePos, true);
	}
	
	/**
	 * 检查鼠标是否悬停在锁定按钮上
	 * @param mousePos 鼠标位置
	 * @return 是否悬停
	 */
	public function isMouseOverLockButton(mousePos:FlxPoint):Bool
	{
		return lockBg.overlapsPoint(mousePos, true);
	}
	
	/**
	 * 设置按钮透明度
	 * @param isOverList 鼠标是否悬停在列表按钮上
	 * @param isOverSetting 鼠标是否悬停在设置按钮上
	 * @param isOverRock 鼠标是否悬停在锁定按钮上
	 * @param clickList 列表按钮是否被点击
	 * @param clickOption 设置按钮是否被点击
	 * @param clickLock 锁定按钮是否被点击
	 */
	public function setButtonAlphas(isOverList:Bool, isOverSetting:Bool, isOverRock:Bool, clickList:Bool, clickOption:Bool, clickLock:Bool):Void
	{
		this.clickList = clickList;
		this.clickOption = clickOption;
		this.clickLock = clickLock;
		
		listBg.alpha = isOverList ? 1 : (clickList ? 0.5 : 0.1);
		settingBg.alpha = isOverSetting ? 1: (clickOption ? 0.5 : 0.1);
		lockBg.alpha = isOverRock ? 1 : (clickLock ? 0.5 : 0.1);
	}
	
	/**
	 * 处理节拍动画
	 * @param helpBool 辅助布尔值
	 * @param beatTime 节拍时间
	 */
	public function handleBeatAnimation(helpBool:Bool, beatTime:Float):Void
	{
		if (helpBool) {
			settingButton.scale.set(0.6, 0.4);
			listButton.scale.set(0.6, 0.4);
			lockButton.scale.set(0.6, 0.4);
		} else {
			settingButton.scale.set(0.4, 0.6);
			listButton.scale.set(0.4, 0.6);
			lockButton.scale.set(0.4, 0.6);
		}
		
		FlxTween.tween(settingButton.scale, {x: 0.5, y: 0.5}, beatTime * 0.5, {
			ease: FlxEase.quadOut
		});
		
		FlxTween.tween(listButton.scale, {x: 0.5, y: 0.5}, beatTime * 0.5, {
			ease: FlxEase.quadOut
		});
		
		FlxTween.tween(lockButton.scale, {x: 0.5, y: 0.5}, beatTime * 0.5, {
			ease: FlxEase.quadOut
		});
	}
}#end