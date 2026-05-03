package developer.console;

import general.backend.ClientPrefs;
import openfl.display.Sprite;
import openfl.events.Event;
import openfl.events.MouseEvent;
import openfl.text.TextField;
import openfl.text.TextFormat;

class ConsoleToggleButton extends Sprite {
    public static var instance(get, null):ConsoleToggleButton;
    
    private static function get_instance():ConsoleToggleButton {
        if (_instance == null) {
            _instance = new ConsoleToggleButton();
        }
        return _instance;
    }
    private static var _instance:ConsoleToggleButton = null;
    
    public function new() {
        super();
        createButton();
        openfl.Lib.current.stage.addEventListener(Event.RESIZE, onResize);
    }
    
    private function createButton():Void {
        graphics.beginFill(0x4CAF50, 0.8);
        graphics.drawRoundRect(0, 0, 80, 30, 5);
        graphics.endFill();
        
        var label = new TextField();
        label.text = "显示控制台";
        label.setTextFormat(new TextFormat(Paths.font('Lang-ZH.ttf'), 12, 0xFFFFFF));
        label.x = 5;
        label.y = 5;
        label.width = 70;
        label.selectable = false;
        addChild(label);
        
        updatePosition();
        
        addEventListener(MouseEvent.CLICK, function(e) {
            Console.show();
            hide();
        });
    }
    
    private function updatePosition():Void {
        x = openfl.Lib.current.stage.stageWidth - 90;
        y = 20;
    }
    
    private function onResize(e:Event):Void {
        updatePosition();
    }
    
    public static function show():Void {
        if (!ClientPrefs.data.developerMode)
            return;
        instance.visible = true;
    }
    
    public static function hide():Void {
        instance.visible = false;
    }
}
