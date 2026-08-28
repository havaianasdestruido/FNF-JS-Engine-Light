package psychlua.pystdlib;

import flixel.util.FlxTimer;
import psychlua.PythonScript;
import play.PlayState;
import psychlua.LuaUtils;

// REFACTOR: extracted from psychlua.PythonScript (timer API)
class PyTimerLib
{
	public static function register(py:PythonScript):Void {
		@:privateAccess {
		// ---------------------------------------------------------------- //
		//                           TIMERS                                 //
		// ---------------------------------------------------------------- //
		PythonScript.registerFunction("runTimer", function(tag:String, time:Float = 1, loops:Int = 1) {
			py.cancelTimer(tag);
			PlayState.instance.modchartTimers.set(tag, new FlxTimer().start(time, function(tmr:FlxTimer) {
				if(tmr.finished) {
					PlayState.instance.modchartTimers.remove(tag);
				}
				PlayState.instance.callOnLuas('onTimerCompleted', [tag, tmr.loops, tmr.loopsLeft]);
			}, loops));
		});
		PythonScript.registerFunction("cancelTimer", function(tag:String) {
			py.cancelTimer(tag);
		});
		}
	}
}
