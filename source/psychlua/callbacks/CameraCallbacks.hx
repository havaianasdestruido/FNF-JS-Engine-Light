package psychlua.callbacks;

import flixel.FlxCamera;
import flixel.util.FlxColor;
import play.PlayState;
import psychlua.FunkinLua;
import psychlua.LuaUtils;

// REFACTOR: extracted from psychlua.FunkinLua (createCamera/addCamera/removeCamera)
class CameraCallbacks
{
	public static function register(funk:FunkinLua):Void {
		final game:PlayState = PlayState.instance;
		@:privateAccess {
		// Helper to generate a unique key name if conflicts exist
		function getUniqueName(base:String, variables:Map<String, Dynamic>):String {
			var candidate = base;
			var counter = 1;

			while (variables.exists(candidate)) {
				// If it's a FlxCamera, stop — we want to avoid overwriting cameras too
				if (Std.isOfType(variables.get(candidate), FlxCamera)) {
					candidate = base + "-" + counter;
					counter++;
				} else {
					// If it's not a camera, still rename to avoid collision
					candidate = base + "-" + counter;
					counter++;
				}
			}

			return candidate;
		}

		// camera funcs, just to help extend the Lua API
		// reminder that is for *creating* them, you need to add them after
		FunkinLua.registerFunction("createCamera", function(cameraName:String, config:Dynamic) {
				final camera = new FlxCamera();
				if (config == null){
					config = {
						x: 0.0,
						y: 0.0,
						width: 0,
						height: 0,
						zoom: 0.0,
						defaultDrawTarget: false
					}
				}
				camera.x = config.x ??= 0.0;
				camera.y = config.y ??= 0.0;
				camera.width = config.width ??= 0;
				camera.height = config.height ??= 0;
				camera.zoom = config.zoom ??= 0.0;
				camera.active = true;
				// just make *sure* there isn't an camera name of an existing variable
				final fucker = PlayState.instance.variables;
				final safeName = getUniqueName(cameraName, fucker);
				if (!fucker.exists(cameraName))
					fucker.set(cameraName, camera);
				else if (safeName != cameraName) {
					LuaUtils.luaTrace(
						funk.lua,
						'An object of $cameraName exists, renaming to $safeName to avoid conflict.',
						false, false, FlxColor.RED
					);
					fucker.set(safeName, camera);
				}
		});

		FunkinLua.registerFunction("addCamera", function(cameraName:String, position:Null<Int> = null, defaultDrawTarget:Bool = false) {
			if(cameraName.trim() != '' && game.variables.exists(cameraName)) {
				final theCam:FlxCamera = game.variables.get(cameraName);
				if (position != null) // allows you to add cameras above camHUD, camGame etc.
					FlxG.cameras.insert(theCam, position, defaultDrawTarget);
				else
					FlxG.cameras.add(theCam, defaultDrawTarget);
			}
		});

		FunkinLua.registerFunction("removeCamera", function(cameraName:String) {
			if(cameraName.trim() != '' && game.variables.exists(cameraName)) {
				final theCam:FlxCamera = game.variables.get(cameraName);
				FlxG.cameras.remove(theCam);
			}
		});
		}
	}
}
