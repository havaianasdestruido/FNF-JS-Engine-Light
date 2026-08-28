package play.helpers;

import backend.ClientPrefs;
import backend.Conductor;
import backend.CoolUtil;

import objects.Character;

import play.PlayState;

// REFACTOR: camera / icon / dance logic extracted from play.PlayState
@:access(play.PlayState)
@:access(backend.MusicBeatState)
class PlayStateCamera
{
	public static function moveCameraSection(state:PlayState):Void {
		if(PlayState.SONG.notes[state.curSection] == null) return;

		if (state.gf != null && PlayState.SONG.notes[state.curSection].gfSection)
		{
			moveCamera(state, 'gf');
			state.callOnLuas('onMoveCamera', ['gf']);
			return;
		}

		if (!PlayState.SONG.notes[state.curSection].mustHitSection)
		{
			moveCamera(state, 'dad');
			state.callOnLuas('onMoveCamera', ['dad']);
		}
		else
		{
			moveCamera(state, 'bf');
			state.callOnLuas('onMoveCamera', ['boyfriend']);
		}
	}

	public static function moveCamera(state:PlayState, focus:String = "bf")
	{
		var char:Character = null;
		var charCamOffset:Array<Float> = [0, 0];
		switch (focus)
		{
			case 'gf' if (state.gf != null):
				char = state.gf;
				charCamOffset = state.girlfriendCameraOffset;

			case 'dad' if (state.dad != null):
				char = state.dad;
				charCamOffset = state.opponentCameraOffset;

			case 'bf' if (state.boyfriend != null):
				char = state.boyfriend;
				charCamOffset = state.boyfriendCameraOffset;

			default:
				return;
		}
		if (char != null) {
			final mid = char.getMidpoint();
			state.camFollow.set(
				mid.x - (char == state.gf ? 0 : char == state.boyfriend ? 100 : -150),
				mid.y - (char == state.gf ? 0 : 100)
			);
			state.camFollow.x += (char == state.boyfriend ? -1 : 1) * char.cameraPosition[0] + charCamOffset[0];
			state.camFollow.y += char.cameraPosition[1] + charCamOffset[1];
		}
	}

	public static function snapCamFollowToPos(state:PlayState, x:Float, y:Float) {
		state.camFollow.set(x, y);
		state.camFollowPos.setPosition(x, y);
	}

	public static function characterBopper(state:PlayState, beat:Int):Void
	{
		if (state.gf != null && beat % Math.round(state.gfSpeed * state.gf.danceEveryNumBeats) == 0 && !state.gf.getAnimationName().startsWith('sing') && !state.gf.stunned)
			state.gf.dance();
		if (state.boyfriend != null && beat % state.boyfriend.danceEveryNumBeats == 0 && !state.boyfriend.getAnimationName().startsWith('sing') && !state.boyfriend.stunned)
			state.boyfriend.dance();
		if (state.dad != null && beat % state.dad.danceEveryNumBeats == 0 && !state.dad.getAnimationName().startsWith('sing') && !state.dad.stunned)
			state.dad.dance();
	}

	public static function playerDance(state:PlayState):Void
	{
		var char = (PlayState.opponentChart ? state.dad : state.boyfriend);
		var anim:String = char.getAnimationName();
		if(char.holdTimer > Conductor.stepCrochet * (0.0011 #if FLX_PITCH / FlxG.sound.music.pitch #end) * char.singDuration * state.singDurMult && anim.startsWith('sing') && !anim.endsWith('miss'))
			char.dance();
	}

	public static function doTwist(state:PlayState)
	{
		state.twistShit = state.twistAmount * state.camTwistIntensity * (!state.twisted ? 1 : -1);
		state.twisted = !state.twisted;

		for (i in [state.camHUD, state.camGame])
		{
			FlxTween.cancelTweensOf(i);
			i.angle = state.twistShit;
			FlxTween.tween(i, {angle: 0}, 45 / Conductor.bpm * state.gfSpeed / state.playbackRate, {ease: FlxEase.circOut});
		}
	}

	public static function updateIconsScale(state:PlayState, elapsed:Float)
	{
		switch (ClientPrefs.iconBounceType) {
			case 'Old Psych':
				for (i in [state.iconP1, state.iconP2])
					i.setGraphicSize(Std.int(FlxMath.lerp(i.frameWidth, i.width, CoolUtil.boundTo(1 - (elapsed * 30 * state.playbackRate), 0, 1))),
					Std.int(FlxMath.lerp(i.frameHeight, i.height, CoolUtil.boundTo(1 - (elapsed * 30 * state.playbackRate), 0, 1))));

			case 'Strident Crisis':
				state.iconSizeResetTime = Math.max(0, state.iconSizeResetTime - elapsed);
				var iconLerp = FlxEase.quartIn(state.iconSizeResetTime / 0.5);

				for (i in [state.iconP1, state.iconP2])
					i.setGraphicSize(Std.int(FlxMath.lerp(i.frameWidth, i.width, iconLerp)),
					Std.int(FlxMath.lerp(i.frameHeight, i.height, iconLerp)));

			case 'Dave and Bambi':
				state.iconSizeResetTime = Math.max(0, state.iconSizeResetTime - elapsed / state.playbackRate);
				var iconLerp = FlxEase.quartIn(state.iconSizeResetTime / 0.8);

				for (i in [state.iconP1, state.iconP2])
					i.setGraphicSize(Std.int(FlxMath.lerp(i.frameWidth, i.width, iconLerp)),
					Std.int(FlxMath.lerp(i.frameHeight, i.height, iconLerp)));

			case 'Plank Engine':
				final funnyBeat = (Conductor.songPosition / 1000) * (Conductor.bpm / 60);

				for (i in [state.iconP1, state.iconP2])
					i.offset.y = Math.abs(Math.sin(funnyBeat * Math.PI))  * 16 - 4;

			case 'New Psych', 'VS Steve':
				for (i in [state.iconP1, state.iconP2]) {
					final mult:Float = FlxMath.lerp(1, i.scale.x, CoolUtil.boundTo(1 - (elapsed * 9 * state.playbackRate), 0, 1));
					i.scale.set(mult, mult);
				}
		}

		for (i in [state.iconP1, state.iconP2]) {
			if (ClientPrefs.iconBounceType == 'Golden Apple') i.centerOffsets();
			i.updateHitbox();
		}
	}

	public static function updateIconsPosition(state:PlayState)
	{
		if (ClientPrefs.smoothHealth)
		{
			state.percent = 1 - (ClientPrefs.smoothHPBug ? (state.displayedHealth / state.maxHealth) : (FlxMath.bound(state.displayedHealth, 0, state.maxHealth) / state.maxHealth));

			state.iconP1.x = 0 + state.healthBar.x + (state.healthBar.width * state.percent) + (150 * state.iconP1.scale.x - 150) / 2 - PlayState.iconOffset;
			state.iconP2.x = 0 + state.healthBar.x + (state.healthBar.width * state.percent) - (150 * state.iconP2.scale.x) / 2 - PlayState.iconOffset * 2;
		}
		else //mb forgot to include this
		{
			state.center = state.healthBar.x + (state.healthBar.width * (FlxMath.remapToRange(state.healthBar.percent, 0, 100, 100, 0) * 0.01));
			state.iconP1.x = state.center + (150 * state.iconP1.scale.x - 150) / 2 - PlayState.iconOffset;
			state.iconP2.x = state.center - (150 * state.iconP2.scale.x) / 2 - PlayState.iconOffset * 2;
		}
	}

	public static function bopIcons(state:PlayState, ?bopBF:Bool = false)
	{
		switch(ClientPrefs.iconBounceType) {
			case 'Dave and Bambi':
				final funny:Float = Math.max(Math.min(state.healthBar.value,(state.maxHealth*0.95)),0.1);

				//health icon bounce but epic
				if (!PlayState.opponentChart)
				{
					state.iconP1.setGraphicSize(Std.int(state.iconP1.width + (50 * (funny + 0.1))),Std.int(state.iconP1.height - (25 * funny)));
					state.iconP2.setGraphicSize(Std.int(state.iconP2.width + (50 * ((2 - funny) + 0.1))),Std.int(state.iconP2.height - (25 * ((2 - funny) + 0.1))));
				} else {
					state.iconP2.setGraphicSize(Std.int(state.iconP2.width + (50 * funny)),Std.int(state.iconP2.height - (25 * funny)));
					state.iconP1.setGraphicSize(Std.int(state.iconP1.width + (50 * ((2 - funny) + 0.1))),Std.int(state.iconP1.height - (25 * ((2 - funny) + 0.1))));
				}
				state.iconSizeResetTime = 0.8;

			case 'Old Psych':
				for (i in [state.iconP1, state.iconP2])
					i.setGraphicSize(Std.int(i.width + 30));

			case 'Strident Crisis':
				final funny:Float = (state.healthBar.percent * 0.01) + 0.01;

				//health icon bounce but epic
				state.iconP1.setGraphicSize(Std.int(state.iconP1.width + (50 * (2 + funny))),Std.int(state.iconP2.height - (25 * (2 + funny))));
				state.iconP2.setGraphicSize(Std.int(state.iconP2.width + (50 * (2 - funny))),Std.int(state.iconP2.height - (25 * (2 - funny))));

				FlxTween.angle(state.iconP1, -15, 0, Conductor.crochet / 1300 * state.gfSpeed, {ease: FlxEase.quadOut});
				FlxTween.angle(state.iconP2, 15, 0, Conductor.crochet / 1300 * state.gfSpeed, {ease: FlxEase.quadOut});

				for (i in [state.iconP1, state.iconP2]) {
					i.scale.set(1.1, 0.8);

					FlxTween.tween(i, {'scale.x': 1, 'scale.y': 1}, Conductor.crochet / 1250 * state.gfSpeed / state.playbackRate, {ease: FlxEase.quadOut});
				}
				state.iconSizeResetTime = 0.5;

			case 'Plank Engine':
				for (i in [state.iconP1, state.iconP2]) {
					i.scale.set(1.3, 0.75);
					FlxTween.cancelTweensOf(i);
					FlxTween.tween(i, {"scale.x": 1, "scale.y": 1}, Conductor.crochet / 1000 / state.playbackRate, {ease: FlxEase.backOut});
				}
				if (state.curBeat % 4 == 0) {
					state.iconP1.offset.x = 10;
					state.iconP2.offset.x = -10;
					state.iconP1.angle = -15;
					state.iconP2.angle = 15;
					for (i in [state.iconP1, state.iconP2])
						FlxTween.tween(i, {"offset.x": 0, angle: 0}, Conductor.crochet / 1000 / state.playbackRate, {ease: FlxEase.expoOut});
				}
			case 'New Psych':
				for (i in [state.iconP1, state.iconP2])
					i.scale.set(1.2, 1.2);

			case 'Golden Apple':
				state.curBeat % (state.gfSpeed * 2) == 0 * state.playbackRate ? {
					state.iconP1.scale.set(1.1, 0.8);
					state.iconP2.scale.set(1.1, 1.3);

					FlxTween.angle(state.iconP1, -15, 0, Conductor.crochet / 1300 / state.playbackRate * state.gfSpeed, {ease: FlxEase.quadOut});
					FlxTween.angle(state.iconP2, 15, 0, Conductor.crochet / 1300 / state.playbackRate * state.gfSpeed, {ease: FlxEase.quadOut});
				} : {
					state.iconP1.scale.set(1.1, 1.3);
					state.iconP2.scale.set(1.1, 0.8);

					FlxTween.angle(state.iconP2, -15, 0, Conductor.crochet / 1300 / state.playbackRate * state.gfSpeed, {ease: FlxEase.quadOut});
					FlxTween.angle(state.iconP1, 15, 0, Conductor.crochet / 1300 / state.playbackRate * state.gfSpeed, {ease: FlxEase.quadOut});
				}

				for (i in [state.iconP1, state.iconP2])
					FlxTween.tween(i, {'scale.x': 1, 'scale.y': 1}, Conductor.crochet / 1250 / state.playbackRate * state.gfSpeed, {ease: FlxEase.quadOut});

			case 'VS Steve':
				state.curBeat % (state.gfSpeed * 2) == 0 ?
				{
					state.iconP1.scale.set(1.1, 0.8);
					state.iconP2.scale.set(1.1, 1.3);
				} : {
					state.iconP1.scale.set(1.1, 1.3);
					state.iconP2.scale.set(1.1, 0.8);
					FlxTween.angle(state.iconP1, -15, 0, Conductor.crochet / 1300 * state.gfSpeed / state.playbackRate, {ease: FlxEase.quadOut});
					FlxTween.angle(state.iconP2, 15, 0, Conductor.crochet / 1300 * state.gfSpeed / state.playbackRate, {ease: FlxEase.quadOut});

				}

				for (i in [state.iconP1, state.iconP2])
					FlxTween.tween(i, {'scale.x': 1, 'scale.y': 1}, Conductor.crochet / 1250 / state.playbackRate * state.gfSpeed, {ease: FlxEase.quadOut});
		}
		state.iconP1.updateHitbox();
		state.iconP2.updateHitbox();
	}

	// REFACTOR: tankman ascend sequence extracted from PlayState.stepHit
	public static function tankmanStep(state:PlayState)
	{
		if (state.curStep >= 896 && state.curStep <= 1152) moveCameraSection(state);
		switch (state.curStep)
		{
			case 896:
				{
					if (!PlayState.opponentChart) {
							state.opponentStrums.forEachAlive(function(daNote:FlxSprite)
							{
								FlxTween.tween(daNote, {alpha: 0}, 0.5, {ease: FlxEase.expoOut,});
							});
						}
					for (i in [state.EngineWatermark, state.timeBarBG, state.timeTxt, state.timeBarBG, state.scoreTxt, state.healthBarBG, state.healthBar, state.iconP1, state.iconP2]) {
						if (i != null) FlxTween.tween(i, {alpha: 0}, 0.5, {ease: FlxEase.expoOut});
					}
					state.dad.velocity.y = -35;
				}
			case 906:
				{
					if (!PlayState.opponentChart) {
					state.playerStrums.forEachAlive(function(daNote:FlxSprite)
					{
						FlxTween.tween(daNote, {alpha: 0}, 0.5, {ease: FlxEase.expoOut,});
					});
					} else {
					state.opponentStrums.forEachAlive(function(daNote:FlxSprite)
					{
						FlxTween.tween(daNote, {alpha: 0}, 0.5, {ease: FlxEase.expoOut,});
					});
					}
				}
			case 1020:
				{
					if (!PlayState.opponentChart) {
					state.playerStrums.forEachAlive(function(daNote:FlxSprite)
					{
						FlxTween.tween(daNote, {alpha: 1}, 0.5, {ease: FlxEase.expoOut,});
					});
					}
				}
			case 1024:
					if (PlayState.opponentChart) {
					state.playerStrums.forEachAlive(function(daNote:FlxSprite)
					{
						FlxTween.tween(daNote, {alpha: 0}, 0.5, {ease: FlxEase.expoOut,});
					});
					}
				state.dad.velocity.y = 0;
				state.boyfriend.velocity.y = -33.5;
			case 1148:
				{
					if (PlayState.opponentChart) {
					state.playerStrums.forEachAlive(function(daNote:FlxSprite)
					{
						FlxTween.tween(daNote, {alpha: 1}, 0.5, {ease: FlxEase.expoOut,});
					});
					}
				}
			case 1151:
				state.cameraSpeed = 100;
			case 1152:
				{
					FlxG.camera.flash(FlxColor.WHITE, 1);
					for (i in [state.EngineWatermark, state.timeBarBG, state.timeTxt, state.timeBarBG, state.scoreTxt, state.healthBarBG, state.healthBar, state.iconP1, state.iconP2]) {
						if (i != null) FlxTween.tween(i, {alpha: 1}, 0.5, {ease: FlxEase.expoOut});
					}
					state.opponentStrums.forEachAlive(function(daNote:FlxSprite)
					{
						FlxTween.tween(daNote, {alpha: 1}, 0.5, {ease: FlxEase.expoOut,});
					});
					state.dad.x = 100;
					state.dad.y = 280;
					state.boyfriend.x = 810;
					state.boyfriend.y = 450;
					state.dad.velocity.y = 0;
					state.boyfriend.velocity.y = 0;
				}
			case 1153:
				state.cameraSpeed = 1;
		}
	}
}
