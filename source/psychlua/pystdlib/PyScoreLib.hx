package psychlua.pystdlib;

import psychlua.PythonScript;
import play.PlayState;
import backend.Highscore;
import psychlua.LuaUtils;

// REFACTOR: extracted from psychlua.PythonScript (score/health API)
class PyScoreLib
{
	public static function register(py:PythonScript):Void {
		@:privateAccess {
		// ---------------------------------------------------------------- //
		//                        SCORE / HEALTH                            //
		// ---------------------------------------------------------------- //
		PythonScript.registerFunction("addScore", function(value:Float = 0) {
			PlayState.instance.songScore += value;
			PlayState.instance.RecalculateRating();
		});
		PythonScript.registerFunction("addMisses", function(value:Int = 0) {
			PlayState.instance.songMisses += value;
			PlayState.instance.RecalculateRating();
		});
		PythonScript.registerFunction("addHits", function(value:Int = 0) {
			PlayState.instance.songHits += value;
			PlayState.instance.RecalculateRating();
		});
		PythonScript.registerFunction("addCombo", function(value:Int = 0) {
			PlayState.instance.combo += value;
			PlayState.instance.RecalculateRating();
		});
		PythonScript.registerFunction("addNPS", function(value:Int = 0) {
			PlayState.instance.nps += value;
		});
		PythonScript.registerFunction("setScore", function(value:Float = 0) {
			PlayState.instance.songScore = value;
			PlayState.instance.RecalculateRating();
		});
		PythonScript.registerFunction("setMisses", function(value:Int = 0) {
			PlayState.instance.songMisses = value;
			PlayState.instance.RecalculateRating();
		});
		PythonScript.registerFunction("setHits", function(value:Int = 0) {
			PlayState.instance.songHits = value;
			PlayState.instance.RecalculateRating();
		});
		PythonScript.registerFunction("getScore", function() {
			return PlayState.instance.songScore;
		});
		PythonScript.registerFunction("getMisses", function() {
			return PlayState.instance.songMisses;
		});
		PythonScript.registerFunction("getHits", function() {
			return PlayState.instance.songHits;
		});
		PythonScript.registerFunction("setHealth", function(value:Float = 0) {
			PlayState.instance.health = value;
		});
		PythonScript.registerFunction("addHealth", function(value:Float = 0) {
			PlayState.instance.health += value;
		});
		PythonScript.registerFunction("addPlaybackSpeed", function(value:Float = 0) {
			PlayState.instance.playbackRate += value;
		});
		PythonScript.registerFunction("getHealth", function() {
			return PlayState.instance.health;
		});
		PythonScript.registerFunction("getPlaybackSpeed", function() {
			return PlayState.instance.playbackRate;
		});
		PythonScript.registerFunction("setPlaybackSpeed", function(value:Float = 0) {
			PlayState.instance.playbackRate = value;
		});
		PythonScript.registerFunction("changeMaxHealth", function(value:Float = 0) {
			var bar = PlayState.instance.healthBar;
			PlayState.instance.maxHealth = value;
			bar.setRange(0, value);
		});
		PythonScript.registerFunction("getMaxHealth", function() {
			return PlayState.instance.maxHealth;
		});
		PythonScript.registerFunction("getColorFromHex", function(color:String) {
			if(!color.startsWith('0x')) color = '0xff' + color;
			return Std.parseInt(color);
		});
		}
	}
}
