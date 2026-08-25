package psychlua.callbacks;

import backend.Paths;
import play.PlayState;
import psychlua.FunkinLua;
import psychlua.LuaUtils;
#if DISCORD_ALLOWED
import backend.DiscordClient;
#end

// REFACTOR: extracted from psychlua.FunkinLua (random/debug/print/cursor/string utils)
class MiscCallbacks
{
	public static function register(funk:FunkinLua):Void {
		@:privateAccess {
		FunkinLua.registerFunction("getRandomInt", function(min:Int, max:Int = FlxMath.MAX_VALUE_INT, exclude:String = '') {
			var excludeArray:Array<String> = exclude.split(',');
			var toExclude:Array<Int> = [];
			for (i in 0...excludeArray.length)
			{
				toExclude.push(Std.parseInt(excludeArray[i].trim()));
			}
			return FlxG.random.int(min, max, toExclude);
		});
		FunkinLua.registerFunction("getRandomFloat", function(min:Float, max:Float = 1, exclude:String = '') {
			var excludeArray:Array<String> = exclude.split(',');
			var toExclude:Array<Float> = [];
			for (i in 0...excludeArray.length)
			{
				toExclude.push(Std.parseFloat(excludeArray[i].trim()));
			}
			return FlxG.random.float(min, max, toExclude);
		});
		FunkinLua.registerFunction("getRandomBool", function(chance:Float = 50) {
			return FlxG.random.bool(chance);
		});
		FunkinLua.registerFunction("debugPrint", function(text1:Dynamic = '', text2:Dynamic = '', text3:Dynamic = '', text4:Dynamic = '', text5:Dynamic = '') {
			if (text1 == null) text1 = '';
			if (text2 == null) text2 = '';
			if (text3 == null) text3 = '';
			if (text4 == null) text4 = '';
			if (text5 == null) text5 = '';
			LuaUtils.luaTrace(funk.lua, '' + text1 + text2 + text3 + text4 + text5, true, false);
		});

		addLocalCallback("close", function() {
			funk.closed = true;
			return funk.closed;
		});
		FunkinLua.registerFunction("changePresence", function(details:String, state:Null<String>, ?smallImageKey:String, ?hasStartTimestamp:Bool, ?endTimestamp:Float) {
			#if DISCORD_ALLOWED
			DiscordClient.changePresence(details, state, smallImageKey, hasStartTimestamp, endTimestamp);
			#end
		});
		// Other stuff
		FunkinLua.registerFunction("stringStartsWith", function(str:String, start:String) {
			return str.startsWith(start);
		});
		FunkinLua.registerFunction("stringEndsWith", function(str:String, end:String) {
			return str.endsWith(end);
		});
		FunkinLua.registerFunction("stringSplit", function(str:String, split:String) {
			return str.split(split);
		});
		FunkinLua.registerFunction("stringTrim", function(str:String) {
			return str.trim();
		});
		FunkinLua.registerFunction("changeCursor", function(path:String, visible:Bool = true, ?loadDefault:Bool = false, scale:Float = 1, xOffset:Int = 0, yOffset:Int = 0) {
			if (Paths.image(path) != null){
				FlxG.mouse.visible = visible;
				FlxG.mouse.unload();
				FlxG.mouse.load(Paths.image(path).bitmap, scale, xOffset, yOffset);
				LuaUtils.luaTrace(funk.lua, 'Changed Cursor in $path');
			}
			else if (loadDefault || path == null || path.length <= 0)
			{
				FlxG.mouse.unload();
				FlxG.mouse.visible = visible;
				LuaUtils.luaTrace(funk.lua, 'Loading default cursor');
			}
			else
			{
				LuaUtils.luaTrace(funk.lua, 'Cursor in $path does not exist!', true, false, FlxColor.RED);
				FlxG.mouse.unload();
				FlxG.mouse.visible = visible;
				// return;
			}
		});
		}
	}
}
