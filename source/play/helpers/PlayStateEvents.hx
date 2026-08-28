package play.helpers;

import flixel.util.FlxSort;
import backend.ClientPrefs;
import backend.Conductor;

import objects.Character;
import objects.CreditsPopUp;

import play.BaseStage;

import play.PlayState;

import play.helpers.PlayStateCharacters;
import play.helpers.PlayStatePlayback;
import play.helpers.PlayStateScripts;

// REFACTOR: imports for relocated root classes
import data.Song;
import objects.Note;

// REFACTOR: event handling extracted from play.PlayState
@:access(play.PlayState)
@:access(backend.MusicBeatState)
class PlayStateEvents
{
	// called only once per different event (Used for precaching)
	public static function eventPushed(state:PlayState, event:EventNote) {
		switch (event.event)
		{
			case 'Change Character':
				var charType:Int = 0;
				switch(event.value1.toLowerCase()) {
					case 'gf' | 'girlfriend' | '1':
						charType = 2;
					case 'dad' | 'opponent' | '0':
						charType = 1;
					default:
						charType = Std.parseInt(event.value1);
						if(Math.isNaN(charType)) charType = 0;
				}
				state.charChangeTimes.push(event.strumTime);
				state.charChangeNames.push(event.value2);
				state.charChangeTypes.push(charType);
			case 'Change Note Multiplier':
				var noteMultiplier:Float = Std.parseFloat(event.value1);
				if (Math.isNaN(noteMultiplier))
					noteMultiplier = 1;

				state.multiChangeEvents[0].push(event.strumTime);
				state.multiChangeEvents[1].push(noteMultiplier);
		}
		eventPushedUnique(state, event);
		if(state.eventPushedMap.exists(event.event)) {
			return;
		}

		state.stagesFunc(function(stage:BaseStage) stage.eventPushed(event));
		if(!state.eventPushedMap.exists(event.event)) {
			state.eventPushedMap.set(event.event, true);
		}
	}

	public static function eventPushedUnique(state:PlayState, event:EventNote) {
		switch(event.event) {
			case 'Change Character':
			if (ClientPrefs.charsAndBG)
			{
				var charType:Int = 0;
				switch(event.value1.toLowerCase()) {
					case 'gf' | 'girlfriend' | '1':
						charType = 2;
					case 'dad' | 'opponent' | '0':
						charType = 1;
					default:
						charType = Std.parseInt(event.value1);
						if(Math.isNaN(charType)) charType = 0;
				}

				var newCharacter:String = event.value2;
				PlayStateCharacters.addCharacterToList(state, newCharacter, charType);
			}
		}
		state.stagesFunc(function(stage:BaseStage) stage.eventPushedUnique(event));
	}

	public static function eventNoteEarlyTrigger(state:PlayState, event:EventNote):Float {
		var returnedValue:Null<Float> = state.callOnLuas('eventEarlyTrigger', [event.event, event.value1, event.value2, event.strumTime], [], [0]);
		if(returnedValue != null && returnedValue != 0 && returnedValue != FunkinLua.Function_Continue) {
			return returnedValue;
		}

		switch(event.event) {
			case 'Kill Henchmen': //Better timing so that the kill sound matches the beat intended
				return 280; //Plays 280ms before the actual position
		}
		return 0;
	}

	public static function sortByTime(state:PlayState, Obj1:Dynamic, Obj2:Dynamic):Int
	{
		return FlxSort.byValues(FlxSort.ASCENDING, Obj1.strumTime, Obj2.strumTime);
	}

	public static function sortByShit(state:PlayState, Obj1:Note, Obj2:Note):Int {
		return FlxSort.byValues(FlxSort.ASCENDING, Obj1.strumTime, Obj2.strumTime);
	}

	public static function triggerEventNote(state:PlayState, eventName:String, value1:String, value2:String, strumTime:Float) {
		var flValue1:Null<Float> = Std.parseFloat(value1);
		var flValue2:Null<Float> = Std.parseFloat(value2);
		if(Math.isNaN(flValue1)) flValue1 = null;
		if(Math.isNaN(flValue2)) flValue2 = null;

		switch(eventName) {
			case 'Hey!':
				if (ClientPrefs.charsAndBG) {
					var value:Int = 2;
					switch(value1.toLowerCase().trim()) {
						case 'bf' | 'boyfriend' | '0':
							value = 0;
						case 'gf' | 'girlfriend' | '1':
							value = 1;
					}

					var time:Float = Std.parseFloat(value2);
					if(Math.isNaN(time) || time <= 0) time = 0.6;

					if(value != 0) {
						if(state.dad.curCharacter.startsWith('gf')) { //Tutorial GF is actually Dad! The GF is an imposter!! ding ding ding ding ding ding ding, dindinding, end my suffering
							state.dad.playAnim('cheer', true);
							state.dad.specialAnim = true;
							state.dad.heyTimer = time;
						} else if (state.gf != null) {
							state.gf.playAnim('cheer', true);
							state.gf.specialAnim = true;
							state.gf.heyTimer = time;
						}
					}
					if(value != 1) {
						state.boyfriend.playAnim('hey', true);
						state.boyfriend.specialAnim = true;
						state.boyfriend.heyTimer = time;
					}
				}

			case 'Set GF Speed':
				var value:Int = Std.parseInt(value1);
				if(Math.isNaN(value) || value < 1) value = 1;
				state.gfSpeed = value;
				if (Conductor.bpm >= 500) state.singDurMult = value;

			case 'Enable Camera Bop':
				state.camZooming = true;

			case 'Disable Camera Bop':
				state.camZooming = false;
				FlxG.camera.zoom = state.defaultCamZoom;
				state.camHUD.zoom = 1;

			case 'Enable Bot Energy':
				if (!state.cpuControlled)
				{
					state.canUseBotEnergy = true;
					state.energyBarBG.visible = state.energyBar.visible = state.energyTxt.visible = true;
					var varsFadeIn:Array<Dynamic> = [state.energyBarBG, state.energyBar, state.energyTxt];
					for (i in 0...varsFadeIn.length) FlxTween.tween(varsFadeIn[i], {alpha: 1}, 0.75, {ease: FlxEase.expoOut});
				}

			case 'Disable Bot Energy':
				if (!state.cpuControlled)
				{
					state.canUseBotEnergy = false;
					if (state.usingBotEnergy) state.usingBotEnergy = false;
					var varsFadeIn:Array<Dynamic> = [state.energyBarBG, state.energyBar, state.energyTxt];
					for (i in 0...varsFadeIn.length)
						FlxTween.tween(varsFadeIn[i], {alpha: 0}, 0.75, {ease: FlxEase.expoOut, onComplete: function(_)
						{
							varsFadeIn[i].visible = false;
						}});
				}

			case 'Set Bot Energy Speeds':
				var drainSpeed:Float = Std.parseFloat(value1);
				if (Math.isNaN(drainSpeed)) drainSpeed = 1;
				state.energyDrainSpeed = drainSpeed;

				var refillSpeed:Float = Std.parseFloat(value2);
				if (Math.isNaN(refillSpeed)) refillSpeed = 1;
				state.energyRefillSpeed = refillSpeed;

			case 'Credits Popup':
			{
				var string1:String = (value1.length > 1 ? value1 : PlayState.SONG.song);
				var string2:String = (value2.length > 1 ? value2 : PlayState.SONG.songCredit);

				var creditsPopup:CreditsPopUp = new CreditsPopUp(FlxG.width, 200, string1, string2);
				creditsPopup.camera = state.camHUD;
				creditsPopup.scrollFactor.set();
				creditsPopup.x = creditsPopup.width * -1;
				state.add(creditsPopup);

				FlxTween.tween(creditsPopup, {x: 0}, 0.5, {ease: FlxEase.backOut, onComplete: function(tweeen:FlxTween)
				{
					FlxTween.tween(creditsPopup, {x: creditsPopup.width * -1} , 1, {ease: FlxEase.backIn, onComplete: function(tween:FlxTween)
					{
						creditsPopup.destroy();
					}, startDelay: 3});
				}});
			}
			case 'Camera Bopping':
				var _interval:Int = Std.parseInt(value1);
				if (Math.isNaN(_interval))
					_interval = 4;
				var _intensity:Float = Std.parseFloat(value2);
				if (Math.isNaN(_intensity))
					_intensity = 1;

				state.camBopIntensity = _intensity;
				state.camBopInterval = _interval;
				if (_interval != 4) state.usingBopIntervalEvent = true;
					else state.usingBopIntervalEvent = false;

			case 'Tween Camera Zoom':
				var zoom:Float = state.ogCamZoom;

				if (value1 != 'default' && value1.trim() != '') {
				  var parsedZoom:Float = Std.parseFloat(value1);
				  if (!Math.isNaN(parsedZoom)) {
					zoom = parsedZoom;
				  }
				}

				var split:Array<String> = value2.split(',');
				var duration:Float = 0;
				var ease:Dynamic = FlxEase.linear;

				if (split.length > 0 && split[0].trim() != '') {
				  var parsedDuration:Float = Std.parseFloat(split[0].trim());
				  if (!Math.isNaN(parsedDuration)) {
					duration = parsedDuration / state.playbackRate;
				  }
				}
				if (split.length > 1) ease = psychlua.LuaUtils.getFlxEaseByString(split[1]);

				state.cameraTwn?.cancel();
				if (state.camZooming) {
				  state.cameraTwn = FlxTween.tween(state, {_defaultCamZoom: zoom}, duration, {ease: ease, onComplete:
					function (twn:FlxTween) {
					  state.cameraTwn = null;
					}
				  });
				} else {
				  state._defaultCamZoom = zoom;
				  state.cameraTwn = FlxTween.tween(FlxG.camera, {zoom: zoom}, duration, {ease: ease, onComplete:
					function (twn:FlxTween) {
					  state.cameraTwn = null;
					}
				  });
				}

			case 'Camera Twist':
				state.camTwist = true;
				var _intensity:Float = Std.parseFloat(value1);
				if (Math.isNaN(_intensity))
					_intensity = 0;
				var _intensity2:Float = Std.parseFloat(value2);
				if (Math.isNaN(_intensity2))
					_intensity2 = 0;
				state.camTwistIntensity = _intensity;
				state.camTwistIntensity2 = _intensity2;
				if (_intensity2 == 0)
				{
					state.camTwist = false;
					for (i in [state.camHUD, state.camGame])
					{
						FlxTween.cancelTweensOf(i);
						FlxTween.tween(i, {angle: 0, x: 0, y: 0}, 1, {ease: FlxEase.sineOut});
					}
				}
			case 'Change Note Multiplier':
				var noteMultiplier:Float = Std.parseFloat(value1);
				if (Math.isNaN(noteMultiplier))
					noteMultiplier = 1;

				if (value2 == "") {
					state.polyphonyOppo = noteMultiplier;
					state.polyphonyBF = noteMultiplier;
				} else {
					switch(value2) {
						case "1": state.polyphonyOppo = noteMultiplier;
						case "2": state.polyphonyBF = noteMultiplier;
					}
				}

			case 'Set Camera Zoom', 'Set Cam Zoom': //Set Cam Zoom was added just to make it cross-compatible with the mod i use that has this specific event
				var newZoom:Float = state.ogCamZoom;
				if (value1 != 'default' && value1.trim() != '') {
				  var parsedZoom:Float = Std.parseFloat(value1);
				  if (!Math.isNaN(parsedZoom)) {
					newZoom = parsedZoom;
				  }
				}

				state.defaultCamZoom = newZoom;

			case 'Fake Song Length':
				var fakelength:Float = Std.parseFloat(value1);
				fakelength *= (Math.isNaN(fakelength) ? 1 : 1000); //don't multiply if value1 is null, but do if value1 is not null
				var doTween:Bool = value2 == "true" ? true : false;
				if (Math.isNaN(fakelength))
					fakelength = FlxG.sound.music.length;
				if (doTween = true) FlxTween.tween(state, {songLength: fakelength}, 1, {ease: FlxEase.expoOut});
				if (doTween = true && (Math.isNaN(fakelength))) FlxTween.tween(state, {songLength: FlxG.sound.music.length}, 1, {ease: FlxEase.expoOut});
				state.songLength = fakelength;

			case 'Add Camera Zoom':
				if(ClientPrefs.camZooms && state.camHUD.zoom < 1.35) {
					var camZoom:Float = Std.parseFloat(value1);
					var hudZoom:Float = Std.parseFloat(value2);
					if(Math.isNaN(camZoom)) camZoom = 0.015;
					if(Math.isNaN(hudZoom)) hudZoom = 0.03;

					state.camBopFactor += camZoom;
					state.camHUD.zoom += hudZoom;
				}

			case 'Play Animation':
				//trace('Anim to play: ' + value1);
				var char:Character = state.dad;
				switch(value2.toLowerCase().trim()) {
					case 'bf' | 'boyfriend':
						char = state.boyfriend;
					case 'gf' | 'girlfriend':
						char = state.gf;
					default:
						var val2:Int = Std.parseInt(value2);
						if(Math.isNaN(val2)) val2 = 0;

						switch(val2) {
							case 1: char = state.boyfriend;
							case 2: char = state.gf;
						}
				}

				if (char != null && ClientPrefs.charsAndBG)
				{
					char.playAnim(value1, true);
					char.specialAnim = true;
				}

			// Evil
			case 'Windows Notification':
				if (value1 == "") value1 = "JS Engine";
				if (value2 == "") value2 = "Are you doing that one bambi song?";
				sendWindowsNotification(state, value1, value2, true);

			case 'Camera Follow Pos':
				if(state.camFollow != null)
				{
					var val1:Float = Std.parseFloat(value1);
					var val2:Float = Std.parseFloat(value2);
					if(Math.isNaN(val1)) val1 = 0;
					if(Math.isNaN(val2)) val2 = 0;

					state.isCameraOnForcedPos = false;
					if(!Math.isNaN(Std.parseFloat(value1)) || !Math.isNaN(Std.parseFloat(value2))) {
						state.camFollow.x = val1;
						state.camFollow.y = val2;
						state.isCameraOnForcedPos = true;
					}
				}

			case 'Alt Idle Animation':
				var char:Character = state.dad;
				switch(value1.toLowerCase().trim()) {
					case 'gf' | 'girlfriend':
						char = state.gf;
					case 'boyfriend' | 'bf':
						char = state.boyfriend;
					default:
						var val:Int = Std.parseInt(value1);
						if(Math.isNaN(val)) val = 0;

						switch(val) {
							case 1: char = state.boyfriend;
							case 2: char = state.gf;
						}
				}

				if (char != null)
				{
					char.idleSuffix = value2;
					char.recalculateDanceIdle();
				}

			case 'Screen Shake':
				var valuesArray:Array<String> = [value1, value2];
				var targetsArray:Array<FlxCamera> = [state.camGame, state.camHUD];
				for (i in 0...targetsArray.length) {
					var split:Array<String> = valuesArray[i].split(',');
					var duration:Float = 0;
					var intensity:Float = 0;
					if(split[0] != null) duration = Std.parseFloat(split[0].trim());
					if(split[1] != null) intensity = Std.parseFloat(split[1].trim());
					if(Math.isNaN(duration)) duration = 0;
					if(Math.isNaN(intensity)) intensity = 0;

					if(duration > 0 && intensity != 0) {
						targetsArray[i].shake(intensity, duration);
					}
				}


			case 'Change Character':
			if (ClientPrefs.charsAndBG)
			{
				var charType:Int = 0;
				switch(value1.toLowerCase().trim()) {
					case 'gf' | 'girlfriend':
						charType = 2;
					case 'dad' | 'opponent':
						charType = 1;
					default:
						charType = Std.parseInt(value1);
						if(Math.isNaN(charType)) charType = 0;
				}

				switch(charType) {
					case 0:
						if(state.boyfriend.curCharacter != value2) {
							if(!state.boyfriendMap.exists(value2)) {
								PlayStateCharacters.addCharacterToList(state, value2, charType);
							}

							var lastAlpha:Float = state.boyfriend.alpha;
							state.boyfriend.alpha = 0.00001;
							state.boyfriend = state.boyfriendMap.get(value2);
							state.boyfriend.alpha = lastAlpha;
							if (!value2.startsWith('bf') && !value2.startsWith('boyfriend')) state.iconP1.changeIcon(state.boyfriend.healthIcon);
							else {
								final iconToChange:String = switch (ClientPrefs.bfIconStyle){
									case 'VS Nonsense V2': 'bfnonsense';
									case 'Doki Doki+': 'bfdoki';
									case 'Leather Engine': 'bfleather';
									case "Mic'd Up": 'bfmup';
									case "FPS Plus": 'bffps';
									case "OS 'Engine'": 'bfos';
									default: 'bf';
								}
								if (iconToChange != 'bf')
									state.iconP1.changeIcon(iconToChange);
							}
							if (state.boyfriend.noteskin != null) state.bfNoteskin = state.boyfriend.noteskin;
						}
						state.setOnLuas('boyfriendName', state.boyfriend.curCharacter);

					case 1:
						if(state.dad.curCharacter != value2) {
							if(!state.dadMap.exists(value2)) {
								PlayStateCharacters.addCharacterToList(state, value2, charType);
							}

							var wasGf:Bool = state.dad.curCharacter.startsWith('gf');
							var lastAlpha:Float = state.dad.alpha;
							state.dad.alpha = 0.00001;
							state.dad = state.dadMap.get(value2);
							if(!state.dad.curCharacter.startsWith('gf')) {
								if(wasGf && state.gf != null) {
									state.gf.visible = true;
								}
							} else if(state.gf != null) {
								state.gf.visible = false;
							}
							state.dad.alpha = lastAlpha;
							state.iconP2.changeIcon(state.dad.healthIcon);
							if (ClientPrefs.botTxtStyle == 'VS Impostor') {
								if (state.botplayTxt != null) FlxTween.color(state.botplayTxt, 1, state.botplayTxt.color, FlxColor.fromRGB(state.dad.healthColorArray[0], state.dad.healthColorArray[1], state.dad.healthColorArray[2]));

								if (state.scoreTxt != null && !ClientPrefs.hideHud) FlxTween.color(state.scoreTxt, 1, state.scoreTxt.color, FlxColor.fromRGB(state.dad.healthColorArray[0], state.dad.healthColorArray[1], state.dad.healthColorArray[2]));
							}
							if (ClientPrefs.scoreStyle == 'JS Engine' && !ClientPrefs.hideHud)
								if (state.scoreTxt != null) FlxTween.color(state.scoreTxt, 1, state.scoreTxt.color, FlxColor.fromRGB(state.dad.healthColorArray[0], state.dad.healthColorArray[1], state.dad.healthColorArray[2]));

							if (state.dad.noteskin != null) state.dadNoteskin = state.dad.noteskin;
						}
						state.setOnLuas('dadName', state.dad.curCharacter);

					case 2:
						if(state.gf != null)
						{
							if(state.gf.curCharacter != value2)
							{
								if(!state.gfMap.exists(value2))
								{
									PlayStateCharacters.addCharacterToList(state, value2, charType);
								}

								var lastAlpha:Float = state.gf.alpha;
								state.gf.alpha = 0.00001;
								state.gf = state.gfMap.get(value2);
								state.gf.alpha = lastAlpha;
							}
							state.setOnLuas('gfName', state.gf.curCharacter);
						}
				}
				PlayState.shouldDrainHealth = (state.opponentDrain || (PlayState.opponentChart ? state.boyfriend.healthDrain : state.dad.healthDrain));
				if (!state.opponentDrain && !Math.isNaN((PlayState.opponentChart ? state.boyfriend : state.dad).drainAmount)) state.healthDrainAmount = PlayState.opponentChart ? state.boyfriend.drainAmount : state.dad.drainAmount;
				if (!state.opponentDrain && !Math.isNaN((PlayState.opponentChart ? state.boyfriend : state.dad).drainFloor)) state.healthDrainFloor = PlayState.opponentChart ? state.boyfriend.drainFloor : state.dad.drainFloor;
				state.reloadHealthBarColors(state.dad.healthColorArray, state.boyfriend.healthColorArray);
				if (ClientPrefs.showNotes)
				{
					for (i in state.strumLineNotes.members)
					{
						var noteskin:String = (i.player == 0 ? state.dadNoteskin : state.bfNoteskin);
						if (noteskin != null)
						{
							i.updateNoteSkin(noteskin);
							i.useRGBShader = noteskin.length < 1 && ClientPrefs.enableColorShader;
						}
					}
				}
				if (ClientPrefs.noteColorStyle == 'Char-Based')
				{
					for (group in [state.notes, state.sustainNotes])
						for (note in group){
							if (note == null || !note.alive)
								continue;
							if (ClientPrefs.enableColorShader) note.updateRGBColors();
						}
				}
			}

			case 'Rainbow Eyesore':
				#if SHADERS_ALLOWED
				final val2:Float = (Std.parseFloat(value2) <= 0 || Math.isNaN(Std.parseFloat(value2))) ? 1 : Std.parseFloat(value2);

				if(ClientPrefs.flashing && ClientPrefs.shaders && state.curStep < Std.parseInt(value1)) {
					state.disableTheTripper = false;
					state.disableTheTripperAt = Std.parseInt(value1);
					FlxG.camera.addShader(PlayState.screenshader.shader);
					PlayState.screenshader.waveAmplitude = 1;
					PlayState.screenshader.waveFrequency = 2;
					PlayState.screenshader.waveSpeed = val2 * state.playbackRate;
					PlayState.screenshader.shader.time = new flixel.math.FlxRandom().float(-1e3, 1e3);
					PlayState.screenshader.enabled = true;
				}
				#end
			case 'Popup':
				final title:String = (value1);
				final message:String = (value2);
				FlxG.sound.music.pause();
				PlayStatePlayback.pauseVocals(state);

				lime.app.Application.current.window.alert(message, title);
				FlxG.sound.music.resume();
				PlayStatePlayback.unpauseVocals(state);
			case 'Popup (No Pause)':
				final title:String = (value1);
				final message:String = (value2);

				lime.app.Application.current.window.alert(message, title);

			case 'Change Scroll Speed':
				if (state.songSpeedType == "constant")
					return;
				var val1:Float = Std.parseFloat(value1);
				var val2:Float = Std.parseFloat(value2);
				if(Math.isNaN(val1)) val1 = 1;
				if(Math.isNaN(val2)) val2 = 0;

				var newValue:Float = PlayState.SONG.speed * ClientPrefs.getGameplaySetting('scrollspeed', 1) * val1;

				if(val2 <= 0)
				{
					state.songSpeed = newValue;
				}
				else
				{
					state.songSpeedTween = FlxTween.tween(state, {songSpeed: newValue}, val2 / state.playbackRate, {ease: FlxEase.linear, onComplete:
						function (twn:FlxTween)
						{
							state.songSpeedTween = null;
						}
					});
				}

			case 'Change Song Name':
				if(ClientPrefs.timeBarType == 'Song Name')
				{
					if (value1.length > 1)
						state.timeTxt.text = value1;
					else state.timeTxt.text = state.curSong;
				}

			case 'Set Property':
				try
				{
					var split:Array<String> = value1.split('.');
					if(split.length > 1) {
						FunkinLua.setVarInArray(FunkinLua.getPropertyLoopThingWhatever(split), split[split.length-1], value2);
					} else {
						FunkinLua.setVarInArray(state, value1, value2);
					}
				}
				catch(e:Dynamic)
				{
					var len:Int = e.message.indexOf('\n') + 1;
					if(len <= 0) len = e.message.length;
					#if LUA_ALLOWED
					PlayStateScripts.addTextToDebug(state, 'ERROR ("Set Property" Event) - ' + e.message.substr(0, len), FlxColor.RED);
					#else
					FlxG.log.warn('ERROR ("Set Property" Event) - ' + e.message.substr(0, len));
					#end
				}
		}
		state.stagesFunc(function(stage:BaseStage) stage.eventCalled(eventName, value1, value2, flValue1, flValue2, strumTime));
		state.callOnLuas('onEvent', [eventName, value1, value2, strumTime]);
	}

	public static function sendWindowsNotification(state:PlayState, title:String, desc:String, isEvent:Bool = false) {
		// haha i got them from slushi engine :) (by nael2xd)
		#if (cpp && windows)
		if (PlatformUtil.detectWine() == true){
			trace("Wine detected!");
			return;
		}
		#end
		#if windows
		function getWindowsVersion() {
			var windowsVersions:Map<String, Int> = [
				"Windows 11" => 11,
				"Windows 10" => 10,
				"Windows 8.1" => 8,
				"Windows 8" => 8,
				"Windows 7" => 7,
			];

			var platformLabel = lime.system.System.platformLabel;
			var words = platformLabel.split(" ");
			var windowsIndex = words.indexOf("Windows");
			var result = "";
			if (windowsIndex != -1 && windowsIndex < words.length - 1)
			{
				result = words[windowsIndex] + " " + words[windowsIndex + 1];
			}

			if (windowsVersions.exists(result)) return windowsVersions.get(result);

			return 0;
		}

		var powershellCommand = "powershell -Command \"& {$ErrorActionPreference = 'Stop';"
		+ "$title = '"
		+ desc
		+ "';"
		+ "[Windows.UI.Notifications.ToastNotificationManager, Windows.UI.Notifications, ContentType = WindowsRuntime] > $null;"
		+ "$template = [Windows.UI.Notifications.ToastNotificationManager]::GetTemplateContent([Windows.UI.Notifications.ToastTemplateType]::ToastText01);"
		+ "$toastXml = [xml] $template.GetXml();"
		+ "$toastXml.GetElementsByTagName('text').AppendChild($toastXml.CreateTextNode($title)) > $null;"
		+ "$xml = New-Object Windows.Data.Xml.Dom.XmlDocument;"
		+ "$xml.LoadXml($toastXml.OuterXml);"
		+ "$toast = [Windows.UI.Notifications.ToastNotification]::new($xml);"
		+ "$toast.Tag = 'Test1';"
		+ "$toast.Group = 'Test2';"
		+ "$notifier = [Windows.UI.Notifications.ToastNotificationManager]::CreateToastNotifier('"
		+ title
		+ "');"
		+ "$notifier.Show($toast);}\"";

		if (title != null && title != "" && desc != null && desc != "" && getWindowsVersion() != 7)
			new HiddenProcess(powershellCommand);

		#else
		if (isEvent) {
			#if linux
			PlayStateScripts.addTextToDebug(state, 'Windows Notifications are not currently supported on Linux!', FlxColor.RED);
			return;
			#else
			trace('Windows Notifications are not currently supported on this platform!');
			return;
			#end
		}
		#end
	}
}
