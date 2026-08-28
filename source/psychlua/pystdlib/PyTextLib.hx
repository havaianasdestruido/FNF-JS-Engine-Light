package psychlua.pystdlib;

// REFACTOR: restored imports
import flixel.text.FlxText;
import flixel.util.FlxColor;
import psychlua.PythonScript;
import play.PlayState;
import backend.Paths;
import psychlua.LuaUtils;

// REFACTOR: extracted from psychlua.PythonScript (text object API)
class PyTextLib
{
	public static function register(py:PythonScript):Void {
		@:privateAccess {
		// Lua texts
		PythonScript.registerFunction("makeLuaText", function(tag:String, text:String, width:Int, x:Float, y:Float) {
			tag = tag.replace('.', '');
			py.resetTextTag(tag);
			var leText:FlxText = new FlxText(x, y, width, text, 16);
			leText.setFormat(Paths.font("vcr.ttf"), 16, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
			leText.cameras = [PlayState.instance.camHUD];
			PlayState.instance.modchartTexts.set(tag, leText);
		});
		PythonScript.registerFunction("setTextString", function(tag:String, text:String) {
			var obj:FlxText = py.getTextObject(tag);
			if(obj != null) {
				obj.text = text;
			}
		});
		PythonScript.registerFunction("setTextSize", function(tag:String, size:Int) {
			var obj:FlxText = py.getTextObject(tag);
			if(obj != null) {
				obj.size = size;
			}
		});
		PythonScript.registerFunction("setTextColor", function(tag:String, color:String) {
			var obj:FlxText = py.getTextObject(tag);
			if(obj != null) {
				var colorNum:Int = Std.parseInt(color);
				if(!color.startsWith('0x')) colorNum = Std.parseInt('0xff' + color);
				obj.color = colorNum;
			}
		});
		PythonScript.registerFunction("setTextFont", function(tag:String, newFont:String) {
			var obj:FlxText = py.getTextObject(tag);
			if(obj != null) {
				obj.font = Paths.font(newFont);
			}
		});
		PythonScript.registerFunction("setTextAlignment", function(tag:String, alignment:String = 'left') {
			var obj:FlxText = py.getTextObject(tag);
			if(obj != null) {
				switch(alignment.toLowerCase().trim()) {
					case 'right': obj.alignment = RIGHT;
					case 'center': obj.alignment = CENTER;
					default: obj.alignment = LEFT;
				}
			}
		});
		PythonScript.registerFunction("getTextString", function(tag:String) {
			var obj:FlxText = py.getTextObject(tag);
			if(obj != null) {
				return obj.text;
			}
			return null;
		});
		PythonScript.registerFunction("setTextBorder", function(tag:String, size:Int, color:String, ?quality:String = 'quality') {
			var obj:FlxText = py.getTextObject(tag);
			if(obj != null) {
				var colorNum:Int = Std.parseInt(color);
				if(!color.startsWith('0x')) colorNum = Std.parseInt('0xff' + color);
				obj.borderStyle = OUTLINE;
				obj.borderSize = size;
				obj.borderColor = colorNum;
			}
		});
		}
	}
}
