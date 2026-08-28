package psychlua.callbacks;

import flixel.FlxBasic;
import backend.Paths;
import play.PlayState;
import psychlua.FunkinLua;
import psychlua.LuaUtils;
import Type.ValueType;

// REFACTOR: extracted from psychlua.FunkinLua (getProperty / setProperty family)
class PropertyCallbacks
{
	public static function register(funk:FunkinLua):Void {
		@:privateAccess {
		FunkinLua.registerFunction("loadGraphic", function(variable:String, image:String, ?gridX:Int = 0, ?gridY:Int = 0) {
			var killMe:Array<String> = variable.split('.');
			var spr:FlxSprite = FunkinLua.getObjectDirectly(killMe[0]);
			var animated = gridX != 0 || gridY != 0;

			if(killMe.length > 1) {
				spr = FunkinLua.getVarInArray(FunkinLua.getPropertyLoopThingWhatever(killMe), killMe[killMe.length-1]);
			}

			if(spr != null && image != null && image.length > 0)
			{
				spr.loadGraphic(Paths.image(image), animated, gridX, gridY);
			}
		});
		FunkinLua.registerFunction("loadFrames", function(variable:String, image:String, spriteType:String = "sparrow") {
			var killMe:Array<String> = variable.split('.');
			var spr:FlxSprite = FunkinLua.getObjectDirectly(killMe[0]);
			if(killMe.length > 1) {
				spr = FunkinLua.getVarInArray(FunkinLua.getPropertyLoopThingWhatever(killMe), killMe[killMe.length-1]);
			}

			if(spr != null && image != null && image.length > 0)
			{
				funk.loadFrames(spr, image, spriteType);
			}
		});

		FunkinLua.registerFunction("getProperty", function(variable:String) {
			var result:Dynamic = null;
			var killMe:Array<String> = variable.split('.');
			if(killMe.length > 1)
				result = FunkinLua.getVarInArray(FunkinLua.getPropertyLoopThingWhatever(killMe), killMe[killMe.length-1]);
			else
				result = FunkinLua.getVarInArray(FunkinLua.getInstance(), variable);
			return result;
		});
		FunkinLua.registerFunction("setProperty", function(variable:String, value:Dynamic) {
			var killMe:Array<String> = variable.split('.');
			if(killMe.length > 1) {
				FunkinLua.setVarInArray(FunkinLua.getPropertyLoopThingWhatever(killMe), killMe[killMe.length-1], value);
				return true;
			}
			FunkinLua.setVarInArray(FunkinLua.getInstance(), variable, value);
			return true;
		});
		FunkinLua.registerFunction("getPropertyFromGroup", function(obj:String, index:Int, variable:Dynamic) {
			var shitMyPants:Array<String> = obj.split('.');
			var realObject:Dynamic = Reflect.getProperty(FunkinLua.getInstance(), obj);
			if(shitMyPants.length>1)
				realObject = FunkinLua.getPropertyLoopThingWhatever(shitMyPants, true, false);

			if(Std.isOfType(realObject, FlxTypedGroup))
			{
				var result:Dynamic = funk.getGroupStuff(realObject.members[index], variable);
				return result;
			}


			var leArray:Dynamic = realObject[index];
			if(leArray != null) {
				var result:Dynamic = null;
				if(Type.typeof(variable) == ValueType.TInt)
					result = leArray[variable];
				else
					result = funk.getGroupStuff(leArray, variable);
				return result;
			}
			LuaUtils.luaTrace(funk.lua, "getPropertyFromGroup | Object #" + index + " from group: " + obj + " doesn't exist!", false, false, FlxColor.RED);
			return null;
		});
		FunkinLua.registerFunction("setPropertyFromGroup", function(obj:String, index:Int, variable:Dynamic, value:Dynamic) {
			var shitMyPants:Array<String> = obj.split('.');
			var realObject:Dynamic = Reflect.getProperty(FunkinLua.getInstance(), obj);
			if(shitMyPants.length>1)
				realObject = FunkinLua.getPropertyLoopThingWhatever(shitMyPants, true, false);

			if(Std.isOfType(realObject, FlxTypedGroup)) {
				funk.setGroupStuff(realObject.members[index], variable, value);
				return;
			}

			var leArray:Dynamic = realObject[index];
			if(leArray != null) {
				if(Type.typeof(variable) == ValueType.TInt) {
					leArray[variable] = value;
					return;
				}
				funk.setGroupStuff(leArray, variable, value);
			}
		});
		FunkinLua.registerFunction("removeFromGroup", function(obj:String, index:Int, dontDestroy:Bool = false) {
			if(Std.isOfType(Reflect.getProperty(FunkinLua.getInstance(), obj), FlxTypedGroup)) {
				var sex = Reflect.getProperty(FunkinLua.getInstance(), obj).members[index];
				if(!dontDestroy)
					sex.kill();
				Reflect.getProperty(FunkinLua.getInstance(), obj).remove(sex, true);
				if(!dontDestroy)
					sex.destroy();
				return;
			}
			Reflect.getProperty(FunkinLua.getInstance(), obj).remove(Reflect.getProperty(FunkinLua.getInstance(), obj)[index]);
		});

		FunkinLua.registerFunction("getPropertyFromClass", function(classVar:String, variable:String) {
			@:privateAccess
			var killMe:Array<String> = variable.split('.');
			if(killMe.length > 1) {
				var coverMeInPiss:Dynamic = FunkinLua.getVarInArray(LuaUtils.resolveClassCompat(classVar), killMe[0]);
				for (i in 1...killMe.length-1) {
					coverMeInPiss = FunkinLua.getVarInArray(coverMeInPiss, killMe[i]);
				}
				return FunkinLua.getVarInArray(coverMeInPiss, killMe[killMe.length-1]);
			}
			return FunkinLua.getVarInArray(LuaUtils.resolveClassCompat(classVar), variable);
		});
		FunkinLua.registerFunction("setPropertyFromClass", function(classVar:String, variable:String, value:Dynamic) {
			@:privateAccess
			var killMe:Array<String> = variable.split('.');
			if(killMe.length > 1) {
				var coverMeInPiss:Dynamic = FunkinLua.getVarInArray(LuaUtils.resolveClassCompat(classVar), killMe[0]);
				for (i in 1...killMe.length-1) {
					coverMeInPiss = FunkinLua.getVarInArray(coverMeInPiss, killMe[i]);
				}
				FunkinLua.setVarInArray(coverMeInPiss, killMe[killMe.length-1], value);
				return true;
			}
			FunkinLua.setVarInArray(LuaUtils.resolveClassCompat(classVar), variable, value);
			return true;
		});

		//shitass stuff for epic coders like me B)  *image of obama giving himself a medal*
		FunkinLua.registerFunction("getObjectOrder", function(obj:String) {
			var killMe:Array<String> = obj.split('.');
			var leObj:FlxBasic = FunkinLua.getObjectDirectly(killMe[0]);
			if(killMe.length > 1) {
				leObj = FunkinLua.getVarInArray(FunkinLua.getPropertyLoopThingWhatever(killMe), killMe[killMe.length-1]);
			}

			if(leObj != null)
			{
				return FunkinLua.getInstance().members.indexOf(leObj);
			}
			LuaUtils.luaTrace(funk.lua, "getObjectOrder | Object " + obj + " doesn't exist!", false, false, FlxColor.RED);
			return -1;
		});
		FunkinLua.registerFunction("setObjectOrder", function(obj:String, position:Int) {
			var killMe:Array<String> = obj.split('.');
			var leObj:FlxBasic = FunkinLua.getObjectDirectly(killMe[0]);
			if(killMe.length > 1) {
				leObj = FunkinLua.getVarInArray(FunkinLua.getPropertyLoopThingWhatever(killMe), killMe[killMe.length-1]);
			}

			if(leObj != null) {
				FunkinLua.getInstance().remove(leObj, true);
				FunkinLua.getInstance().insert(position, leObj);
				return;
			}
			LuaUtils.luaTrace(funk.lua, "setObjectOrder | Object " + obj + " doesn't exist!", false, false, FlxColor.RED);
		});
		}
	}
}

