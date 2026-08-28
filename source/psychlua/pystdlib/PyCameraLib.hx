package psychlua.pystdlib;

// REFACTOR: restored imports
import flixel.FlxCamera;
import flixel.FlxG;
import psychlua.PythonScript;
import play.PlayState;
import psychlua.LuaUtils;

// REFACTOR: extracted from psychlua.PythonScript (camera API)
class PyCameraLib
{
	public static function register(py:PythonScript):Void {
		final game:PlayState = PlayState.instance;
		@:privateAccess {
		// ---------------------------------------------------------------- //
		//                           CAMERA                                 //
		// ---------------------------------------------------------------- //
		PythonScript.registerFunction("cameraSetTarget", function(target:String) {
			switch(target.trim().toLowerCase()) {
				case 'gf' | 'girlfriend':
					game.moveCamera('gf');
				case 'dad' | 'opponent':
					game.moveCamera('dad');
				default:
					game.moveCamera('bf');
			}
		});
		PythonScript.registerFunction("cameraShake", function(camera:String, intensity:Float, duration:Float) {
			LuaUtils.cameraFromString(camera).shake(intensity, duration / PlayState.instance.playbackRate);
		});
		PythonScript.registerFunction("cameraFlash", function(camera:String, color:String, duration:Float, forced:Bool) {
			var colorNum:Int = Std.parseInt(color);
			if(!color.startsWith('0x')) colorNum = Std.parseInt('0xff' + color);
			LuaUtils.cameraFromString(camera).flash(colorNum, duration / PlayState.instance.playbackRate, null, forced);
		});
		PythonScript.registerFunction("cameraFade", function(camera:String, color:String, duration:Float, forced:Bool, ?fadeOut:Bool = false) {
			var colorNum:Int = Std.parseInt(color);
			if(!color.startsWith('0x')) colorNum = Std.parseInt('0xff' + color);
			LuaUtils.cameraFromString(camera).fade(colorNum, duration / PlayState.instance.playbackRate, fadeOut, null, forced);
		});
		PythonScript.registerFunction("getMouseX", function(camera:String) {
			var cam:FlxCamera = LuaUtils.cameraFromString(camera);
			return FlxG.mouse.getScreenPosition(cam).x;
		});
		PythonScript.registerFunction("getMouseY", function(camera:String) {
			var cam:FlxCamera = LuaUtils.cameraFromString(camera);
			return FlxG.mouse.getScreenPosition(cam).y;
		});
		PythonScript.registerFunction("mouseClicked", function(button:String) {
			var boobs = FlxG.mouse.justPressed;
			switch(button) {
				case 'middle': boobs = FlxG.mouse.justPressedMiddle;
				case 'right': boobs = FlxG.mouse.justPressedRight;
			}
			return boobs;
		});
		PythonScript.registerFunction("mousePressed", function(button:String) {
			var boobs = FlxG.mouse.pressed;
			switch(button) {
				case 'middle': boobs = FlxG.mouse.pressedMiddle;
				case 'right': boobs = FlxG.mouse.pressedRight;
			}
			return boobs;
		});
		PythonScript.registerFunction("mouseReleased", function(button:String) {
			var boobs = FlxG.mouse.justReleased;
			switch(button) {
				case 'middle': boobs = FlxG.mouse.justReleasedMiddle;
				case 'right': boobs = FlxG.mouse.justReleasedRight;
			}
			return boobs;
		});
		}
	}
}
