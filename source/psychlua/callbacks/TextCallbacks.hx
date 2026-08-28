package psychlua.callbacks;

import backend.Paths;
import play.PlayState;
import psychlua.FunkinLua;
import headers.PsychLua;

// REFACTOR: extracted from psychlua.FunkinLua (text object API)
class TextCallbacks
{
	public static function register(funk:FunkinLua):Void {
		@:privateAccess {
		// LUA TEXTS
		FunkinLua.registerFunction("makeLuaText", function(tag:String, text:String, width:Int, x:Float, y:Float) {
			tag = tag.replace('.', '');
			funk.resetTextTag(tag);
			var leText:FlxText = new FlxText(x, y, width, text, 16);
			leText.setFormat(Paths.font("vcr.ttf"), 16, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
			leText.cameras = [PlayState.instance.camHUD];
			PlayState.instance.modchartTexts.set(tag, leText);
		});

		FunkinLua.registerFunction("setTextString", function(tag:String, text:String) {
			var obj:FlxText = FunkinLua.getTextObject(tag);
			if(obj != null)
			{
				obj.text = text;
				return true;
			}
			LuaUtils.luaTrace(funk.lua, "setTextString | Object " + tag + " doesn't exist!", false, false, FlxColor.RED);
			return false;
		});
		FunkinLua.registerFunction("setTextSize", function(tag:String, size:Int) {
			var obj:FlxText = FunkinLua.getTextObject(tag);
			if(obj != null)
			{
				obj.size = size;
				return true;
			}
			LuaUtils.luaTrace(funk.lua, "setTextSize | Object " + tag + " doesn't exist!", false, false, FlxColor.RED);
			return false;
		});
		FunkinLua.registerFunction("setTextWidth", function(tag:String, width:Float) {
			var obj:FlxText = FunkinLua.getTextObject(tag);
			if(obj != null)
			{
				obj.fieldWidth = width;
				return true;
			}
			LuaUtils.luaTrace(funk.lua, "setTextWidth | Object " + tag + " doesn't exist!", false, false, FlxColor.RED);
			return false;
		});
		FunkinLua.registerFunction("setTextBorder", function(tag:String, size:Int, color:String) {
			var obj:FlxText = FunkinLua.getTextObject(tag);
			if(obj != null)
			{
				var colorNum:Int = Std.parseInt(color);
				if(!color.startsWith('0x')) colorNum = Std.parseInt('0xff' + color);

				obj.borderSize = size;
				obj.borderColor = colorNum;
				return true;
			}
			LuaUtils.luaTrace(funk.lua, "setTextBorder | Object " + tag + " doesn't exist!", false, false, FlxColor.RED);
			return false;
		});
		FunkinLua.registerFunction("setTextColor", function(tag:String, color:String) {
			var obj:FlxText = FunkinLua.getTextObject(tag);
			if(obj != null)
			{
				var colorNum:Int = Std.parseInt(color);
				if(!color.startsWith('0x')) colorNum = Std.parseInt('0xff' + color);

				obj.color = colorNum;
				return true;
			}
			LuaUtils.luaTrace(funk.lua, "setTextColor | Object " + tag + " doesn't exist!", false, false, FlxColor.RED);
			return false;
		});
		FunkinLua.registerFunction("setTextFont", function(tag:String, newFont:String) {
			var obj:FlxText = FunkinLua.getTextObject(tag);
			if(obj != null)
			{
				obj.font = Paths.font(newFont);
				return true;
			}
			LuaUtils.luaTrace(funk.lua, "setTextFont | Object " + tag + " doesn't exist!", false, false, FlxColor.RED);
			return false;
		});
		FunkinLua.registerFunction("setTextItalic", function(tag:String, italic:Bool) {
			var obj:FlxText = FunkinLua.getTextObject(tag);
			if(obj != null)
			{
				obj.italic = italic;
				return true;
			}
			LuaUtils.luaTrace(funk.lua, "setTextItalic | Object " + tag + " doesn't exist!", false, false, FlxColor.RED);
			return false;
		});
		FunkinLua.registerFunction("setTextAlignment", function(tag:String, alignment:String = 'left') {
			var obj:FlxText = FunkinLua.getTextObject(tag);
			if(obj != null)
			{
				obj.alignment = LEFT;
				switch(alignment.trim().toLowerCase())
				{
					case 'right':
						obj.alignment = RIGHT;
					case 'center':
						obj.alignment = CENTER;
				}
				return true;
			}
			LuaUtils.luaTrace(funk.lua, "setTextAlignment | Object " + tag + " doesn't exist!", false, false, FlxColor.RED);
			return false;
		});

		FunkinLua.registerFunction("getTextString", function(tag:String) {
			var obj:FlxText = FunkinLua.getTextObject(tag);
			if(obj != null && obj.text != null)
			{
				return obj.text;
			}
			LuaUtils.luaTrace(funk.lua, "getTextString | Object " + tag + " doesn't exist!", false, false, FlxColor.RED);
			return null;
		});
		FunkinLua.registerFunction("getTextSize", function(tag:String) {
			var obj:FlxText = FunkinLua.getTextObject(tag);
			if(obj != null)
			{
				return obj.size;
			}
			LuaUtils.luaTrace(funk.lua, "getTextSize | Object " + tag + " doesn't exist!", false, false, FlxColor.RED);
			return -1;
		});
		FunkinLua.registerFunction("getTextFont", function(tag:String) {
			var obj:FlxText = FunkinLua.getTextObject(tag);
			if(obj != null)
			{
				return obj.font;
			}
			LuaUtils.luaTrace(funk.lua, "getTextFont | Object " + tag + " doesn't exist!", false, false, FlxColor.RED);
			return null;
		});
		FunkinLua.registerFunction("getTextWidth", function(tag:String) {
			var obj:FlxText = FunkinLua.getTextObject(tag);
			if(obj != null)
			{
				return obj.fieldWidth;
			}
			LuaUtils.luaTrace(funk.lua, "getTextWidth | Object " + tag + " doesn't exist!", false, false, FlxColor.RED);
			return 0;
		});

		FunkinLua.registerFunction("addLuaText", function(tag:String) {
			if(PlayState.instance.modchartTexts.exists(tag)) {
				var shit:FlxText = PlayState.instance.modchartTexts.get(tag);
				if(shit != null) FunkinLua.getInstance().add(shit);
			}
		});
		FunkinLua.registerFunction("removeLuaText", function(tag:String, destroy:Bool = true) {
			if(!PlayState.instance.modchartTexts.exists(tag)) {
				return;
			}

			var pee:FlxText = PlayState.instance.modchartTexts.get(tag);

			if(pee != null)
				FunkinLua.getInstance().remove(pee, true);

			if(destroy) {
				pee.destroy();
				PlayState.instance.modchartTexts.remove(tag);
			}
		});
		}
	}
}
