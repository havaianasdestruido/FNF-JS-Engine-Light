package psychlua.callbacks;

import backend.Conductor;
import backend.Highscore;
import backend.Paths;
import data.Song;
import play.PlayState;
import psychlua.FunkinLua;
import headers.PsychLua;
import states.LoadingState;
import states.FreeplayState;
import states.StoryMenuState;
import states.substates.PauseSubState;
import objects.DialogueBoxPsych;
import objects.DialogueBoxPsych.DialogueFile;

import objects.Character;

// REFACTOR: extracted from psychlua.FunkinLua (song flow / score / characters / gameplay events)
class GameCallbacks
{
	public static function register(funk:FunkinLua):Void {
		final game:PlayState = PlayState.instance;
		@:privateAccess {
		FunkinLua.registerFunction("loadSong", function(?name:String = null, ?difficultyNum:Int = -1) {
			if(name == null || name.length < 1)
				name = PlayState.SONG.song;
			if (difficultyNum == -1)
				difficultyNum = PlayState.storyDifficulty;

			var poop = Highscore.formatSong(name, difficultyNum);
			PlayState.SONG = Song.loadFromJson(poop, name);
			PlayState.storyDifficulty = difficultyNum;
			PlayState.instance.persistentUpdate = false;
			LoadingState.loadAndSwitchState(PlayState.new);

			FlxG.sound.music.pause();
			FlxG.sound.music.volume = 0;
			if(PlayState.instance.vocals != null)
			{
				PlayState.instance.vocals.pause();
				PlayState.instance.vocals.volume = 0;
			}
		});
		//stupid bietch ass functions
		FunkinLua.registerFunction("addScore", function(value:Float = 0) {
			PlayState.instance.songScore += value;
			PlayState.instance.RecalculateRating();
		});
		FunkinLua.registerFunction("addMisses", function(value:Int = 0) {
			PlayState.instance.songMisses += value;
			PlayState.instance.RecalculateRating();
		});
		FunkinLua.registerFunction("addHits", function(value:Int = 0) {
			PlayState.instance.songHits += value;
			PlayState.instance.RecalculateRating();
		});
		FunkinLua.registerFunction("addCombo", function(value:Int = 0) {
			PlayState.instance.combo += value;
			PlayState.instance.RecalculateRating();
		});
		FunkinLua.registerFunction("addNPS", function(value:Int = 0) {
			PlayState.instance.nps += value;
		});
		FunkinLua.registerFunction("setScore", function(value:Float = 0) {
			var newScore:Float = value;
			PlayState.instance.songScore = newScore;
			PlayState.instance.RecalculateRating();
		});
		FunkinLua.registerFunction("setMisses", function(value:Int = 0) {
			PlayState.instance.songMisses = value;
			PlayState.instance.RecalculateRating();
		});
		FunkinLua.registerFunction("setHits", function(value:Int = 0) {
			PlayState.instance.songHits = value;
			PlayState.instance.RecalculateRating();
		});
		FunkinLua.registerFunction("getScore", function() {
			return PlayState.instance.songScore;
		});
		FunkinLua.registerFunction("getMisses", function() {
			return PlayState.instance.songMisses;
		});
		FunkinLua.registerFunction("getHits", function() {
			return PlayState.instance.songHits;
		});

		FunkinLua.registerFunction("setHealth", function(value:Float = 0) {
			PlayState.instance.health = value;
		});
		FunkinLua.registerFunction("addHealth", function(value:Float = 0) {
			PlayState.instance.health += value;
		});
		FunkinLua.registerFunction("addPlaybackSpeed", function(value:Float = 0) {
			PlayState.instance.playbackRate += value;
		});
		FunkinLua.registerFunction("getHealth", function() {
			return PlayState.instance.health;
		});
		FunkinLua.registerFunction("getPlaybackSpeed", function() {
			return PlayState.instance.playbackRate;
		});
		FunkinLua.registerFunction("setPlaybackSpeed", function(value:Float = 0) {
			PlayState.instance.playbackRate = value;
		});
		FunkinLua.registerFunction("changeMaxHealth", function(value:Float = 0) {
			{
				var bar = PlayState.instance.healthBar;
				PlayState.instance.maxHealth = value;
				bar.setRange(0, value);
			}
		});
		FunkinLua.registerFunction("getMaxHealth", function() {
			return PlayState.instance.maxHealth;
		});
		FunkinLua.registerFunction("getColorFromHex", function(color:String) {
			if(!color.startsWith('0x')) color = '0xff' + color;
			return Std.parseInt(color);
		});
		FunkinLua.registerFunction("addCharacterToList", function(name:String, type:String) {
			var charType:Int = 0;
			switch(type.toLowerCase()) {
				case 'dad': charType = 1;
				case 'gf' | 'girlfriend': charType = 2;
			}
			PlayState.instance.addCharacterToList(name, charType);
		});
		FunkinLua.registerFunction("precacheImage", function(name:String) {
			Paths.image(name);
		});
		FunkinLua.registerFunction("precacheSound", function(name:String) {
			Paths.sound(name);
		});
		FunkinLua.registerFunction("precacheMusic", function(name:String) {
			Paths.music(name);
		});
		FunkinLua.registerFunction("triggerEvent", function(name:String, arg1:Dynamic, arg2:Dynamic, strumTime:Float) {
			var value1:String = arg1;
			var value2:String = arg2;
			PlayState.instance.triggerEventNote(name, value1, value2, strumTime);
			//trace('Triggered event: ' + name + ', ' + value1 + ', ' + value2);
			return true;
		});

		FunkinLua.registerFunction("startCountdown", function() {
			PlayState.instance.startCountdown();
			return true;
		});
		FunkinLua.registerFunction("endSong", function() {
			PlayState.instance.KillNotes();
			PlayState.instance.endSong();
			return true;
		});
		FunkinLua.registerFunction("restartSong", function(?skipTransition:Bool = false) {
			PlayState.instance.persistentUpdate = false;
			PauseSubState.restartSong(skipTransition);
			return true;
		});
		FunkinLua.registerFunction("exitSong", function(?skipTransition:Bool = false) {
			if(skipTransition)
			{
				FlxTransitionableState.skipNextTransIn = true;
				FlxTransitionableState.skipNextTransOut = true;
			}

			if(FlxG.sound.music != null) FlxG.sound.music.stop();

			if(PlayState.isStoryMode)
				FlxG.switchState(StoryMenuState.new);
			else
				FlxG.switchState(FreeplayState.new);

			FlxG.sound.playMusic(Paths.music('freakyMenu'));
			PlayState.changedDifficulty = false;
			PlayState.chartingMode = false;
			PlayState.instance.transitioning = true;
			Mods.loadTopMod();
			return true;
		});
		FunkinLua.registerFunction("getSongPosition", function() {
			return Conductor.songPosition;
		});
		FunkinLua.registerFunction("getCharacterX", function(type:String) {
			switch(type.toLowerCase()) {
				case 'dad' | 'opponent':
					return PlayState.instance.dadGroup.x;
				case 'gf' | 'girlfriend':
					return PlayState.instance.gfGroup.x;
				default:
					return PlayState.instance.boyfriendGroup.x;
			}
		});
		FunkinLua.registerFunction("setCharacterX", function(type:String, value:Float) {
			switch(type.toLowerCase()) {
				case 'dad' | 'opponent':
					PlayState.instance.dadGroup.x = value;
				case 'gf' | 'girlfriend':
					PlayState.instance.gfGroup.x = value;
				default:
					PlayState.instance.boyfriendGroup.x = value;
			}
		});
		FunkinLua.registerFunction("getCharacterY", function(type:String) {
			switch(type.toLowerCase()) {
				case 'dad' | 'opponent':
					return PlayState.instance.dadGroup.y;
				case 'gf' | 'girlfriend':
					return PlayState.instance.gfGroup.y;
				default:
					return PlayState.instance.boyfriendGroup.y;
			}
		});
		FunkinLua.registerFunction("setCharacterY", function(type:String, value:Float) {
			switch(type.toLowerCase()) {
				case 'dad' | 'opponent':
					PlayState.instance.dadGroup.y = value;
				case 'gf' | 'girlfriend':
					PlayState.instance.gfGroup.y = value;
				default:
					PlayState.instance.boyfriendGroup.y = value;
			}
		});
		FunkinLua.registerFunction("cameraSetTarget", function(target:String) {
			switch(target.trim().toLowerCase())
			{
				case 'gf', 'girlfriend': // now gf can be targeted
					game.moveCamera('gf');
				case 'dad', 'opponent':
					game.moveCamera('dad');
				default:
					game.moveCamera('bf');
			}
		});
		FunkinLua.registerFunction("cameraShake", function(camera:String, intensity:Float, duration:Float) {
			LuaUtils.cameraFromString(camera).shake(intensity, duration / PlayState.instance.playbackRate);
		});

		FunkinLua.registerFunction("cameraFlash", function(camera:String, color:String, duration:Float,forced:Bool) {
			var colorNum:Int = Std.parseInt(color);
			if(!color.startsWith('0x')) colorNum = Std.parseInt('0xff' + color);
			LuaUtils.cameraFromString(camera).flash(colorNum, duration / PlayState.instance.playbackRate,null,forced);
		});
		FunkinLua.registerFunction("cameraFade", function(camera:String, color:String, duration:Float, forced:Bool, ?fadeOut:Bool = false) {
			var colorNum:Int = Std.parseInt(color);
			if(!color.startsWith('0x')) colorNum = Std.parseInt('0xff' + color);
			LuaUtils.cameraFromString(camera).fade(colorNum, duration / PlayState.instance.playbackRate, fadeOut, null, forced);
		});
		FunkinLua.registerFunction("setRatingPercent", function(value:Float) {
			PlayState.instance.ratingPercent = value;
		});
		FunkinLua.registerFunction("setRatingName", function(value:String) {
			PlayState.instance.ratingName = value;
		});
		FunkinLua.registerFunction("setRatingFC", function(value:String) {
			PlayState.instance.ratingFC = value;
		});
		FunkinLua.registerFunction("getMouseX", function(camera:String) {
			var cam:FlxCamera = LuaUtils.cameraFromString(camera);
			return FlxG.mouse.getScreenPosition(cam).x;
		});
		FunkinLua.registerFunction("getMouseY", function(camera:String) {
			var cam:FlxCamera = LuaUtils.cameraFromString(camera);
			return FlxG.mouse.getScreenPosition(cam).y;
		});
		FunkinLua.registerFunction("characterDance", function(character:String) {
			switch(character.toLowerCase()) {
				case 'dad': PlayState.instance.dad.dance();
				case 'gf' | 'girlfriend': if(PlayState.instance.gf != null) PlayState.instance.gf.dance();
				default: PlayState.instance.boyfriend.dance();
			}
		});
		FunkinLua.registerFunction("startDialogue", function(dialogueFile:String, music:String = null) {
			var path:String;
			#if MODS_ALLOWED
			path = Paths.modsJson(Paths.formatToSongPath(PlayState.SONG.song) + '/' + dialogueFile);
			if(!FileSystem.exists(path))
			#end
				path = Paths.json(Paths.formatToSongPath(PlayState.SONG.song) + '/' + dialogueFile);

			LuaUtils.luaTrace(funk.lua, 'startDialogue | Trying to load dialogue: ' + path);

			#if MODS_ALLOWED
			if(FileSystem.exists(path))
			#else
			if(Assets.exists(path))
			#end
			{
				var shit:DialogueFile = DialogueBoxPsych.parseDialogue(path);
				if(shit.dialogue.length > 0) {
					PlayState.instance.startDialogue(shit, music);
					LuaUtils.luaTrace(funk.lua, 'startDialogue | Successfully loaded dialogue', false, false, FlxColor.GREEN);
					return true;
				} else {
					LuaUtils.luaTrace(funk.lua, 'startDialogue | Your dialogue file is badly formatted!', false, false, FlxColor.RED);
				}
			} else {
				LuaUtils.luaTrace(funk.lua, 'startDialogue | Dialogue file not found', false, false, FlxColor.RED);
				if(PlayState.instance.endingSong) {
					PlayState.instance.endSong();
				} else {
					PlayState.instance.startCountdown();
				}
			}
			return false;
		});
		FunkinLua.registerFunction("startVideo", function(videoFile:String) {
			#if VIDEOS_ALLOWED
			if(FileSystem.exists(Paths.video(videoFile))) {
				PlayState.instance.startVideo(videoFile);
				return true;
			} else {
				LuaUtils.luaTrace(funk.lua, 'startVideo | Video file not found: ' + videoFile, false, false, FlxColor.RED);
			}
			return false;

			#else
			if(PlayState.instance.endingSong) {
				PlayState.instance.endSong();
			} else {
				PlayState.instance.startCountdown();
			}
			return true;
			#end
		});
		}
	}
}
