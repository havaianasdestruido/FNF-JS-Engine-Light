package psychlua.pystdlib;

import psychlua.PythonScript;
import psychlua.LuaUtils;
import Type.ValueType;

// REFACTOR: extracted from psychlua.PythonScript (getProperty / setProperty family)
class PyPropertyLib
{
	public static function register(py:PythonScript):Void {
		@:privateAccess {
		PythonScript.registerFunction("getProperty", function(variable:String) {
			var result:Dynamic = null;
			var killMe:Array<String> = variable.split('.');
			if(killMe.length > 1)
				result = FunkinLua.getVarInArray(FunkinLua.getPropertyLoopThingWhatever(killMe), killMe[killMe.length-1]);
			else
				result = FunkinLua.getVarInArray(py.getInstance(), variable);
			return result;
		});
		PythonScript.registerFunction("setProperty", function(variable:String, value:Dynamic) {
			var killMe:Array<String> = variable.split('.');
			if(killMe.length > 1) {
				FunkinLua.setVarInArray(FunkinLua.getPropertyLoopThingWhatever(killMe), killMe[killMe.length-1], value);
				return true;
			}
			FunkinLua.setVarInArray(py.getInstance(), variable, value);
			return true;
		});
		PythonScript.registerFunction("getPropertyFromGroup", function(obj:String, index:Int, variable:Dynamic) {
			var shitMyPants:Array<String> = obj.split('.');
			var realObject:Dynamic = Reflect.getProperty(py.getInstance(), obj);
			if(shitMyPants.length>1)
				realObject = FunkinLua.getPropertyLoopThingWhatever(shitMyPants, true, false);

			if(Std.isOfType(realObject, FlxTypedGroup)) {
				var result:Dynamic = py.getGroupStuff(realObject.members[index], variable);
				return result;
			}

			var leArray:Dynamic = realObject[index];
			if(leArray != null) {
				var result:Dynamic = null;
				if(Type.typeof(variable) == ValueType.TInt)
					result = leArray[variable];
				else
					result = py.getGroupStuff(leArray, variable);
				return result;
			}
			py.pyTrace("getPropertyFromGroup | Object #" + index + " from group: " + obj + " doesn't exist!", false, false, FlxColor.RED);
			return null;
		});
		PythonScript.registerFunction("setPropertyFromGroup", function(obj:String, index:Int, variable:Dynamic, value:Dynamic) {
			var shitMyPants:Array<String> = obj.split('.');
			var realObject:Dynamic = Reflect.getProperty(py.getInstance(), obj);
			if(shitMyPants.length>1)
				realObject = FunkinLua.getPropertyLoopThingWhatever(shitMyPants, true, false);

			if(Std.isOfType(realObject, FlxTypedGroup)) {
				py.setGroupStuff(realObject.members[index], variable, value);
				return;
			}

			var leArray:Dynamic = realObject[index];
			if(leArray != null) {
				if(Type.typeof(variable) == ValueType.TInt) {
					leArray[variable] = value;
					return;
				}
				py.setGroupStuff(leArray, variable, value);
			}
		});
		PythonScript.registerFunction("removeFromGroup", function(obj:String, index:Int, dontDestroy:Bool = false) {
			if(Std.isOfType(Reflect.getProperty(py.getInstance(), obj), FlxTypedGroup)) {
				var sex = Reflect.getProperty(py.getInstance(), obj).members[index];
				if(!dontDestroy)
					sex.kill();
				Reflect.getProperty(py.getInstance(), obj).remove(sex, true);
				if(!dontDestroy)
					sex.destroy();
				return;
			}
			Reflect.getProperty(py.getInstance(), obj).remove(Reflect.getProperty(py.getInstance(), obj)[index]);
		});
		PythonScript.registerFunction("getPropertyFromClass", function(classVar:String, variable:String) {
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
		PythonScript.registerFunction("setPropertyFromClass", function(classVar:String, variable:String, value:Dynamic) {
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
		PythonScript.registerFunction("getObjectOrder", function(obj:String) {
			var killMe:Array<String> = obj.split('.');
			var leObj:FlxBasic = FunkinLua.getObjectDirectly(killMe[0]);
			if(killMe.length > 1) {
				leObj = FunkinLua.getVarInArray(FunkinLua.getPropertyLoopThingWhatever(killMe), killMe[killMe.length-1]);
			}

			if(leObj != null) {
				return py.getInstance().members.indexOf(leObj);
			}
			py.pyTrace("getObjectOrder | Object " + obj + " doesn't exist!", false, false, FlxColor.RED);
			return -1;
		});
		PythonScript.registerFunction("setObjectOrder", function(obj:String, position:Int) {
			var killMe:Array<String> = obj.split('.');
			var leObj:FlxBasic = FunkinLua.getObjectDirectly(killMe[0]);
			if(killMe.length > 1) {
				leObj = FunkinLua.getVarInArray(FunkinLua.getPropertyLoopThingWhatever(killMe), killMe[killMe.length-1]);
			}

			if(leObj != null) {
				py.getInstance().remove(leObj, true);
				py.getInstance().insert(position, leObj);
				return;
			}
			py.pyTrace("setObjectOrder | Object " + obj + " doesn't exist!", false, false, FlxColor.RED);
		});
		}
	}
}

