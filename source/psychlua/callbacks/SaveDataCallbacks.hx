package psychlua.callbacks;

import backend.CoolUtil;
import play.PlayState;
import psychlua.FunkinLua;
import headers.PsychLua;

// REFACTOR: extracted from psychlua.FunkinLua (save data API)
class SaveDataCallbacks
{
	public static function register(funk:FunkinLua):Void {
		@:privateAccess {
		FunkinLua.registerFunction("initSaveData", function(name:String, ?folder:String = 'psychenginemods') {
			if(!PlayState.instance.modchartSaves.exists(name))
			{
				var save:FlxSave = new FlxSave();
				// folder goes unused for flixel 5 users. @BeastlyGhost
				save.bind(name, CoolUtil.getSavePath() + "/" + folder);
				PlayState.instance.modchartSaves.set(name, save);
				return;
			}
			LuaUtils.luaTrace(funk.lua, 'initSaveData | Save file already initialized: ' + name);
		});
		FunkinLua.registerFunction("flushSaveData", function(name:String) {
			if(PlayState.instance.modchartSaves.exists(name))
			{
				PlayState.instance.modchartSaves.get(name).flush();
				return;
			}
			LuaUtils.luaTrace(funk.lua, 'flushSaveData | Save file not initialized: ' + name, false, false, FlxColor.RED);
		});
		FunkinLua.registerFunction("getDataFromSave", function(name:String, field:String, ?defaultValue:Dynamic = null) {
			if(PlayState.instance.modchartSaves.exists(name))
			{
				var retVal:Dynamic = Reflect.field(PlayState.instance.modchartSaves.get(name).data, field);
				return retVal;
			}
			LuaUtils.luaTrace(funk.lua, 'getDataFromSave | Save file not initialized: ' + name, false, false, FlxColor.RED);
			return defaultValue;
		});
		FunkinLua.registerFunction("setDataFromSave", function(name:String, field:String, value:Dynamic) {
			if(PlayState.instance.modchartSaves.exists(name))
			{
				Reflect.setField(PlayState.instance.modchartSaves.get(name).data, field, value);
				return;
			}
			LuaUtils.luaTrace(funk.lua, 'setDataFromSave | Save file not initialized: ' + name, false, false, FlxColor.RED);
		});
		}
	}
}
