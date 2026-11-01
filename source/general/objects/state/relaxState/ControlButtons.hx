package general.objects.state.relaxState;
#if RELAX_ALLOWED

import flixel.util.FlxSpriteUtil;

class ControlButtons
{
	public var LeftButton:ButtonSprite;
	public var MiddleButton:FlxSprite;
	public var RightButton:ButtonSprite;
	
	public var SaveY:Array<Float> = [];
	
	public function new()
	{
		createButtons();
	}

	private function createButtons():Void
	{
		var buttonHeight = 60;
		var buttonSpacing = 15;
		var buttonWidth = 100;
		var buttonY = FlxG.height - buttonHeight - 10;

		var totalWidth = buttonWidth * 3 + buttonSpacing * 2;
		var startX = (FlxG.width - totalWidth) / 2;

		LeftButton = new ButtonSprite(startX, buttonY, buttonWidth, buttonHeight, 10, 10);
		LeftButton.scrollFactor.set(0, 0);

		MiddleButton = new FlxSprite(LeftButton.x + LeftButton.width + buttonSpacing, buttonY);
		MiddleButton.makeGraphic(buttonWidth, Std.int(buttonHeight), 0xFF24232C);
		MiddleButton.scrollFactor.set(0, 0);

		RightButton = new ButtonSprite(MiddleButton.x + MiddleButton.width + buttonSpacing, buttonY, buttonWidth, buttonHeight, 10, 10);
		RightButton.scrollFactor.set(0, 0);

		// 重新计算位置确保居中
		totalWidth = Std.int(LeftButton.width + MiddleButton.width + RightButton.width + 30);
		startX = (FlxG.width - totalWidth) / 2;
		buttonY = Std.int(FlxG.height - LeftButton.height - 10);

		LeftButton.x = startX;
		MiddleButton.x = LeftButton.x + LeftButton.width + 15;
		RightButton.x = MiddleButton.x + MiddleButton.width + 15;

		LeftButton.y = buttonY;
		MiddleButton.y = buttonY;
		RightButton.y = buttonY;

		SaveY = [LeftButton.y, RightButton.y];
	}

	public function updateButtons(mousePos:FlxPoint):Void
	{
		var isOverLeft = LeftButton.overlapsPoint(mousePos, true);
		var isOverMiddle = MiddleButton.overlapsPoint(mousePos, true);
		var isOverRight = RightButton.overlapsPoint(mousePos, true);

		LeftButton.alpha = isOverLeft ? 0.8 : 1;
		MiddleButton.alpha = isOverMiddle ? 0.8 : 1;
		RightButton.alpha = isOverRight ? 0.8 : 1;
	}

	public function handleClick(mousePos:FlxPoint, onLeftClick:Void->Void, onMiddleClick:Void->Void, onRightClick:Void->Void):Bool
	{
		var isOverLeft = LeftButton.overlapsPoint(mousePos, true);
		var isOverMiddle = MiddleButton.overlapsPoint(mousePos, true);
		var isOverRight = RightButton.overlapsPoint(mousePos, true);

		if (FlxG.mouse.justPressed) {
			if (isOverLeft) {
				FlxG.sound.play(Paths.sound('scrollMenu'), 0.7);
				FlxTween.tween(LeftButton, {y: SaveY[0] + 5}, 0.1, {
					ease: FlxEase.quadOut,
					onComplete: function(_) FlxTween.tween(LeftButton, {y: SaveY[0]}, 0.1)
				});
				if (onLeftClick != null) onLeftClick();
				return true;
			}
			else if (isOverMiddle) {
				FlxG.sound.play(Paths.sound('scrollMenu'), 0.7);
				if (onMiddleClick != null) onMiddleClick();
				return true;
			}
			else if (isOverRight) {
				FlxG.sound.play(Paths.sound('scrollMenu'), 0.7);
				FlxTween.tween(RightButton, {y: SaveY[1] + 5}, 0.1, {
					ease: FlxEase.quadOut,
					onComplete: function(_) FlxTween.tween(RightButton, {y: SaveY[1]}, 0.1)
				});
				if (onRightClick != null) onRightClick();
				return true;
			}
		}
		return false;
	}

	public function beatAnimation(beatTime:Float):Void
	{
		var saveFaX1 = LeftButton.x;
		var saveFaX2 = RightButton.x;

		LeftButton.x += 5;
		RightButton.x -= 5;

		FlxTween.tween(LeftButton, {x: saveFaX1}, beatTime * 0.5, {
			ease: FlxEase.quadOut
		});

		FlxTween.tween(RightButton, {x: saveFaX2}, beatTime * 0.5, {
			ease: FlxEase.quadOut
		});
	}

	public function fourBeatAnimation(beatTime:Float):Void
	{
		var saveFaY1 = LeftButton.y;
		var saveFaY2 = RightButton.y;
		var saveFaY3 = MiddleButton.y;

		LeftButton.y += 5;
		RightButton.y += 5;
		MiddleButton.y += 5;

		FlxTween.tween(LeftButton, {y: saveFaY1}, beatTime * 0.5, {
			ease: FlxEase.quadOut
		});

		FlxTween.tween(MiddleButton, {y: saveFaY3}, beatTime * 0.5, {
			ease: FlxEase.quadOut
		});

		FlxTween.tween(RightButton, {y: saveFaY2}, beatTime * 0.5, {
			ease: FlxEase.quadOut
		});
	}
	
	/**
	 * 检查鼠标是否悬停在左按钮上
	 * @param mousePos 鼠标位置
	 * @return 是否悬停
	 */
	public function isMouseOverLeftButton(mousePos:FlxPoint):Bool
	{
		return LeftButton.overlapsPoint(mousePos, true);
	}
	
	/**
	 * 检查鼠标是否悬停在中间按钮上
	 * @param mousePos 鼠标位置
	 * @return 是否悬停
	 */
	public function isMouseOverMiddleButton(mousePos:FlxPoint):Bool
	{
		return MiddleButton.overlapsPoint(mousePos, true);
	}
	
	/**
	 * 检查鼠标是否悬停在右按钮上
	 * @param mousePos 鼠标位置
	 * @return 是否悬停
	 */
	public function isMouseOverRightButton(mousePos:FlxPoint):Bool
	{
		return RightButton.overlapsPoint(mousePos, true);
	}
	
	/**
	 * 设置按钮透明度
	 * @param isOverLeft 鼠标是否悬停在左按钮上
	 * @param isOverMiddle 鼠标是否悬停在中间按钮上
	 * @param isOverRight 鼠标是否悬停在右按钮上
	 */
	public function setButtonAlphas(isOverLeft:Bool, isOverMiddle:Bool, isOverRight:Bool):Void
	{
		LeftButton.alpha = isOverLeft ? 0.8 : 1;
		MiddleButton.alpha = isOverMiddle ? 0.8 : 1;
		RightButton.alpha = isOverRight ? 0.8 : 1;
	}
	
	/**
	 * 处理左按钮按下动画
	 * @param duration 动画持续时间
	 */
	public function animateLeftButtonPress(duration:Float):Void
	{
		FlxTween.tween(LeftButton, {y: SaveY[0] + 5}, duration, {
			ease: FlxEase.quadOut,
			onComplete: function(_) FlxTween.tween(LeftButton, {y: SaveY[0]}, duration)
		});
	}
	
	/**
	 * 处理右按钮按下动画
	 * @param duration 动画持续时间
	 */
	public function animateRightButtonPress(duration:Float):Void
	{
		FlxTween.tween(RightButton, {y: SaveY[1] + 5}, duration, {
			ease: FlxEase.quadOut,
			onComplete: function(_) FlxTween.tween(RightButton, {y: SaveY[1]}, duration)
		});
	}
	
	/**
	 * 处理节拍动画（别名方法，调用beatAnimation）
	 * @param beatTime 节拍时间
	 */
	public function handleBeatAnimation(beatTime:Float):Void
	{
		beatAnimation(beatTime);
	}
	
	/**
	 * 处理四拍动画（别名方法，调用fourBeatAnimation）
	 * @param beatTime 节拍时间
	 */
	public function handleFourTimeBeatAnimation(beatTime:Float):Void
	{
		fourBeatAnimation(beatTime);
	}
	
	/**
	 * 销毁按钮资源
	 */
	public function destroy():Void
	{
		if (LeftButton != null) {
			LeftButton.destroy();
			LeftButton = null;
		}
		
		if (MiddleButton != null) {
			MiddleButton.destroy();
			MiddleButton = null;
		}
		
		if (RightButton != null) {
			RightButton.destroy();
			RightButton = null;
		}
	}
}#end