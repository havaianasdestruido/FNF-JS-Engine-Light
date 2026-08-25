package psychlua.pystdlib;

import psychlua.PythonScript;
import play.PlayState;
import psychlua.LuaUtils;

// REFACTOR: imports for relocated root classes
import objects.Character;

// REFACTOR: extracted from psychlua.PythonScript (character API)
class PyCharacterLib
{
	public static function register(py:PythonScript):Void {
		@:privateAccess {
		// ---------------------------------------------------------------- //
		//                        CHARACTERS                                //
		// ---------------------------------------------------------------- //
		PythonScript.registerFunction("getCharacterX", function(type:String) {
			switch(type.toLowerCase()) {
				case 'dad' | 'opponent':
					return PlayState.instance.dadGroup.x;
				case 'gf' | 'girlfriend':
					return PlayState.instance.gfGroup.x;
				default:
					return PlayState.instance.boyfriendGroup.x;
			}
		});
		PythonScript.registerFunction("setCharacterX", function(type:String, value:Float) {
			switch(type.toLowerCase()) {
				case 'dad' | 'opponent':
					PlayState.instance.dadGroup.x = value;
				case 'gf' | 'girlfriend':
					PlayState.instance.gfGroup.x = value;
				default:
					PlayState.instance.boyfriendGroup.x = value;
			}
		});
		PythonScript.registerFunction("getCharacterY", function(type:String) {
			switch(type.toLowerCase()) {
				case 'dad' | 'opponent':
					return PlayState.instance.dadGroup.y;
				case 'gf' | 'girlfriend':
					return PlayState.instance.gfGroup.y;
				default:
					return PlayState.instance.boyfriendGroup.y;
			}
		});
		PythonScript.registerFunction("setCharacterY", function(type:String, value:Float) {
			switch(type.toLowerCase()) {
				case 'dad' | 'opponent':
					PlayState.instance.dadGroup.y = value;
				case 'gf' | 'girlfriend':
					PlayState.instance.gfGroup.y = value;
				default:
					PlayState.instance.boyfriendGroup.y = value;
			}
		});
		PythonScript.registerFunction("dance", function(character:String = 'bf') {
			switch(character.toLowerCase()) {
				case 'dad': PlayState.instance.dad.dance();
				case 'gf' | 'girlfriend': if(PlayState.instance.gf != null) PlayState.instance.gf.dance();
				default: PlayState.instance.boyfriend.dance();
			}
		});
		PythonScript.registerFunction("addCharacterToList", function(name:String, type:String) {
			var charType:Int = 0;
			switch(type.toLowerCase()) {
				case 'dad': charType = 1;
				case 'gf' | 'girlfriend': charType = 2;
			}
			PlayState.instance.addCharacterToList(name, charType);
		});
		PythonScript.registerFunction("setRatingPercent", function(value:Float) {
			PlayState.instance.ratingPercent = value;
		});
		PythonScript.registerFunction("setRatingName", function(value:String) {
			PlayState.instance.ratingName = value;
		});
		PythonScript.registerFunction("setRatingFC", function(value:String) {
			PlayState.instance.ratingFC = value;
		});
		}
	}
}
