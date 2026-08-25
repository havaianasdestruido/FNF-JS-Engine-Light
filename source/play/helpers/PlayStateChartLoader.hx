package play.helpers;

import backend.ClientPrefs;
import backend.Conductor;
import backend.CoolUtil;

import data.Section.SwagSection;
import data.Song;

import editors.ChartingState;

import objects.Character;
import objects.Character.Boyfriend;
import objects.Note;
import objects.Note.EventNote;
import objects.Note.PreloadedChartNote;

import openfl.system.System;

import play.PlayState;

// REFACTOR: imports for relocated root classes
import backend.MusicBeatState;

// REFACTOR: chart parsing extracted from play.PlayState.generateSong
class PlayStateChartLoader
{
	public static function generateSong(state:PlayState, ?startingPoint:Float = 0):Void
	{
		var offsetStart = (startingPoint > 0 ? 500 : 0);
		final startTime = haxe.Timer.stamp();

		state.songSpeedType = ClientPrefs.getGameplaySetting('scrolltype','multiplicative');

		switch(state.songSpeedType)
		{
			case "multiplicative":
				state.songSpeed = PlayState.SONG.speed * ClientPrefs.getGameplaySetting('scrollspeed', 1);
			case "constant":
				state.songSpeed = ClientPrefs.getGameplaySetting('scrollspeed', 1);
		}

		state.ogSongSpeed = state.songSpeed;

		Conductor.changeBPM(PlayState.SONG.bpm);

		state.curSong = PlayState.SONG.song;

		var diff:String = (PlayState.SONG.specialAudioName.length > 1 ? PlayState.SONG.specialAudioName : CoolUtil.difficultyString()).toLowerCase();

		if (PlayState.SONG.windowName != null && PlayState.SONG.windowName != '')
			MusicBeatState.windowNamePrefix = PlayState.SONG.windowName;

		state.vocals = new FlxSound();
		state.opponentVocals = new FlxSound();
		try
		{
			if (PlayState.SONG.needsVoices)
			{
				var playerVocals = Paths.voices(state.curSong, diff, (state.boyfriend.vocalsFile == null || state.boyfriend.vocalsFile.length < 1) ? "Player" : state.boyfriend.vocalsFile);
				state.vocals.loadEmbedded(playerVocals != null ? playerVocals : Paths.voices(state.curSong, diff));

				var oppVocals = Paths.voices(state.curSong, diff, (state.dad.vocalsFile == null || state.dad.vocalsFile.length < 1) ? "Opponent" : state.dad.vocalsFile);
				if(oppVocals != null) state.opponentVocals.loadEmbedded(oppVocals);
			}
		}
		catch(e) {}

		state.vocals.pitch = state.opponentVocals.pitch = state.playbackRate;
		FlxG.sound.list.add(state.vocals);
		FlxG.sound.list.add(state.opponentVocals);
		state.inst = new FlxSound();
		try
		{
			state.inst.loadEmbedded(Paths.inst(PlayState.SONG.song, diff));
		}
		catch (e:Dynamic) {}
		FlxG.sound.list.add(state.inst);

		final noteData:Array<SwagSection> = PlayState.SONG.notes;

		var eventsToLoad:String = (PlayState.SONG.specialEventsName.length > 1 ? PlayState.SONG.specialEventsName : CoolUtil.difficultyString()).toLowerCase();

		final songName:String = Paths.formatToSongPath(PlayState.SONG.song);
		final file:String = Paths.songEvents(songName, eventsToLoad);
		#if MODS_ALLOWED
		if (FileSystem.exists(Paths.json(file)) || FileSystem.exists(Paths.modsJson(file))) {
		#else
		if (OpenFlAssets.exists(file)) {
		#end
			var eventsData:Array<Dynamic> = Song.loadFromJson(Paths.songEvents(songName, eventsToLoad, true), songName).events;
			for (event in eventsData) //Event Notes
			{
				for (i in 0...event[1].length)
				{
					if (event[0] >= startingPoint + offsetStart)
					{
						var newEventNote:Array<Dynamic> = [event[0], event[1][i][0], event[1][i][1], event[1][i][2]];
						var subEvent:EventNote = {
							strumTime: newEventNote[0] + ClientPrefs.noteOffset,
							event: newEventNote[1],
							value1: newEventNote[2],
							value2: newEventNote[3]
						};
						state.eventNotes.push(subEvent);
						PlayStateEvents.eventPushed(state, subEvent);
					}
				}
			}
		}
		for (event in PlayState.SONG.events) //Event Notes
		{
			for (i in 0...event[1].length)
			{
				if (event[0] >= startingPoint + offsetStart)
				{
					var newEventNote:Array<Dynamic> = [event[0], event[1][i][0], event[1][i][1], event[1][i][2]];
					var subEvent:EventNote = {
						strumTime: newEventNote[0] + ClientPrefs.noteOffset,
						event: newEventNote[1],
						value1: newEventNote[2],
						value2: newEventNote[3]
					};
					state.eventNotes.push(subEvent);
					PlayStateEvents.eventPushed(state, subEvent);
				}
			}
		}
		var currentBPMLol:Float = Conductor.bpm;
		var stepCrochet:Float = 15000 / currentBPMLol;
		var currentMultiplier:Float = 1;
		var gottaHitNote:Bool = false;
		var swagNote:PreloadedChartNote;
		var ghostNotesCleared:Int = 0;
		// TODO: Optimize and clean up this mess, maybe split into functions
		// this is absolute spaghetti code
		for (section in noteData) {
			if (section.changeBPM) {
				currentBPMLol = section.bpm;
				stepCrochet = 15000 / currentBPMLol;
			}

			for (i in 0...section.sectionNotes.length)
			{
				final songNotes:Array<Dynamic> = section.sectionNotes[i];

				if (songNotes[1] == -1)
					continue;

				if (songNotes[0] >= startingPoint + offsetStart) {
					final daStrumTime:Float = songNotes[0];
					var daNoteData:Int = 0;
					if (!state.assignedFirstData && state.oneK)
					{
						state.firstNoteData = Std.int(songNotes[1] % 4);
						state.assignedFirstData = true;
					}
					if (!state.randomMode && !state.flip && !state.stairs && !state.waves) daNoteData = Std.int(songNotes[1] % 4);

					if (state.oneK) daNoteData = state.firstNoteData;

					if (state.randomMode) daNoteData = FlxG.random.int(0, 3);

					if (state.flip) daNoteData = Std.int(Math.abs((songNotes[1] % 4) - 3));

					if (state.stairs && !state.waves) {
						daNoteData = state.stair % 4;
						state.stair++;
					}

					if (state.waves) {
						switch (state.stair % 6) {
							case 0 | 1 | 2 | 3:
								daNoteData = state.stair % 6;
							case 4:
								daNoteData = 2;
							case 5:
								daNoteData = 1;
						}
						state.stair++;
					}

					gottaHitNote = (!PlayState.opponentChart ? songNotes[1] < 4 : songNotes[1] > 3) ? section.mustHitSection : !section.mustHitSection;

					if ((PlayState.bothSides || gottaHitNote) && songNotes[3] != 'Hurt Note') {
						state.totalNotes += 1;
					}
					if (!PlayState.bothSides && !gottaHitNote) {
						state.opponentNoteTotal += 1;
					}

					if (daStrumTime >= state.charChangeTimes[0])
					{
						switch (state.charChangeTypes[0])
						{
							case 0:
								var boyfriendToGrab:Boyfriend = state.boyfriendMap.get(state.charChangeNames[0]);
								if (boyfriendToGrab != null) state.bfNoteskin = boyfriendToGrab.noteskin;
							case 1:
								var dadToGrab:Character = state.dadMap.get(state.charChangeNames[0]);
								if (dadToGrab != null) state.dadNoteskin = dadToGrab.noteskin;
						}
						state.charChangeTimes.shift();
						state.charChangeNames.shift();
						state.charChangeTypes.shift();
					}

					if (state.multiChangeEvents[0].length > 0 && daStrumTime >= state.multiChangeEvents[0][0])
					{
						currentMultiplier = state.multiChangeEvents[1][0];
						state.multiChangeEvents[0].shift();
						state.multiChangeEvents[1].shift();
					}

					swagNote = {
						strumTime: daStrumTime,
						noteData: daNoteData,
						mustPress: PlayState.bothSides || gottaHitNote,
						oppNote: (PlayState.opponentChart ? gottaHitNote : !gottaHitNote),
						noteType: songNotes[3],
						animSuffix: (songNotes[3] == 'Alt Animation' || section.altAnim ? '-alt' : ''),
						noteskin: (gottaHitNote ? state.bfNoteskin : state.dadNoteskin),
						gfNote: songNotes[3] == 'GF Sing' || (section.gfSection && songNotes[1] < 4),
						noAnimation: songNotes[3] == 'No Animation',
						noMissAnimation: songNotes[3] == 'No Animation',
						sustainLength: songNotes[2],
						hitHealth: 0.023,
						missHealth: songNotes[3] != 'Hurt Note' ? 0.0475 : 0.3,
						wasHit: false,
						hitCausesMiss: songNotes[3] == 'Hurt Note',
						multSpeed: 1,
						multAlpha: 1,
						noteDensity: currentMultiplier,
						ignoreNote: songNotes[3] == 'Hurt Note' && gottaHitNote
					};
					if (swagNote.noteskin.length > 0 && !Paths.noteSkinFramesMap.exists(swagNote.noteskin)) inline Paths.initNote(swagNote.noteskin);

					if(!Std.isOfType(songNotes[3], String)) swagNote.noteType = ChartingState.noteTypeList[songNotes[3]]; //Backward compatibility + compatibility with Week 7 charts

					if(Std.isOfType(songNotes[3], Bool)) swagNote.animSuffix = (songNotes[3] || section.altAnim ? '-alt' : ''); //Compatibility with charts made by SNIFF

					if (!state.noteTypeMap.exists(swagNote.noteType)) {
						state.noteTypeMap.set(swagNote.noteType, true);
					}

					state.unspawnNotes.push(swagNote);

					if (state.jackingtime > 0) {
						for (j in 0...Std.int(state.jackingtime)) {
							final jackNote:PreloadedChartNote = {
								strumTime: swagNote.strumTime + (15000 / PlayState.SONG.bpm) * (j + 1),
								noteData: swagNote.noteData,
								mustPress: swagNote.mustPress,
								oppNote: swagNote.oppNote,
								noteType: swagNote.noteType,
								animSuffix: (songNotes[3] == 'Alt Animation' || section.altAnim ? '-alt' : ''),
								noteskin: (gottaHitNote ? state.bfNoteskin : state.dadNoteskin),
								gfNote: swagNote.gfNote,
								isSustainNote: false,
								isSustainEnd: false,
								parentST: 0,
								hitHealth: swagNote.hitHealth,
								missHealth: swagNote.missHealth,
								wasHit: false,
								multSpeed: 1,
								multAlpha: 1,
								noteDensity: currentMultiplier,
								hitCausesMiss: swagNote.hitCausesMiss,
								ignoreNote: swagNote.ignoreNote
							};
							state.unspawnNotes.push(jackNote);
						}
					}

					if (swagNote.sustainLength < 1) continue;

					final roundSus:Int = Math.round(swagNote.sustainLength / stepCrochet);
					if (roundSus > 0) {
						for (susNote in 0...roundSus + 1) {
							final sustainNote:PreloadedChartNote = {
								strumTime: daStrumTime + (stepCrochet * susNote),
								noteData: daNoteData,
								mustPress: PlayState.bothSides || gottaHitNote,
								oppNote: (PlayState.opponentChart ? gottaHitNote : !gottaHitNote),
								noteType: songNotes[3],
								animSuffix: (songNotes[3] == 'Alt Animation' || section.altAnim ? '-alt' : ''),
								noteskin: (gottaHitNote ? state.bfNoteskin : state.dadNoteskin),
								gfNote: songNotes[3] == 'GF Sing' || (section.gfSection && songNotes[1] < 4),
								noAnimation: songNotes[3] == 'No Animation',
								isSustainNote: true,
								isSustainEnd: susNote == roundSus,
								parentST: swagNote.strumTime,
								parentSL: swagNote.sustainLength,
								hitHealth: 0.023,
								missHealth: songNotes[3] != 'Hurt Note' ? 0.0475 : 0.1,
								wasHit: false,
								multSpeed: 1,
								multAlpha: 1,
								noteDensity: currentMultiplier,
								hitCausesMiss: songNotes[3] == 'Hurt Note',
								ignoreNote: songNotes[3] == 'Hurt Note' && swagNote.mustPress
							};
							state.unspawnNotes.push(sustainNote);
						}
					}
				} else {
					final gottaHitNote:Bool = ((songNotes[1] < 4 && !PlayState.opponentChart)
						|| (songNotes[1] > 3 && PlayState.opponentChart) ? section.mustHitSection : !section.mustHitSection);
					if ((PlayState.bothSides || gottaHitNote) && songNotes[3] != 'Hurt Note') {
						state.totalNotes += 1;
						state.combo += 1;
						state.totalNotesPlayed += 1;
					}
					if (!PlayState.bothSides && !gottaHitNote) {
						state.opponentNoteTotal += 1;
						state.enemyHits += 1;
					}
				}
			}
			PlayState.sectionsLoaded += 1;
			state.notesLoadedRN += section.sectionNotes.length;
			#if debug
			Sys.print('\rSection ${PlayState.sectionsLoaded} loaded! (' + state.notesLoadedRN + ' notes)');
			#end
		}

		state.bfNoteskin = state.boyfriend.noteskin;
		state.dadNoteskin = state.dad.noteskin;

		if (ClientPrefs.noteColorStyle == 'Char-Based')
		{
			for (group in [state.notes, state.sustainNotes])
				for (note in group){
					if (note == null || !note.alive)
						continue;
					if (ClientPrefs.enableColorShader) note.updateRGBColors();
				}
		}
		// trace('["${SONG.song.toUpperCase()}" CHART INFO]: Ghost Notes Cleared: $ghostNotesCleared');
		state.unspawnNotes.sort((a, b) -> PlayStateEvents.sortByTime(state, a, b));
		state.eventNotes.sort((a, b) -> PlayStateEvents.sortByTime(state, a, b));
		state.generatedMusic = true;

		PlayState.sectionsLoaded = 0;

		final endTime = haxe.Timer.stamp();

		System.gc();

		final elapsedTime = endTime - startTime;

		#if debug
		Sys.print('\nDone! \n\nTime taken: ' + CoolUtil.formatTime(elapsedTime * 1000) + "\nAverage NPS while loading: " + Math.floor(state.notesLoadedRN / elapsedTime));
		#end
		state.notesLoadedRN = 0;
	}
}
