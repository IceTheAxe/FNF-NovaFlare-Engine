package options.objects.backend;

import openfl.display.Shape;
import openfl.display.BitmapData;

class NumButton extends FlxSpriteGroup {

    var follow:Option;

    var innerX:Float; //该摁键在option的x
    var innerY:Float; //该摁键在option的y

    public var deleteButton:FlxSprite;
    public var addButton:FlxSprite;

    public var moveBG:Rect;
    public var moveDis:Rect;
    public var rod:Rect;
	
    var max:Float;
    var min:Float;

    public function new(X:Float, Y:Float, width:Float, height:Float, follow:Option) {
        super(X, Y);

        this.follow = follow;
        this.min = follow.minValue;
        this.max = follow.maxValue;
        innerX = X;
        innerY = Y;

        deleteButton = new FlxSprite();
        deleteButton.loadGraphic(createButton(height * 0.75, 0xFF6363, '-'));
        deleteButton.antialiasing = ClientPrefs.data.antialiasing;
        deleteButton.y += (height - deleteButton.height) / 2;
        add(deleteButton);

        addButton = new FlxSprite();
        addButton.loadGraphic(createButton(height * 0.75, 0x63FF75, '+'));
        addButton.antialiasing = ClientPrefs.data.antialiasing;
        addButton.x += width - addButton.width;
        addButton.y += (height - addButton.height) / 2;
        add(addButton);

        moveBG = new Rect(deleteButton.width * 1.2, 
                         0, 
                         width - (deleteButton.width + addButton.width) * 1.2, 
                         deleteButton.height * 0.5, 
                         deleteButton.height * 0.5 * 0.5, 
                         deleteButton.height * 0.5 * 0.5,
                         0xFF000000,
                         0.4
                         );
        moveBG.y += (height - moveBG.height) / 2;
        add(moveBG);

        moveDis = new Rect(deleteButton.width * 1.2, 
                         0, 
                         width - (deleteButton.width + addButton.width) * 1.2, 
                         deleteButton.height * 0.5, 
                         deleteButton.height * 0.5 * 0.5, 
                         deleteButton.height * 0.5 * 0.5,
                         EngineSet.mainColor,
                         1.0
                         );
        moveDis.y += (height - moveDis.height) / 2;
        add(moveDis);

        rod = new Rect(deleteButton.width * 1.2, 
                        0, 
                        height / 10, 
                        deleteButton.height, 
                        height / 10, 
                        height / 10, 
                        0xffffff,
                        1.0
                        );
        rod.y += (height - rod.height) / 2;
        add(rod);

        initData();
    }

    public function initData() {
        var percent = (follow.defaultValue - min) / (max - min);
        // 值可能刚被外部改过（例如 Option.resetData），去重缓存要跟着失效
        lastSentValue = Math.NaN;
        rectUpdate(percent);
    }

    public var onFocus:Bool = false;

    var focusAdd:Bool = false;
    var addHoldTime:Float = 0;

    var focusDelete:Bool = false;
    var deleteHoldTime:Float = 0;

    override function update(elapsed:Float)
	{
		super.update(elapsed);

        if (!follow.allowUpdate) return;

        if (OptionsState.instance.mouseEvent.overlaps(OptionsState.instance.specBG) || OptionsState.instance.mouseEvent.overlaps(OptionsState.instance.downBG)) return;

        var mouse = FlxG.mouse;

		// 点在轨道上就生效：落在滑块附近是"接着拖"，点在轨道别处是"直接跳到指针位置"。
		// 纵向判定带取滑块的高度而不是轨道本身的 —— 轨道只有几像素高，按不准。
		if (mouse.justPressed && isOnTrack(mouse.x, mouse.y))
		{
			onFocus = true;
			jumpToPointer(mouse.x);
			// 本帧后面紧跟的 onHold() 会按"指针 - lastMouseX"再跳一次，先对齐掉
			lastMouseX = mouse.x;
		}

        var inputAllow:Bool = true;

        if (Math.abs(OptionsState.instance.cataMove.velocity) > 2) inputAllow = false;

        if (inputAllow) {
            if (onFocus && mouse.pressed)
                onHold();

            if (mouse.justReleased)
            {
                onFocus = false;
            }

            if (mouse.overlaps(addButton))
            {
                if (mouse.justPressed) {  
                    changeData(true);
                    focusAdd = true;
                }

                if (mouse.pressed && focusAdd) {  
                    OptionsState.instance.cataMove.inputAllow = false;
                    if (addHoldTime > 0.3) {
                        addHoldTime -= 0.01;
                        changeData(true);
                    } else {
                        addHoldTime += elapsed;
                    }

                    if (addButton.scale.x > 0.8)
                        addButton.scale.x = addButton.scale.y -= ((addButton.scale.x - 0.8) * (addButton.scale.x - 0.8) * 0.75);
                } else {
                    addHoldTime = 0;
                    focusAdd = false;
                }
            } else {
                addHoldTime = 0;
                focusAdd = false;
            }

            if (mouse.overlaps(deleteButton))
            {
                if (mouse.justPressed) {  
                    changeData(false);
                    focusDelete = true;
                }

                if (mouse.pressed && focusDelete) {  
                    OptionsState.instance.cataMove.inputAllow = false;
                    if (deleteHoldTime > 0.3) {
                        deleteHoldTime -= 0.01;
                        changeData(false);
                    } else {
                        deleteHoldTime += elapsed;
                    }

                    if (deleteButton.scale.x > 0.8)
                        deleteButton.scale.x = deleteButton.scale.y -= ((deleteButton.scale.x - 0.8) * (deleteButton.scale.x - 0.8) * 0.75);
                } else {
                    deleteHoldTime = 0;
                    focusDelete = false;
                }
            } else {
                deleteHoldTime = 0;
                focusDelete = false;
            }
        }

        if (addButton.scale.x < 1 && !focusAdd)
            addButton.scale.x = addButton.scale.y += ((1 - addButton.scale.x) * (1 - addButton.scale.x) * 0.5);
        if (deleteButton.scale.x < 1 && !focusDelete)
            deleteButton.scale.x = deleteButton.scale.y += ((1 - deleteButton.scale.x) * (1 - deleteButton.scale.x) * 0.5);
	}

    var lastMouseX = 0;

    /**
     * 上一次真正写出去的值。
     * 拖动时 rectUpdate 每帧都会跑，但按 decimals 取整后大部分帧算出的值是同一个，
     * 不去重的话 setValue / onChange 会以帧率被重复触发（有的 onChange 是重活）。
     * 用 NaN 当"还没有写过"的哨兵 —— NaN 与任何值（包括自己）比较都不相等。
     */
    var lastSentValue:Float = Math.NaN;

    /** 把值直接跳到指针所在的轨道位置（点击跳转）。 */
    function jumpToPointer(pointerX:Float):Void
    {
        var usable:Float = moveBG.width - rod.width;
        if (usable <= 0) return;

        var percent:Float = FlxMath.bound((pointerX - moveBG.x) / usable, 0, 1);
        var outputData:Float = FlxMath.roundDecimal(min + (max - min) * percent, follow.decimals);
        rectUpdate(percent, outputData);
    }

    /** 指针是否落在轨道上。纵向用滑块的高度当判定带。 */
    function isOnTrack(pointerX:Float, pointerY:Float):Bool
    {
        if (pointerY < rod.y || pointerY > rod.y + rod.height) return false;
        return pointerX >= moveBG.x && pointerX <= moveBG.x + moveBG.width;
    }

    function onHold()
	{
        OptionsState.instance.cataMove.inputAllow = false;
        var deltaX:Float = FlxG.mouse.x - lastMouseX;
        lastMouseX = FlxG.mouse.x;
        if (deltaX == 0) return;

		rod.x += deltaX;

        var startX = follow.followX + follow.innerX + innerX + deleteButton.width * 1.2;
		if (rod.x < startX)
			rod.x = startX;
		if (rod.x + rod.width > startX + moveBG.width)
			rod.x = startX + moveBG.width - rod.width;

		var percent = (rod.x - moveBG.x) / (moveBG.width - rod.width);
        var outputData = FlxMath.roundDecimal(min + (max - min) * percent, follow.decimals);
        rectUpdate(percent, outputData);
	}

    function changeData(isAdd:Bool)
	{
		var outputData:Float = follow.getValue();
		if (isAdd)
			outputData += Math.pow(0.1, follow.decimals);
		else
			outputData -= Math.pow(0.1, follow.decimals);

		if (outputData < min)
			outputData = min;
		if (outputData > max)
			outputData = max;

		outputData = FlxMath.roundDecimal(outputData, follow.decimals);
		var percent = (outputData - min) / (max - min);

		rectUpdate(percent, outputData);
	}

    function rectUpdate(percent:Float, ?outputData)
	{
		moveDis._frame.frame.width = moveDis.width * percent;
		if (moveDis._frame.frame.width < 1)
			moveDis._frame.frame.width = 1;
		rod.x = follow.followX + follow.innerX + innerX + deleteButton.width * 1.2 + (moveBG.width - rod.width) * percent;

        if (outputData == null) return;

        var value:Float = cast outputData;
        if (value == lastSentValue) return;
        lastSentValue = value;

        follow.setValue(outputData);
		follow.change();
        follow.updateDisText();
	}
    
    private function createButton(size:Float, color:Int, symbol:String) {
        // 绘制按钮背景
        var button = new Shape();
        button.graphics.beginFill(color);
        button.graphics.drawRoundRect(0, 0, size, size, size / 4, size / 4);
        button.graphics.endFill();
        
        // 绘制符号
        button.graphics.lineStyle(3, 0xffffff); // 白色线条，3像素粗
        
        if (symbol == "+") {
            // 绘制加号：横线
            button.graphics.moveTo(size * 0.2, size * 0.5);
            button.graphics.lineTo(size * 0.8, size * 0.5);
            // 绘制加号：竖线
            button.graphics.moveTo(size * 0.5, size * 0.2);
            button.graphics.lineTo(size * 0.5, size * 0.8);
        } else if (symbol == "-") {
            // 绘制减号：横线
            button.graphics.moveTo(size * 0.2, size * 0.5);
            button.graphics.lineTo(size * 0.8, size * 0.5);
        }
        var bitmap:BitmapData = new BitmapData(Std.int(size), Std.int(size), true, 0);
		bitmap.draw(button);
		return bitmap;
    }
}