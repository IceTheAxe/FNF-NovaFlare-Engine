/*
 * Copyright (C) 2025 Mobile Porting Team
 *
 * Permission is hereby granted, free of charge, to any person obtaining a
 * copy of this software and associated documentation files (the "Software"),
 * to deal in the Software without restriction, including without limitation
 * the rights to use, copy, modify, merge, publish, distribute, sublicense,
 * and/or sell copies of the Software, and to permit persons to whom the
 * Software is furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
 * FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
 * DEALINGS IN THE SOFTWARE.
 */

package mobile.backend;

import flixel.FlxG;
import flixel.system.scaleModes.BaseScaleMode;
import general.backend.ClientPrefs;

/**
 * 宽屏 scaleMode（自 FE 移动版移植）：
 * wideScreen 开启时画布铺满整个窗口（配合 Main.hx 启动时按屏幕比例算出的画布，
 * FlxG.width/height 即真宽屏值，UI 用 FlxG.width 自动获得更多视野）；
 * 关闭时按画布比例信箱居中（等价于 RatioScaleMode 的行为，画面不变形）。
 * @author: Karim Akra
 */
class MobileScaleMode extends BaseScaleMode
{
	/// kill-switch：需要临时禁用宽屏铺满时置 false（会自动重挂 scaleMode）
	public static var allowWideScreen(default, set):Bool = true;

	override function updateGameSize(Width:Int, Height:Int):Void
	{
		if (ClientPrefs.data.wideScreen && allowWideScreen)
		{
			// BaseScaleMode 默认行为 = Fill：gameSize = 窗口尺寸，铺满
			super.updateGameSize(Width, Height);
		}
		else
		{
			var ratio:Float = FlxG.width / FlxG.height; // 画布比例
			var realRatio:Float = Width / Height; // 窗口比例

			var scaleY:Bool = realRatio < ratio;

			if (scaleY)
			{
				gameSize.x = Width;
				gameSize.y = Math.floor(gameSize.x / ratio);
			}
			else
			{
				gameSize.y = Height;
				gameSize.x = Math.floor(gameSize.y * ratio);
			}
		}
	}

	override function updateGamePosition():Void
	{
		if (ClientPrefs.data.wideScreen && allowWideScreen)
		{
			if (FlxG.game != null)
				FlxG.game.x = FlxG.game.y = 0; // 铺满，不居中
		}
		else
			super.updateGamePosition(); // 信箱居中
	}

	@:noCompletion
	private static function set_allowWideScreen(value:Bool):Bool
	{
		allowWideScreen = value;
		FlxG.scaleMode = new MobileScaleMode();
		return value;
	}
}
