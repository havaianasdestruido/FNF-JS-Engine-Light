package psychlua.callbacks;

import shaders.ErrorHandledShader.ErrorHandledRuntimeShader;

import backend.ClientPrefs;
import backend.Paths;
import play.PlayState;
import psychlua.FunkinLua;
import psychlua.LuaUtils;

#if SHADERS_ALLOWED
import flixel.addons.display.FlxRuntimeShader;
import openfl.filters.ShaderFilter;
#end

// REFACTOR: extracted from psychlua.FunkinLua (initLuaShader / sprite and camera runtime shader API)
class ShaderCallbacks
{
	public static function register(funk:FunkinLua):Void {
		final game:PlayState = PlayState.instance;
		@:privateAccess {
		FunkinLua.registerFunction("initLuaShader", function(name:String, glslVersion:Int = 120) {
			if(!ClientPrefs.shaders) return false;

			#if (MODS_ALLOWED && SHADERS_ALLOWED)
			return funk.initLuaShader(name, glslVersion);
			#else
			LuaUtils.luaTrace(funk.lua, "initLuaShader | Platform unsupported for Runtime Shaders!", false, false, FlxColor.RED);
			#end
			return false;
		});

		FunkinLua.registerFunction("setSpriteShader", function(obj:String, shader:String) {
			if(!ClientPrefs.shaders) return false;

			#if (MODS_ALLOWED && SHADERS_ALLOWED)
			if(!game.runtimeShaders.exists(shader) && !funk.initLuaShader(shader))
			{
				LuaUtils.luaTrace(funk.lua, 'setSpriteShader | Shader $shader is missing! Make sure you\'ve initalized your shader first!', false, false, FlxColor.RED);
				return false;
			}

			var killMe:Array<String> = obj.split('.');
			var leObj:FlxSprite = FunkinLua.getObjectDirectly(killMe[0]);
			if(killMe.length > 1) {
				leObj = FunkinLua.getVarInArray(FunkinLua.getPropertyLoopThingWhatever(killMe), killMe[killMe.length-1]);
			}

			if(leObj != null) {
				var arr:Array<String> = game.runtimeShaders.get(shader);
				leObj.shader = new ErrorHandledRuntimeShader(shader, arr[0], arr[1]);
				return true;
			}
			#else
			LuaUtils.luaTrace(funk.lua, "setSpriteShader | Platform unsupported for Runtime Shaders!", false, false, FlxColor.RED);
			#end
			return false;
		});
		FunkinLua.registerFunction("removeSpriteShader", function(obj:String) {
			var killMe:Array<String> = obj.split('.');
			var leObj:FlxSprite = FunkinLua.getObjectDirectly(killMe[0]);
			if(killMe.length > 1) {
				leObj = FunkinLua.getVarInArray(FunkinLua.getPropertyLoopThingWhatever(killMe), killMe[killMe.length-1]);
			}

			if(leObj != null) {
				leObj.shader = null;
				return true;
			}
			return false;
		});

		// camera shaders
		FunkinLua.registerFunction("setCameraShader", function(cam:String, shader:String, ?index:String) {
			if (!ClientPrefs.shaders) return false;

			if (index == null || index.length < 1)
			    index = shader;

			#if (MODS_ALLOWED && SHADERS_ALLOWED)
			if (!game.runtimeShaders.exists(shader) && !game.initLuaShader(shader)) {
			    LuaUtils.luaTrace(funk.lua, 'addShaderToCam | Shader $shader is missing! Make sure you\'ve initalized your shader first!', false, false, FlxColor.RED);
			    return false;
			}

            var arr:Array<String> = game.runtimeShaders.get(shader);
            var camera = LuaUtils.getCam(cam);
            @:privateAccess {
            if (camera.filters == null)
                camera.filters = [];
				final filter = new ShaderFilter(new ErrorHandledRuntimeShader(shader, arr[0], arr[1]));
				FunkinLua.storedFilters.set(index, filter);
				camera.filters.push(filter);
            }
            return true;
			#else
            LuaUtils.luaTrace(funk.lua, "addShaderToCam | Platform unsupported for Runtime Shaders!", false, false, FlxColor.RED);
			#end
			return false;
		});

		FunkinLua.registerFunction("removeCameraShader", function(cam:String, shader:String) {
			#if (MODS_ALLOWED && SHADERS_ALLOWED)
			if (!ClientPrefs.shaders) return false;
			final camera = LuaUtils.getCam(cam);
			@:privateAccess {
			if(!FunkinLua.storedFilters.exists(shader)) {
				LuaUtils.luaTrace(funk.lua, 'removeCamShader | $shader does not exist!', false, false, FlxColor.YELLOW);
				return false;
			}

			if (camera.filters == null) {
				LuaUtils.luaTrace(funk.lua, 'removeCamShader | camera $cam does not have any shaders!', false, false, FlxColor.YELLOW);
				return false;
			}

			camera.filters.remove(FunkinLua.storedFilters.get(shader));
			FunkinLua.storedFilters.remove(shader);
			return true;
			}
			#else
			LuaUtils.luaTrace(funk.lua, 'removeCamShader | Platform unsupported for Runtime Shaders!', false, false, FlxColor.RED);
			#end
			return false;
		});

		FunkinLua.registerFunction("getShaderBool", function(obj:String, prop:String) {
			#if (MODS_ALLOWED && SHADERS_ALLOWED)
			var shader:FlxRuntimeShader = funk.getShader(obj);
			if (shader == null || !ClientPrefs.shaders)
			{
				return null;
			}
			return shader.getBool(prop);
			#else
			LuaUtils.luaTrace(funk.lua, "getShaderBool | Platform unsupported for Runtime Shaders!", false, false, FlxColor.RED);
			return null;
			#end
		});
		FunkinLua.registerFunction("getShaderBoolArray", function(obj:String, prop:String) {
			#if (MODS_ALLOWED && SHADERS_ALLOWED)
			var shader:FlxRuntimeShader = funk.getShader(obj);
			if (shader == null || !ClientPrefs.shaders)
			{
				return null;
			}
			return shader.getBoolArray(prop);
			#else
			LuaUtils.luaTrace(funk.lua, "getShaderBoolArray | Platform unsupported for Runtime Shaders!", false, false, FlxColor.RED);
			return null;
			#end
		});
		FunkinLua.registerFunction("getShaderInt", function(obj:String, prop:String) {
			#if (MODS_ALLOWED && SHADERS_ALLOWED)
			var shader:FlxRuntimeShader = funk.getShader(obj);
			if (shader == null || !ClientPrefs.shaders)
			{
				return null;
			}
			return shader.getInt(prop);
			#else
			LuaUtils.luaTrace(funk.lua, "getShaderInt | Platform unsupported for Runtime Shaders!", false, false, FlxColor.RED);
			return null;
			#end
		});
		FunkinLua.registerFunction("getShaderIntArray", function(obj:String, prop:String) {
			#if (MODS_ALLOWED && SHADERS_ALLOWED)
			var shader:FlxRuntimeShader = funk.getShader(obj);
			if (shader == null || !ClientPrefs.shaders)
			{
				return null;
			}
			return shader.getIntArray(prop);
			#else
			LuaUtils.luaTrace(funk.lua, "getShaderIntArray | Platform unsupported for Runtime Shaders!", false, false, FlxColor.RED);
			return null;
			#end
		});
		FunkinLua.registerFunction("getShaderFloat", function(obj:String, prop:String) {
			#if (MODS_ALLOWED && SHADERS_ALLOWED)
			var shader:FlxRuntimeShader = funk.getShader(obj);
			if (shader == null || !ClientPrefs.shaders)
			{
				return null;
			}
			return shader.getFloat(prop);
			#else
			LuaUtils.luaTrace(funk.lua, "getShaderFloat | Platform unsupported for Runtime Shaders!", false, false, FlxColor.RED);
			return null;
			#end
		});
		FunkinLua.registerFunction("getShaderFloatArray", function(obj:String, prop:String) {
			#if (MODS_ALLOWED && SHADERS_ALLOWED)
			var shader:FlxRuntimeShader = funk.getShader(obj);
			if (shader == null || !ClientPrefs.shaders)
			{
				return null;
			}
			return shader.getFloatArray(prop);
			#else
			LuaUtils.luaTrace(funk.lua, "getShaderFloatArray | Platform unsupported for Runtime Shaders!", false, false, FlxColor.RED);
			return null;
			#end
		});

		FunkinLua.registerFunction("setShaderBool", function(obj:String, prop:String, value:Bool) {
			#if (MODS_ALLOWED && SHADERS_ALLOWED)
			var shader:FlxRuntimeShader = funk.getShader(obj);
			if(shader == null || !ClientPrefs.shaders) return;

			shader.setBool(prop, value);
			#else
			LuaUtils.luaTrace(funk.lua, "setShaderBool | Platform unsupported for Runtime Shaders!", false, false, FlxColor.RED);
			#end
		});
		FunkinLua.registerFunction("setShaderBoolArray", function(obj:String, prop:String, values:Dynamic) {
			#if (MODS_ALLOWED && SHADERS_ALLOWED)
			var shader:FlxRuntimeShader = funk.getShader(obj);
			if(shader == null || !ClientPrefs.shaders) return;

			shader.setBoolArray(prop, values);
			#else
			LuaUtils.luaTrace(funk.lua, "setShaderBoolArray | Platform unsupported for Runtime Shaders!", false, false, FlxColor.RED);
			#end
		});
		FunkinLua.registerFunction("setShaderInt", function(obj:String, prop:String, value:Int) {
			#if (MODS_ALLOWED && SHADERS_ALLOWED)
			var shader:FlxRuntimeShader = funk.getShader(obj);
			if(shader == null || !ClientPrefs.shaders) return;

			shader.setInt(prop, value);
			#else
			LuaUtils.luaTrace(funk.lua, "setShaderInt | Platform unsupported for Runtime Shaders!", false, false, FlxColor.RED);
			#end
		});
		FunkinLua.registerFunction("setShaderIntArray", function(obj:String, prop:String, values:Dynamic) {
			#if (MODS_ALLOWED && SHADERS_ALLOWED)
			var shader:FlxRuntimeShader = funk.getShader(obj);
			if(shader == null || !ClientPrefs.shaders) return;

			shader.setIntArray(prop, values);
			#else
			LuaUtils.luaTrace(funk.lua, "setShaderIntArray | Platform unsupported for Runtime Shaders!", false, false, FlxColor.RED);
			#end
		});
		FunkinLua.registerFunction("setShaderFloat", function(obj:String, prop:String, value:Float) {
			#if (MODS_ALLOWED && SHADERS_ALLOWED)
			var shader:FlxRuntimeShader = funk.getShader(obj);
			if(shader == null || !ClientPrefs.shaders) return;

			shader.setFloat(prop, value);
			#else
			LuaUtils.luaTrace(funk.lua, "setShaderFloat | Platform unsupported for Runtime Shaders!", false, false, FlxColor.RED);
			#end
		});
		FunkinLua.registerFunction("setShaderFloatArray", function(obj:String, prop:String, values:Dynamic) {
			#if (MODS_ALLOWED && SHADERS_ALLOWED)
			var shader:FlxRuntimeShader = funk.getShader(obj);
			if(shader == null || !ClientPrefs.shaders) return;

			shader.setFloatArray(prop, values);
			#else
			LuaUtils.luaTrace(funk.lua, "setShaderFloatArray | Platform unsupported for Runtime Shaders!", false, false, FlxColor.RED);
			#end
		});

		FunkinLua.registerFunction("setShaderSampler2D", function(obj:String, prop:String, bitmapdataPath:String) {
			#if (MODS_ALLOWED && SHADERS_ALLOWED)
			var shader:FlxRuntimeShader = funk.getShader(obj);
			if(shader == null || !ClientPrefs.shaders) return;

			// trace('bitmapdatapath: $bitmapdataPath');
			var value = Paths.image(bitmapdataPath);
			if(value != null && value.bitmap != null)
			{
				// trace('Found bitmapdata. Width: ${value.bitmap.width} Height: ${value.bitmap.height}');
				shader.setSampler2D(prop, value.bitmap);
			}
			#else
			LuaUtils.luaTrace(funk.lua, "setShaderSampler2D | Platform unsupported for Runtime Shaders!", false, false, FlxColor.RED);
			#end
		});
		}
	}
}
