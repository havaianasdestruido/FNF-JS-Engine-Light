package play.helpers;

import backend.ClientPrefs;
import backend.Conductor;

import objects.CreditsPopUp;

import play.BaseStage;
import play.BaseStage.Countdown;
import play.PlayState;

import play.helpers.PlayStateCamera;
import play.helpers.PlayStateNoteHelpers;
import play.helpers.PlayStatePlayback;

// REFACTOR: imports for relocated root classes
import data.Song;
import objects.Note;

// REFACTOR: countdown logic extracted from play.PlayState
@:access(play.PlayState)
@:access(backend.MusicBeatState)
class PlayStateCountdown
{
	public static function cacheCountdown(state:PlayState)
	{
		var introAssets:Map<String, Array<String>> = new Map<String, Array<String>>();
		var introImagesArray:Array<String> = switch(PlayState.stageUI) {
			case "pixel": ['${PlayState.stageUI}UI/ready-pixel', '${PlayState.stageUI}UI/set-pixel', '${PlayState.stageUI}UI/date-pixel'];
			case "normal": ["ready", "set" ,"go"];
			default: ['${PlayState.stageUI}UI/ready', '${PlayState.stageUI}UI/set', '${PlayState.stageUI}UI/go'];
		}
		introAssets.set(PlayState.stageUI, introImagesArray);
		var introAlts:Array<String> = introAssets.get(PlayState.stageUI);
		for (asset in introAlts) Paths.image(asset);

		state.intro3 = new FlxSound().loadEmbedded(Paths.sound('intro3' + state.introSoundsSuffix));
		state.intro2 = new FlxSound().loadEmbedded(Paths.sound('intro2' + state.introSoundsSuffix));
		state.intro1 = new FlxSound().loadEmbedded(Paths.sound('intro1' + state.introSoundsSuffix));
		state.introGo = new FlxSound().loadEmbedded(Paths.sound('introGo' + state.introSoundsSuffix));
	}

	public static function startCountdown(state:PlayState):Void
	{
		if(state.startedCountdown) {
			state.callOnLuas('onStartCountdown');
			return;
		}

		state.inCutscene = false;
		var ret:Dynamic = state.callOnLuas('onStartCountdown');

		if (PlayState.SONG.song.toLowerCase() == 'anti-cheat-song')
		{
			final secretsong:FlxSprite = new FlxSprite().loadGraphic(Paths.image('secretSong'));
			secretsong.antialiasing = ClientPrefs.globalAntialiasing;
			secretsong.scrollFactor.set();
			secretsong.setGraphicSize(Std.int(secretsong.width / FlxG.camera.zoom));
			secretsong.updateHitbox();
			secretsong.screenCenter();
			secretsong.cameras = [state.camGame];
			state.add(secretsong);
		}

		if(ret != FunkinLua.Function_Stop) {
			if (state.skipCountdown || PlayState.startOnTime > 0) state.skipArrowStartTween = true;

			PlayStateNoteHelpers.generateStaticArrows(state, 0);
			PlayStateNoteHelpers.generateStaticArrows(state, 1);
			for (i in 0...state.opponentStrums.length) {
				state.setOnLuas('defaultOpponentStrumX' + i, state.opponentStrums.members[i].x);
				state.setOnLuas('defaultOpponentStrumY' + i, state.opponentStrums.members[i].y);
				if(PlayState.bothSides) state.opponentStrums.members[i].visible = false;
			}
			for (i in 0...state.playerStrums.length) {
				state.setOnLuas('defaultPlayerStrumX' + i, state.playerStrums.members[i].x);
				state.setOnLuas('defaultPlayerStrumY' + i, state.playerStrums.members[i].y);
			}

			state.startedCountdown = state.mobileControls.visible = true;
			Conductor.songPosition = -Conductor.crochet * 5;
			state.setOnLuas('startedCountdown', true);
			state.callOnLuas('onCountdownStarted');

			var swagCounter:Int = 0;

			if(PlayState.startOnTime < 0) PlayState.startOnTime = 0;

			if (PlayState.startOnTime > 0) {
				PlayStateNoteHelpers.clearNotesBefore(state, PlayState.startOnTime);
				PlayStatePlayback.setSongTime(state, PlayState.startOnTime - 350);
				return;
			}
			else if (state.skipCountdown)
			{
				PlayStatePlayback.setSongTime(state, 0);
				return;
			}

			state.startTimer = new FlxTimer().start(Conductor.crochet / 1000 / state.playbackRate, function(tmr:FlxTimer)
			{
				if (ClientPrefs.charsAndBG) PlayStateCamera.characterBopper(state, tmr.loopsLeft);

				var introAssets:Map<String, Array<String>> = new Map<String, Array<String>>();
				var introImagesArray:Array<String> = switch(PlayState.stageUI) {
					case "pixel": ['${PlayState.stageUI}UI/ready-pixel', '${PlayState.stageUI}UI/set-pixel', '${PlayState.stageUI}UI/date-pixel'];
					case "normal": ["ready", "set" ,"go"];
					default: ['${PlayState.stageUI}UI/ready', '${PlayState.stageUI}UI/set', '${PlayState.stageUI}UI/go'];
				}
				introAssets.set(PlayState.stageUI, introImagesArray);

				var introAlts:Array<String> = introAssets.get(PlayState.stageUI);
				var antialias:Bool = ClientPrefs.globalAntialiasing;
				if(PlayState.isPixelStage) {
					introAlts = introAssets.get('pixel');
					antialias = false;
				}

				var tick:Countdown = THREE;

				if (swagCounter > 0 && swagCounter < 4) createCountdownSprite(state, introAlts[swagCounter-1], antialias);

				switch (swagCounter)
				{
					case 0:
						state.intro3.volume = FlxG.sound.volume;
						state.intro3.play();
						tick = THREE;
					case 1:
						state.intro2.volume = FlxG.sound.volume;
						state.intro2.play();
						tick = TWO;
					case 2:
						state.intro1.volume = FlxG.sound.volume;
						state.intro1.play();
						tick = ONE;
					case 3:
						state.introGo.volume = FlxG.sound.volume;
						state.introGo.play();
						tick = GO;
						if (ClientPrefs.tauntOnGo && ClientPrefs.charsAndBG)
						{
							final charsToHey = [state.dad, state.boyfriend, state.gf];
							for (char in charsToHey)
							{
								if(char != null)
								{
									if (char.animOffsets.exists('hey') || char.animOffsets.exists('cheer'))
									{
										char.playAnim(char.animOffsets.exists('hey') ? 'hey' : 'cheer', true);
										char.specialAnim = true;
										char.heyTimer = 0.6;
									} else if (char.animOffsets.exists('singUP') && (!char.animOffsets.exists('hey') || !char.animOffsets.exists('cheer')))
									{
										char.playAnim('singUP', true);
										char.specialAnim = true;
										char.heyTimer = 0.6;
									}
								}
							}
						}
					case 4:
					tick = START;
					if (PlayState.SONG.songCredit != null && PlayState.SONG.songCredit.length > 0)
					{
						var creditsPopup:CreditsPopUp = new CreditsPopUp(FlxG.width, 200, PlayState.SONG.song, PlayState.SONG.songCredit);
						creditsPopup.cameras = [state.camHUD];
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
				}

				for (group in [state.notes, state.sustainNotes]) group.forEachAlive(function(note:Note) {
					if(ClientPrefs.opponentStrums || !ClientPrefs.opponentStrums || PlayState.middleScroll || !note.mustPress)
					{
						note.alpha *= 0.35;
					}
					if(ClientPrefs.opponentStrums || !ClientPrefs.opponentStrums || note.mustPress)
					{
						note.copyAlpha = false;
						note.alpha = note.multAlpha;
						if(PlayState.middleScroll && !note.mustPress) {
							note.alpha *= 0.35;
						}
					}
				});
				state.stagesFunc(function(stage:BaseStage) stage.countdownTick(tick, swagCounter));
				state.callOnLuas('onCountdownTick', [swagCounter]);

				swagCounter += 1;
			}, 5);
		}
	}

	inline public static function createCountdownSprite(state:PlayState, image:String, antialias:Bool):FlxSprite
	{
		var spr:FlxSprite = new FlxSprite().loadGraphic(Paths.image(image));
		spr.cameras = [state.camHUD];
		spr.scrollFactor.set();
		spr.updateHitbox();

		if (PlayState.isPixelStage)
			spr.setGraphicSize(Std.int(spr.width * PlayState.daPixelZoom));

		spr.screenCenter();
		spr.antialiasing = antialias;
		state.insert(state.members.indexOf(state.notes), spr);
		FlxTween.tween(spr, {"scale.x": 0, "scale.y": 0, alpha: 0}, Conductor.crochet / 1000 / state.playbackRate, {
			ease: FlxEase.cubeInOut,
			onComplete: function(twn:FlxTween)
			{
				state.remove(spr);
				spr.destroy();
			}
		});
		return spr;
	}
}
