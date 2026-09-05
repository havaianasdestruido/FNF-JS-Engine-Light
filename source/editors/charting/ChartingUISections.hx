package editors.charting;

// REFACTOR: extracted from editors.ChartingState (behavior-preserving)
import backend.ClientPrefs;
import backend.Conductor;
import backend.CoolUtil;
import backend.Paths;
import data.Song;
import data.Song.SwagSong;
import editors.ChartingState;
import flixel.addons.ui.FlxUI;
import flixel.addons.ui.FlxUICheckBox;
import flixel.addons.ui.FlxUIInputText;
import flixel.addons.ui.FlxUINumericStepper;
import flixel.addons.ui.FlxUISlider;
import flixel.ui.FlxButton;
import objects.FlxUIDropDownMenuCustom;
import objects.Prompt;
import play.PlayState;

// REFACTOR: imports for relocated root classes
import data.Section;
import objects.Character;
import objects.Note;

@:access(editors.ChartingState)
@:access(backend.MusicBeatState)
class ChartingUISections
{
  public static function addSongUI(state:ChartingState):Void
  {
    state.UI_songTitle = new FlxUIInputText(10, 10, 70, state._song.song, 8);
    state.UI_songTitle.focusGained = () -> FlxG.stage.window.textInputEnabled = true;
    state.blockPressWhileTypingOn.push(state.UI_songTitle);

    var check_voices = new FlxUICheckBox(10, 25, null, null, "Has voice track", 100);
    check_voices.checked = state._song.needsVoices;
    // state._song.needsVoices = check_voices.checked;
    check_voices.callback = function() {
      state._song.needsVoices = check_voices.checked;
      // trace('CHECKED!');
    };

    var saveButton:FlxButton = new FlxButton(110, 8, "Save", function() {
      state.saveLevel();
    });

    var reloadSong:FlxButton = new FlxButton(saveButton.x + 90, saveButton.y, "Reload Audio", function() {
      state.currentSongName = Paths.formatToSongPath(state.UI_songTitle.text);
      state.updateJsonData();
      state.loadSong();
      state.updateWaveform();
    });

    var reloadSongJson:FlxButton = new FlxButton(reloadSong.x, saveButton.y + 30, "Reload JSON", function() {
      state.openSubState(new Prompt('This action will clear current progress.\n\nProceed?', 0, function() {
        state.loadJson(state._song.song.toLowerCase(), state.difficulty);
      }, null, state.ignoreWarnings));
    });

    var loadAutosaveBtn:FlxButton = new FlxButton(reloadSongJson.x, reloadSongJson.y + 30, 'Load Backup From File', function() {
      state.promptBackup(); // this is so assssssssssssssssssssssss
    });

    var loadEventJson:FlxButton = new FlxButton(loadAutosaveBtn.x, loadAutosaveBtn.y + 30, 'Load Events', function() {
      var diff:String = (state.specialEventsName.length > 1 ? state.specialEventsName : state.difficulty).toLowerCase();
      var songName:String = Paths.formatToSongPath(state._song.song);
      var file:String = Paths.songEvents(songName, diff);
      #if sys
      if (FileSystem.exists(Paths.json(file)) || FileSystem.exists(Paths.modsJson(file)))
      #else
      if (OpenFlAssets.exists(file))
      #end
      {
        state.clearEvents();
        var events:SwagSong = Song.loadFromJson(Paths.songEvents(songName, diff, true), songName);
        state._song.events = events.events;
        state.changeSection(ChartingState.curSec);
      }
    });

    var saveEvents:FlxButton = new FlxButton(110, reloadSongJson.y, 'Save Events', function() {
      state.saveEvents();
    });
    var saveCompressed:FlxButton = new FlxButton(110, reloadSongJson.y + 30, 'Save Compressed', function() {
      state.saveLevel(true);
    });
    var autosaveButton:FlxButton = new FlxButton(saveEvents.x, reloadSongJson.y + 60, "Save to Backups", function() {
      if (state.autoSaveTimer != null) state.autoSaveTimer.reset(state.autoSaveLength);

      state.saveLevel(true, true);
    });

    var clear_events:FlxButton = new FlxButton(320, 310, 'Clear events', function() {
      state.openSubState(new Prompt('This action will clear current progress.\n\nProceed?', 0, state.clearEvents, null, state.ignoreWarnings));
    });
    clear_events.color = FlxColor.RED;
    clear_events.label.color = FlxColor.WHITE;

    var clear_notes:FlxButton = new FlxButton(320, clear_events.y + 30, 'Clear notes', function() {
      state.openSubState(new Prompt('This action will clear current progress.\n\nProceed?', 0, function() {
        for (sec in 0...state._song.notes.length)
        {
          state._song.notes[sec].sectionNotes = [];
        }
        state.updateGrid();
      }, null, state.ignoreWarnings));
    });
    clear_notes.color = FlxColor.RED;
    clear_notes.label.color = FlxColor.WHITE;

    var stepperBPM:FlxUINumericStepper = new FlxUINumericStepper(10, 70, 1, 1, 1, 999999, 3);
    stepperBPM.value = Conductor.bpm;
    stepperBPM.name = 'song_bpm';
    state.blockPressWhileTypingOnStepper.push(stepperBPM);

    var stepperSpeed:FlxUINumericStepper = new FlxUINumericStepper(10, stepperBPM.y + 35, 0.1, 1, 0.1, 100, 1);
    stepperSpeed.value = state._song.speed;
    stepperSpeed.name = 'song_speed';
    state.blockPressWhileTypingOnStepper.push(stepperSpeed);
    #if MODS_ALLOWED
    var directories:Array<String> = [
      Paths.mods('characters/'),
      Paths.mods(Mods.currentModDirectory + '/characters/'),
      Paths.getPreloadPath('characters/')
    ];
    for (mod in Mods.getGlobalMods())
      directories.push(Paths.mods(mod + '/characters/'));
    #else
    var directories:Array<String> = [Paths.getPreloadPath('characters/')];
    #end

    var tempMap:Map<String, Bool> = new Map<String, Bool>();
    var characters:Array<String> = CoolUtil.coolTextFile(Paths.txt('characterList'));
    for (i in 0...characters.length)
    {
      tempMap.set(characters[i], true);
    }

    #if MODS_ALLOWED
    for (i in 0...directories.length)
    {
      var directory:String = directories[i];
      if (FileSystem.exists(directory))
      {
        for (file in FileSystem.readDirectory(directory))
        {
          var path = haxe.io.Path.join([directory, file]);
          if (!FileSystem.isDirectory(path) && file.endsWith('.json'))
          {
            var charToCheck:String = file.substr(0, file.length - 5);
            if (!charToCheck.endsWith('-dead') && !tempMap.exists(charToCheck))
            {
              tempMap.set(charToCheck, true);
              characters.push(charToCheck);
            }
          }
        }
      }
    }
    #end

    var player1DropDown = new FlxUIDropDownMenuCustom(10, stepperSpeed.y + 45, FlxUIDropDownMenuCustom.makeStrIdLabelArray(characters, true),
      function(character:String) {
        state._song.player1 = characters[Std.parseInt(character)];
        state.updateJsonData();
        state.updateHeads();
      });
    player1DropDown.selectedLabel = state._song.player1;
    state.blockPressWhileScrolling.push(player1DropDown);

    var gfVersionDropDown = new FlxUIDropDownMenuCustom(player1DropDown.x, player1DropDown.y + 40,
      FlxUIDropDownMenuCustom.makeStrIdLabelArray(characters, true), function(character:String) {
        state._song.gfVersion = characters[Std.parseInt(character)];
        state.updateJsonData();
        state.updateHeads();
    });
    gfVersionDropDown.selectedLabel = state._song.gfVersion;
    state.blockPressWhileScrolling.push(gfVersionDropDown);

    var player2DropDown = new FlxUIDropDownMenuCustom(player1DropDown.x, gfVersionDropDown.y + 40,
      FlxUIDropDownMenuCustom.makeStrIdLabelArray(characters, true), function(character:String) {
        state._song.player2 = characters[Std.parseInt(character)];
        state.updateJsonData();
        state.updateHeads();
    });
    player2DropDown.selectedLabel = state._song.player2;
    state.blockPressWhileScrolling.push(player2DropDown);

    #if MODS_ALLOWED
    var directories:Array<String> = [
      Paths.mods('stages/'),
      Paths.mods(Mods.currentModDirectory + '/stages/'),
      Paths.getPreloadPath('stages/')
    ];
    for (mod in Mods.getGlobalMods())
      directories.push(Paths.mods(mod + '/stages/'));
    #else
    var directories:Array<String> = [Paths.getPreloadPath('stages/')];
    #end

    tempMap.clear();
    var stageFile:Array<String> = CoolUtil.coolTextFile(Paths.txt('stageList'));
    var stages:Array<String> = [];
    for (i in 0...stageFile.length)
    { // Prevent duplicates
      var stageToCheck:String = stageFile[i];
      if (!tempMap.exists(stageToCheck))
      {
        stages.push(stageToCheck);
      }
      tempMap.set(stageToCheck, true);
    }
    #if MODS_ALLOWED
    for (i in 0...directories.length)
    {
      var directory:String = directories[i];
      if (FileSystem.exists(directory))
      {
        for (file in FileSystem.readDirectory(directory))
        {
          var path = haxe.io.Path.join([directory, file]);
          if (!FileSystem.isDirectory(path) && file.endsWith('.json'))
          {
            var stageToCheck:String = file.substr(0, file.length - 5);
            if (!tempMap.exists(stageToCheck))
            {
              tempMap.set(stageToCheck, true);
              stages.push(stageToCheck);
            }
          }
        }
      }
    }
    #end

    if (stages.length < 1) stages.push('stage');

    state.stageDropDown = new FlxUIDropDownMenuCustom(player1DropDown.x + 140, player1DropDown.y, FlxUIDropDownMenuCustom.makeStrIdLabelArray(stages, true),
      function(character:String) {
        state._song.stage = stages[Std.parseInt(character)];
      });
    state.stageDropDown.selectedLabel = state._song.stage;
    state.blockPressWhileScrolling.push(state.stageDropDown);

    state.UI_songDiff = new FlxUIInputText(state.stageDropDown.x, state.stageDropDown.y + 40, 70, CoolUtil.currentDifficulty, 8);
    state.blockPressWhileTypingOn.push(state.UI_songDiff);

    state.UI_specAudio = new FlxUIInputText(state.stageDropDown.x, state.stageDropDown.y + 70, 70, state.specialAudioName, 8);
    state.blockPressWhileTypingOn.push(state.UI_specAudio);

    state.UI_specEvents = new FlxUIInputText(state.stageDropDown.x, state.stageDropDown.y + 100, 70, state.specialEventsName, 8);
    state.blockPressWhileTypingOn.push(state.UI_specEvents);

    var skin = PlayState.SONG.arrowSkin;
    if (skin == null) skin = '';
    state.noteSkinInputText = new FlxUIInputText(player2DropDown.x, player2DropDown.y + 50, 150, skin, 8);
    state.blockPressWhileTypingOn.push(state.noteSkinInputText);
    state.noteSkinInputText.focusGained = () -> FlxG.stage.window.textInputEnabled = true;

    state.noteSplashesInputText = new FlxUIInputText(state.noteSkinInputText.x, state.noteSkinInputText.y + 35, 150, state._song.splashSkin, 8);
    state.blockPressWhileTypingOn.push(state.noteSplashesInputText);
    state.noteSplashesInputText.focusGained = () -> FlxG.stage.window.textInputEnabled = true;

    var reloadNotesButton:FlxButton = new FlxButton(state.noteSplashesInputText.x + 5, state.noteSplashesInputText.y + 20, 'Change Notes', function() {
      state._song.arrowSkin = state.noteSkinInputText.text;
      state.selectionNote.texture = state.noteSkinInputText.text;
      Paths.initDefaultSkin(state.noteSkinInputText.text, true);
      state.updateGrid();
    });

    var tab_group_song = new FlxUI(null, state.UI_box);
    tab_group_song.name = "Song";
    tab_group_song.add(state.UI_songTitle);
    tab_group_song.add(state.UI_songDiff);
    tab_group_song.add(state.UI_specAudio);
    tab_group_song.add(state.UI_specEvents);

    tab_group_song.add(check_voices);
    tab_group_song.add(clear_events);
    tab_group_song.add(clear_notes);
    tab_group_song.add(saveButton);
    tab_group_song.add(saveEvents);
    tab_group_song.add(saveCompressed);
    tab_group_song.add(reloadSong);
    tab_group_song.add(reloadSongJson);
    tab_group_song.add(loadAutosaveBtn);
    tab_group_song.add(autosaveButton);
    tab_group_song.add(loadEventJson);
    tab_group_song.add(stepperBPM);
    tab_group_song.add(stepperSpeed);
    tab_group_song.add(reloadNotesButton);
    tab_group_song.add(state.noteSkinInputText);
    tab_group_song.add(state.noteSplashesInputText);
    tab_group_song.add(new FlxText(stepperBPM.x, stepperBPM.y - 15, 0, 'Song BPM:'));
    tab_group_song.add(new FlxText(stepperSpeed.x, stepperSpeed.y - 15, 0, 'Song Speed:'));
    tab_group_song.add(new FlxText(player2DropDown.x, player2DropDown.y - 15, 0, 'Opponent:'));
    tab_group_song.add(new FlxText(gfVersionDropDown.x, gfVersionDropDown.y - 15, 0, 'Girlfriend:'));
    tab_group_song.add(new FlxText(player1DropDown.x, player1DropDown.y - 15, 0, 'Boyfriend:'));
    tab_group_song.add(new FlxText(state.stageDropDown.x, state.stageDropDown.y - 15, 0, 'Stage:'));
    tab_group_song.add(new FlxText(state.noteSkinInputText.x, state.noteSkinInputText.y - 15, 0, 'Note Texture:'));
    tab_group_song.add(new FlxText(state.noteSplashesInputText.x, state.noteSplashesInputText.y - 15, 0, 'Note Splashes Texture:'));
    tab_group_song.add(new FlxText(state.UI_songDiff.x, state.UI_songDiff.y - 15, 0, "Difficulty:"));
    tab_group_song.add(new FlxText(state.UI_specAudio.x, state.UI_specAudio.y - 15, 0, "Special Audio Name:"));
    tab_group_song.add(new FlxText(state.UI_specEvents.x, state.UI_specEvents.y - 15, 0, "Special Events File:"));
    tab_group_song.add(player2DropDown);
    tab_group_song.add(gfVersionDropDown);
    tab_group_song.add(player1DropDown);
    tab_group_song.add(state.stageDropDown);

    state.UI_box.addGroup(tab_group_song);

    state.initPsychCamera().follow(state.camPos, null, 999);
  }

  public static function addSongDataUI(state:ChartingState):Void // therell be more added here later
  {
    var tab_group_songdata = new FlxUI(null, state.UI_box);
    tab_group_songdata.name = "Data";

    state.creditInputText = new FlxUIInputText(10, 30, 100, state._song.songCredit, 8);
    state.blockPressWhileTypingOn.push(state.creditInputText);
    state.creditInputText.focusGained = () -> FlxG.stage.window.textInputEnabled = true;

    state.creditPathInputText = new FlxUIInputText(10, 60, 100, state._song.songCreditBarPath, 8);
    state.blockPressWhileTypingOn.push(state.creditPathInputText);
    state.creditPathInputText.focusGained = () -> FlxG.stage.window.textInputEnabled = true;

    state.creditIconInputText = new FlxUIInputText(10, 90, 100, state._song.songCreditIcon, 8);
    state.blockPressWhileTypingOn.push(state.creditIconInputText);
    state.creditIconInputText.focusGained = () -> FlxG.stage.window.textInputEnabled = true;

    state.winNameInputText = new FlxUIInputText(10, 120, 100, state._song.windowName, 8);
    state.blockPressWhileTypingOn.push(state.winNameInputText);
    state.winNameInputText.focusGained = () -> FlxG.stage.window.textInputEnabled = true;

    //
    state.gameOverCharacterInputText = new FlxUIInputText(10, state.winNameInputText.y + 30, 150, state._song.gameOverChar != null ? state._song.gameOverChar : '', 8);
    state.blockPressWhileTypingOn.push(state.gameOverCharacterInputText);

    state.gameOverSoundInputText = new FlxUIInputText(10, state.gameOverCharacterInputText.y + 35, 150, state._song.gameOverSound != null ? state._song.gameOverSound : '', 8);
    state.blockPressWhileTypingOn.push(state.gameOverSoundInputText);

    state.gameOverLoopInputText = new FlxUIInputText(10, state.gameOverSoundInputText.y + 35, 150, state._song.gameOverLoop != null ? state._song.gameOverLoop : '', 8);
    state.blockPressWhileTypingOn.push(state.gameOverLoopInputText);

    state.gameOverEndInputText = new FlxUIInputText(10, state.gameOverLoopInputText.y + 35, 150, state._song.gameOverEnd != null ? state._song.gameOverEnd : '', 8);
    state.blockPressWhileTypingOn.push(state.gameOverEndInputText);
    //

    var check_disableNoteRGB:FlxUICheckBox = new FlxUICheckBox(10, 270, null, null, "Disable Note RGB", 100);
    check_disableNoteRGB.checked = (state._song.disableNoteRGB == true);
    check_disableNoteRGB.callback = function() {
      state._song.disableNoteRGB = check_disableNoteRGB.checked;
      state.updateGrid();
      // trace('CHECKED!');
    };

    tab_group_songdata.add(state.gameOverCharacterInputText);
    tab_group_songdata.add(state.gameOverSoundInputText);
    tab_group_songdata.add(state.gameOverLoopInputText);
    tab_group_songdata.add(state.gameOverEndInputText);

    tab_group_songdata.add(check_disableNoteRGB);

    tab_group_songdata.add(new FlxText(state.gameOverCharacterInputText.x, state.gameOverCharacterInputText.y - 15, 0, 'Game Over Character Name:'));
    tab_group_songdata.add(new FlxText(state.gameOverSoundInputText.x, state.gameOverSoundInputText.y - 15, 0, 'Game Over Death Sound (sounds/):'));
    tab_group_songdata.add(new FlxText(state.gameOverLoopInputText.x, state.gameOverLoopInputText.y - 15, 0, 'Game Over Loop Music (music/):'));
    tab_group_songdata.add(new FlxText(state.gameOverEndInputText.x, state.gameOverEndInputText.y - 15, 0, 'Game Over Retry Music (music/):'));

    tab_group_songdata.add(state.creditInputText);
    tab_group_songdata.add(state.creditPathInputText);
    tab_group_songdata.add(state.creditIconInputText);
    tab_group_songdata.add(new FlxText(state.creditInputText.x, state.creditInputText.y - 15, 0, 'Song Credit:'));
    tab_group_songdata.add(new FlxText(state.creditPathInputText.x, state.creditPathInputText.y - 15, 0, 'Credit Bar Path:'));
    tab_group_songdata.add(new FlxText(state.creditIconInputText.x, state.creditIconInputText.y - 15, 0, 'Credit Icon:'));
    tab_group_songdata.add(state.winNameInputText);
    tab_group_songdata.add(new FlxText(state.winNameInputText.x, state.winNameInputText.y - 15, 0, 'Window Name:'));

    state.UI_box.addGroup(tab_group_songdata);
  }

  public static function addSectionUI(state:ChartingState):Void
  {
    var tab_group_section = new FlxUI(null, state.UI_box);
    tab_group_section.name = 'Section';

    state.check_mustHitSection = new FlxUICheckBox(10, 15, null, null, "Must hit section", 100);
    state.check_mustHitSection.name = 'check_mustHit';
    state.check_mustHitSection.checked = (state._song.notes[ChartingState.curSec] != null ? state._song.notes[ChartingState.curSec].mustHitSection : true);

    state.check_gfSection = new FlxUICheckBox(10, state.check_mustHitSection.y + 22, null, null, "GF section", 100);
    state.check_gfSection.name = 'check_gf';
    state.check_gfSection.checked = (state._song.notes[ChartingState.curSec] != null ? state._song.notes[ChartingState.curSec].gfSection : false);
    // state._song.needsVoices = check_mustHit.checked;

    state.check_altAnim = new FlxUICheckBox(state.check_gfSection.x + 120, state.check_gfSection.y, null, null, "Alt Animation", 100);
    state.check_altAnim.checked = (state._song.notes[ChartingState.curSec] != null ? state._song.notes[ChartingState.curSec].altAnim : false);

    state.stepperBeats = new FlxUINumericStepper(10, 100, 1, 4, 1, 8192, 2); // idk why youd need 8k beats in a single section but ok i guess??
    state.stepperBeats.value = state.getSectionBeats();
    state.stepperBeats.name = 'section_beats';
    state.blockPressWhileTypingOnStepper.push(state.stepperBeats);
    state.check_altAnim.name = 'check_altAnim';

    state.check_crossFade = new FlxUICheckBox(130, 60, null, null, "Cross Fade", 100);
		state.check_crossFade.checked = state._song.notes[ChartingState.curSec].crossFade;
		state.check_crossFade.name = 'check_crossFade';

    state.check_changeBPM = new FlxUICheckBox(10, state.stepperBeats.y + 30, null, null, 'Change BPM', 100);
    state.check_changeBPM.checked = (state._song.notes[ChartingState.curSec] != null ? state._song.notes[ChartingState.curSec].changeBPM : false);
    state.check_changeBPM.name = 'check_changeBPM';

    state.stepperSectionBPM = new FlxUINumericStepper(10, state.check_changeBPM.y + 20, 1, Conductor.bpm, 0, 999999, 1);
    if (state.check_changeBPM.checked)
    {
      state.stepperSectionBPM.value = state._song.notes[ChartingState.curSec].bpm;
    } else
    {
      state.stepperSectionBPM.value = Conductor.bpm;
    }
    state.stepperSectionBPM.name = 'section_bpm';
    state.blockPressWhileTypingOnStepper.push(state.stepperSectionBPM);

    var check_eventsSec:FlxUICheckBox = null;
    var check_notesSec:FlxUICheckBox = null;
    var copyButton:FlxButton = new FlxButton(10, 190, "Copy Section", function() {
      state.notesCopied = [];
      state.sectionToCopy = ChartingState.curSec;
      for (i in 0...state._song.notes[ChartingState.curSec].sectionNotes.length)
      {
        var note:Array<Dynamic> = state._song.notes[ChartingState.curSec].sectionNotes[i];
        state.notesCopied.push(note);
      }

      var startThing:Float = state.sectionStartTime();
      var endThing:Float = state.sectionStartTime(1);
      for (event in state._song.events)
      {
        var strumTime:Float = event[0];
        if (endThing > event[0] && event[0] >= startThing)
        {
          var copiedEventArray:Array<Dynamic> = [];
          for (i in 0...event[1].length)
          {
            var eventToPush:Array<Dynamic> = event[1][i];
            copiedEventArray.push([eventToPush[0], eventToPush[1], eventToPush[2]]);
          }
          state.notesCopied.push([strumTime, -1, copiedEventArray]);
        }
      }
    });

    var pasteButton:FlxButton = new FlxButton(copyButton.x + 100, copyButton.y, "Paste Section", function() {
      if (state.notesCopied == null || state.notesCopied.length < 1)
      {
        return;
      }

      var addToTime:Float = Conductor.stepCrochet * (state.getSectionBeats() * 4 * (ChartingState.curSec - state.sectionToCopy));
      // trace('Time to add: ' + addToTime);

      for (note in state.notesCopied)
      {
        var copiedNote:Array<Dynamic> = [];
        var newStrumTime:Float = note[0] + addToTime;
        if (note[1] < 0)
        {
          if (check_eventsSec.checked)
          {
            var copiedEventArray:Array<Dynamic> = [];
            for (i in 0...note[2].length)
            {
              var eventToPush:Array<Dynamic> = note[2][i];
              copiedEventArray.push([eventToPush[0], eventToPush[1], eventToPush[2]]);
            }
            state._song.events.push([newStrumTime, copiedEventArray]);
          }
        } else
        {
          if (check_notesSec.checked)
          {
            if (note[4] != null)
            {
              copiedNote = [newStrumTime, note[1], note[2], note[3], note[4]];
            } else
            {
              copiedNote = [newStrumTime, note[1], note[2], note[3]];
            }
            state._song.notes[ChartingState.curSec].sectionNotes.push(copiedNote);
          }
        }
      }
      state.updateGrid(false);
    });

    var clearSectionButton:FlxButton = new FlxButton(pasteButton.x + 100, pasteButton.y, "Clear", function() {
      if (check_notesSec.checked)
      {
        state._song.notes[ChartingState.curSec].sectionNotes = [];
      }

      if (check_eventsSec.checked)
      {
        var i:Int = state._song.events.length - 1;
        var startThing:Float = state.sectionStartTime();
        var endThing:Float = state.sectionStartTime(1);
        while (i > -1)
        {
          var event:Array<Dynamic> = state._song.events[i];
          if (event != null && endThing > event[0] && event[0] >= startThing)
          {
            state._song.events.remove(event);
          }
          --i;
        }
      }
      state.updateGrid(false);
      state.updateNoteUI();
    });
    clearSectionButton.color = FlxColor.RED;
    clearSectionButton.label.color = FlxColor.WHITE;

    check_notesSec = new FlxUICheckBox(10, clearSectionButton.y + 25, null, null, "Notes", 100);
    check_notesSec.checked = true;
    check_eventsSec = new FlxUICheckBox(check_notesSec.x + 100, check_notesSec.y, null, null, "Events", 100);
    check_eventsSec.checked = true;

    var swapSection:FlxButton = new FlxButton(10, check_notesSec.y + 40, "Swap section", function() {
      for (i in 0...state._song.notes[ChartingState.curSec].sectionNotes.length)
      {
        var note:Array<Dynamic> = state._song.notes[ChartingState.curSec].sectionNotes[i];
        note[1] = (note[1] + 4) % 8;
        state._song.notes[ChartingState.curSec].sectionNotes[i] = note;
      }
      state.updateGrid(false);
    });

    var stepperCopy:FlxUINumericStepper = null;
    var copyLastButton:FlxButton = new FlxButton(10, swapSection.y + 30, "Copy last section", function() {
      state.saveUndo(state._song); // in case you copy from the wrong section and want to easily undo it
      var value:Int = Std.int(stepperCopy.value);
      if (value == 0) return;

      var daSec = FlxMath.maxInt(ChartingState.curSec, value);
      if (state._song.notes[daSec - value] == null || state._song.notes[daSec] == null) return;

      if (check_notesSec.checked && state._song.notes[daSec - value] != null)
      {
        for (note in state._song.notes[daSec - value].sectionNotes)
        {
          var strum = note[0] + Conductor.stepCrochet * (state.getSectionBeats(daSec) * 4 * value);

          var copiedNote:Array<Dynamic> = [strum, note[1], note[2], note[3]];
          state._song.notes[daSec].sectionNotes.push(copiedNote);
        }
      }

      if (check_eventsSec.checked && state._song.notes[daSec - value] != null)
      {
        var startThing:Float = state.sectionStartTime(-value);
        var endThing:Float = state.sectionStartTime(-value + 1);
        for (event in state._song.events)
        {
          var strumTime:Float = event[0];
          if (endThing > event[0] && event[0] >= startThing)
          {
            strumTime += Conductor.stepCrochet * (state.getSectionBeats(daSec) * 4 * value);
            var copiedEventArray:Array<Dynamic> = [];
            for (i in 0...event[1].length)
            {
              var eventToPush:Array<Dynamic> = event[1][i];
              copiedEventArray.push([eventToPush[0], eventToPush[1], eventToPush[2]]);
            }
            state._song.events.push([strumTime, copiedEventArray]);
          }
        }
      }
      state.updateGrid(false);
    });
    copyLastButton.setGraphicSize(80, 30);
    copyLastButton.updateHitbox();

    stepperCopy = new FlxUINumericStepper(copyLastButton.x + 100, copyLastButton.y, 1, 1, -999, 999, 0);
    state.blockPressWhileTypingOnStepper.push(stepperCopy);

    var duetButton:FlxButton = new FlxButton(10, copyLastButton.y + 45, "Duet Notes", function() {
      var duetNotes:Array<Array<Dynamic>> = [];
      for (note in state._song.notes[ChartingState.curSec].sectionNotes)
      {
        var boob = note[1];
        if (boob > 3)
        {
          boob -= 4;
        } else
        {
          boob += 4;
        }

        var copiedNote:Array<Dynamic> = [note[0], boob, note[2], note[3]];
        duetNotes.push(copiedNote);
      }

      for (i in duetNotes)
      {
        state._song.notes[ChartingState.curSec].sectionNotes.push(i);
      }

      state.updateGrid(false);
    });
    var mirrorButton:FlxButton = new FlxButton(duetButton.x + 100, duetButton.y, "Mirror Notes", function() {
      var duetNotes:Array<Array<Dynamic>> = [];
      for (note in state._song.notes[ChartingState.curSec].sectionNotes)
      {
        var boob = note[1] % 4;
        boob = 3 - boob;
        if (note[1] > 3) boob += 4;

        note[1] = boob;
        var copiedNote:Array<Dynamic> = [note[0], boob, note[2], note[3]];
        // duetNotes.push(copiedNote);
      }

      for (i in duetNotes)
      {
        // state._song.notes[ChartingState.curSec].sectionNotes.push(i);
      }

      state.updateGrid(false);
    });
    var clearLeftSectionButton:FlxButton = new FlxButton(duetButton.x, duetButton.y + 30, "Clear Left Side", function() {
      if (Conductor.songPosition >= 0) state.curSection = Math.floor(Conductor.songPosition / (Conductor.stepCrochet * 16));

      if (state._song.notes[state.curSection] == null || state._song.notes[state.curSection] != null && state._song.notes[state.curSection].sectionNotes == null) return;
      state.saveUndo(state._song); // this is really weird so im saving it as an undoable action just in case it does the wrong section
      var removeThese = [];
      for (noteIndex in 0...state._song.notes[state.curSection].sectionNotes.length)
      {
        if (state._song.notes[state.curSection].sectionNotes[noteIndex][1] < 4)
        {
          removeThese.push(state._song.notes[state.curSection].sectionNotes[noteIndex]);
        }
      }
      if (removeThese != [])
      {
        for (x in removeThese)
        {
          state._song.notes[state.curSection].sectionNotes.remove(x);
        }
      }

      state.updateGrid(false);
      state.updateNoteUI();
    });
    var clearRightSectionButton:FlxButton = new FlxButton(clearLeftSectionButton.x + 100, clearLeftSectionButton.y, "Clear Right Side", function() {
      if (Conductor.songPosition >= 0) state.curSection = Math.floor(Conductor.songPosition / (Conductor.stepCrochet * 16));

      if (state._song.notes[state.curSection] == null || state._song.notes[state.curSection] != null && state._song.notes[state.curSection].sectionNotes == null) return;
      state.saveUndo(state._song); // this is really weird so im saving it as an undoable action just in case it does the wrong section
      var removeThese = [];
      for (noteIndex in 0...state._song.notes[state.curSection].sectionNotes.length)
      {
        if (state._song.notes[state.curSection].sectionNotes[noteIndex][1] >= 4)
        {
          removeThese.push(state._song.notes[state.curSection].sectionNotes[noteIndex]);
        }
      }
      if (removeThese != [])
      {
        for (x in removeThese)
        {
          state._song.notes[state.curSection].sectionNotes.remove(x);
        }
      }

      state.updateGrid(false);
      state.updateNoteUI();
    });
    clearLeftSectionButton.color = FlxColor.RED;
    clearLeftSectionButton.label.color = FlxColor.WHITE;
    clearRightSectionButton.color = FlxColor.RED;
    clearRightSectionButton.label.color = FlxColor.WHITE;

    var stepperSectionJump:FlxUINumericStepper = new FlxUINumericStepper(clearSectionButton.x, clearSectionButton.y + 30, 1, 0, 0, 999999, 0);
    state.blockPressWhileTypingOnStepper.push(stepperSectionJump);

    var jumpSection:FlxButton = new FlxButton(clearSectionButton.x, stepperSectionJump.y + 20, "Jump Section", function() {
      var value:Int = Std.int(stepperSectionJump.value);
      state.changeSection(value);
    });

    var CopyNextSectionCount:FlxUINumericStepper = new FlxUINumericStepper(jumpSection.x, jumpSection.y + 60, 1, 1, -16384, 16384, 0);
    state.blockPressWhileTypingOnStepper.push(CopyNextSectionCount);

    state.CopyLastSectionCount = new FlxUINumericStepper(CopyNextSectionCount.x + 100, CopyNextSectionCount.y, 1, 1, -16384, 16384, 0);
    state.blockPressWhileTypingOnStepper.push(state.CopyLastSectionCount);

    state.CopyFutureSectionCount = new FlxUINumericStepper(state.CopyLastSectionCount.x + 70, state.CopyLastSectionCount.y, 1, 1, -16384, 16384, 0);
    state.blockPressWhileTypingOnStepper.push(state.CopyFutureSectionCount);

    state.CopyLoopCount = new FlxUINumericStepper(state.CopyFutureSectionCount.x - 60, state.CopyLastSectionCount.y + 40, 1, 1, -16384, 16384, 0);
    state.blockPressWhileTypingOnStepper.push(state.CopyLoopCount);

    state.copyMultiSectButton = new FlxButton(state.CopyFutureSectionCount.x, state.CopyLastSectionCount.y
      + 40,
      "Copy from the last "
      + Std.int(state.CopyFutureSectionCount.value)
      + " to the next "
      + Std.int(state.CopyFutureSectionCount.value)
      + " sections, "
      + Std.int(state.CopyLoopCount.value)
      + " times",
      function() {
        var swapNotes:Bool = FlxG.keys.pressed.CONTROL;
        var daSec = FlxMath.maxInt(ChartingState.curSec, Std.int(state.CopyLastSectionCount.value));
        var value1:Int = Std.int(state.CopyLastSectionCount.value);
        var value2:Int = Std.int(state.CopyFutureSectionCount.value) * Std.int(state.CopyLoopCount.value);
        if (value1 == 0)
        {
          return;
        }
        if (state._song.notes[state.curSection] != null && Math.isNaN(state._song.notes[daSec].sectionNotes.length))
        {
          trace("HEY! your section doesn't have any notes! please place at least 1 note then try using this.");
          return; // prevent a crash if the section doesn't have any notes
        }
        state.saveUndo(state._song); // I don't even know why.

        if (check_notesSec.checked)
        {
          for (i in 0...value2)
          {
            if (state.curSection - value1 < 0)
            {
              trace("The number you put for value 1 would cause the game to copy notes from a negative section.");
              break;
            }
            for (note in state._song.notes[daSec - value1].sectionNotes)
            {
              var strum = note[0] + Conductor.stepCrochet * (state.getSectionBeats(daSec - value1) * 4 * value1);

              var data = note[1];
              if (swapNotes) data = Std.int(note[1] + 4) % 8;
              var copiedNote:Array<Dynamic> = [strum, data, note[2], note[3]];
              inline state._song.notes[daSec].sectionNotes.push(copiedNote);
            }
            if (state.sectionStartTime(1) > FlxG.sound.music.length)
            {
              trace('Last possible section reached!');
              break;
            }
            if (state._song.notes[ChartingState.curSec + 1] == null)
            {
              state.addSection(state.getSectionBeats());
            }
            state.changeSection(ChartingState.curSec + 1);
            daSec = FlxMath.maxInt(ChartingState.curSec, Std.int(state.CopyLastSectionCount.value) - 1);
            // Feel free to comment this out.
            trace('Loops Remaining: '
              + (value2 - i)
              + ', current note count: '
              + FlxStringUtil.formatMoney(CoolUtil.getNoteAmount(state._song), false)
              + ' Notes');
          }
        }
      });
    state.copyMultiSectButton.color = FlxColor.BLUE;
    state.copyMultiSectButton.label.color = FlxColor.WHITE;
    state.copyMultiSectButton.setGraphicSize(Std.int(state.copyMultiSectButton.width), Std.int(state.copyMultiSectButton.height));
    state.copyMultiSectButton.updateHitbox();

    var copyNextButton:FlxButton = new FlxButton(CopyNextSectionCount.x, CopyNextSectionCount.y + 20, "Copy to the next..", function() {
      var swapNotes:Bool = FlxG.keys.pressed.CONTROL;
      var value:Int = Std.int(CopyNextSectionCount.value);
      if (value == 0)
      {
        return;
      }
      if (state._song.notes[ChartingState.curSec] == null
        || state._song.notes[ChartingState.curSec] != null
        && state._song.notes[ChartingState.curSec].sectionNotes.length < 1
        || Math.isNaN(state._song.notes[ChartingState.curSec].sectionNotes.length)
        || state._song.notes[ChartingState.curSec].sectionNotes == null)
      {
        trace("HEY! your section doesn't have any notes! please place at least 1 note then try using this.");
        return; // prevent a crash if the section doesn't have any notes
      }
      state.saveUndo(state._song); // I don't even know why.

      for (i in 0...value)
      {
        if (state.sectionStartTime(1) > FlxG.sound.music.length)
        {
          trace('Last possible section reached!');
          break;
        }
        if (state._song.notes[ChartingState.curSec + 1] == null) state.addSection(state.getSectionBeats());
        state.changeSection(ChartingState.curSec + 1);
        for (note in state._song.notes[ChartingState.curSec - 1].sectionNotes)
        {
          var strum = note[0] + Conductor.stepCrochet * (state.getSectionBeats(ChartingState.curSec - 1) * 4);

          var data = note[1];
          if (swapNotes) data = Std.int(note[1] + 4) % 8;
          var copiedNote:Array<Dynamic> = [strum, data, note[2], note[3]];
          state._song.notes[ChartingState.curSec].sectionNotes.push(copiedNote);
        }
      }
      state.updateGrid(false);
    });
    copyNextButton.color = FlxColor.CYAN;
    copyNextButton.label.color = FlxColor.WHITE;

    state.deleteSecStart = new FlxUINumericStepper(state.copyMultiSectButton.x + 80, state.CopyLastSectionCount.y, 1, 1, -16384, 16384, 0);
    state.blockPressWhileTypingOnStepper.push(state.deleteSecStart);

    state.deleteSecEnd = new FlxUINumericStepper(state.deleteSecStart.x + 60, state.CopyLastSectionCount.y, 1, 1, -16384, 16384, 0);
    state.blockPressWhileTypingOnStepper.push(state.deleteSecEnd);

    state.deleteSections = new FlxButton(state.deleteSecStart.x
      + 30, state.CopyLastSectionCount.y
      + 40,
      "Delete sections "
      + Std.int(state.deleteSecStart.value)
      + " to "
      + Std.int(state.deleteSecEnd.value), function() {
        var startSec:Int = Std.int(state.deleteSecStart.value);
        var endSec:Int = Std.int(state.deleteSecEnd.value);
        var sectionsToDelete:Int = endSec - startSec;
        if (sectionsToDelete < 0)
        {
          return;
        }
        state.saveUndo(state._song); // I don't even know why.

        var deleteBfNotes:Bool = FlxG.keys.pressed.SHIFT;
        var deleteOppNotes:Bool = FlxG.keys.pressed.CONTROL;

        for (i in 0...sectionsToDelete)
        {
          if (state._song.notes[startSec + i] != null
            && state._song.notes[startSec + i].sectionNotes != null) if (!deleteBfNotes && !deleteOppNotes) state._song.notes[startSec + i].sectionNotes = [];
            else
            {
              var b = state._song.notes[startSec + i].sectionNotes.length - 1;
              while (b >= 0)
              {
                var note = state._song.notes[startSec + i].sectionNotes[b];
                if (note != null
                  && deleteBfNotes
                  && (note[1] < 4 ? state._song.notes[startSec + i].mustHitSection : !state._song.notes[startSec + i].mustHitSection))
                  state._song.notes[startSec + i].sectionNotes.remove(note);
                if (note != null
                  && deleteOppNotes
                  && (note[1] < 4 ? !state._song.notes[startSec + i].mustHitSection : state._song.notes[startSec + i].mustHitSection))
                  state._song.notes[startSec + i].sectionNotes.remove(note);
                b--;
              }
            }
        }
    });
    state.deleteSections.color = FlxColor.YELLOW;
    state.deleteSections.label.color = FlxColor.WHITE;
    state.deleteSections.setGraphicSize(Std.int(state.deleteSections.width), Std.int(state.deleteSections.height));
    state.deleteSections.updateHitbox();

    tab_group_section.add(stepperSectionJump);
    tab_group_section.add(jumpSection);
    tab_group_section.add(new FlxText(state.stepperBeats.x, state.stepperBeats.y - 15, 0, 'Beats per Section:'));
    tab_group_section.add(state.stepperBeats);
    tab_group_section.add(state.stepperSectionBPM);
    tab_group_section.add(state.check_mustHitSection);
    tab_group_section.add(state.check_gfSection);
    tab_group_section.add(state.check_altAnim);
    tab_group_section.add(state.check_crossFade);
    tab_group_section.add(state.check_changeBPM);
    tab_group_section.add(copyButton);
    tab_group_section.add(pasteButton);
    tab_group_section.add(clearRightSectionButton);
    tab_group_section.add(clearLeftSectionButton);
    tab_group_section.add(copyNextButton);
    tab_group_section.add(CopyNextSectionCount);
    tab_group_section.add(state.CopyLastSectionCount);
    tab_group_section.add(state.CopyFutureSectionCount);
    tab_group_section.add(state.CopyLoopCount);
    tab_group_section.add(state.deleteSecStart);
    tab_group_section.add(state.deleteSecEnd);
    tab_group_section.add(clearSectionButton);
    tab_group_section.add(check_notesSec);
    tab_group_section.add(check_eventsSec);
    tab_group_section.add(swapSection);
    tab_group_section.add(stepperCopy);
    tab_group_section.add(copyLastButton);
    tab_group_section.add(duetButton);
    tab_group_section.add(mirrorButton);
    tab_group_section.add(state.copyMultiSectButton);
    tab_group_section.add(state.deleteSections);

    state.UI_box.addGroup(tab_group_section);
  }

  public static function addNoteUI(state:ChartingState):Void
  {
    var tab_group_note = new FlxUI(null, state.UI_box);
    tab_group_note.name = 'Note';

    state.stepperSusLength = new FlxUINumericStepper(10, 25, Conductor.stepCrochet / 2, 0, 0, Conductor.stepCrochet * 64);
    state.stepperSusLength.value = 0;
    state.stepperSusLength.name = 'note_susLength';
    state.blockPressWhileTypingOnStepper.push(state.stepperSusLength);

    state.strumTimeInputText = new FlxUIInputText(10, 65, 180, "0");
    tab_group_note.add(state.strumTimeInputText);
    state.blockPressWhileTypingOn.push(state.strumTimeInputText);

    var key:Int = 0;
    var displayNameList:Array<String> = [];
    while (key < ChartingState.noteTypeList.length)
    {
      displayNameList.push(ChartingState.noteTypeList[key]);
      state.noteTypeMap.set(ChartingState.noteTypeList[key], key);
      state.noteTypeIntMap.set(key, ChartingState.noteTypeList[key]);
      key++;
    }
    var notetypeFiles:Array<String> = Mods.mergeAllTextsNamed('data/' + Paths.formatToSongPath(state._song.song) + '/notetypes.txt', '', true);
    if (notetypeFiles.length > 0)
    {
      for (ntTyp in notetypeFiles)
      {
        var name:String = ntTyp.trim();
        if (!displayNameList.contains(name))
        {
          displayNameList.push(name);
          state.noteTypeMap.set(name, key);
          state.noteTypeIntMap.set(key, name);
          key++;
        }
      }
    }

    #if LUA_ALLOWED
    var directories:Array<String> = [];

    #if MODS_ALLOWED
    directories.push(Paths.mods('custom_notetypes/'));
    directories.push(Paths.mods(Mods.currentModDirectory + '/custom_notetypes/'));
    for (mod in Mods.getGlobalMods())
      directories.push(Paths.mods(mod + '/custom_notetypes/'));
    #end

    for (i in 0...directories.length)
    {
      var directory:String = directories[i];
      if (FileSystem.exists(directory))
      {
        for (file in FileSystem.readDirectory(directory))
        {
          var path = haxe.io.Path.join([directory, file]);
          if (!FileSystem.isDirectory(path) && file.endsWith('.lua'))
          {
            var fileToCheck:String = file.substr(0, file.length - 4);
            if (!state.noteTypeMap.exists(fileToCheck))
            {
              displayNameList.push(fileToCheck);
              state.noteTypeMap.set(fileToCheck, key);
              state.noteTypeIntMap.set(key, fileToCheck);
              key++;
            }
          }
        }
      }
    }
    #end

    for (i in 1...displayNameList.length)
    {
      displayNameList[i] = i + '. ' + displayNameList[i];
    }

    state.noteTypeDropDown = new FlxUIDropDownMenuCustom(10, 105, FlxUIDropDownMenuCustom.makeStrIdLabelArray(displayNameList, true), function(character:String) {
      state.currentType = Std.parseInt(character);
      if (state.curSelectedNote != null && state.curSelectedNote[1] > -1)
      {
        state.curSelectedNote[3] = state.noteTypeIntMap.get(state.currentType);
        state.updateGrid(false);
      }
    });
    state.blockPressWhileScrolling.push(state.noteTypeDropDown);

    var leftSectionNotetype:FlxButton = new FlxButton(state.noteTypeDropDown.x, state.noteTypeDropDown.y + 40, "Left Section to Notetype", function() {
      for (i in 0...state._song.notes[ChartingState.curSec].sectionNotes.length)
      {
        var note:Array<Dynamic> = state._song.notes[ChartingState.curSec].sectionNotes[i];
        if (note[1] < 4)
        {
          note[3] = state.noteTypeIntMap.get(state.currentType);
        }
        state._song.notes[ChartingState.curSec].sectionNotes[i] = note;
      }
      state.updateGrid(false);
    });
    var rightSectionNotetype:FlxButton = new FlxButton(leftSectionNotetype.x + 90, leftSectionNotetype.y, "Right Section to Notetype", function() {
      for (i in 0...state._song.notes[ChartingState.curSec].sectionNotes.length)
      {
        var note:Array<Dynamic> = state._song.notes[ChartingState.curSec].sectionNotes[i];
        if (note[1] > 3)
        {
          note[3] = state.noteTypeIntMap.get(state.currentType);
        }
        state._song.notes[ChartingState.curSec].sectionNotes[i] = note;
      }
      state.updateGrid(false);
    });

    tab_group_note.add(new FlxText(10, 10, 0, 'Sustain length:'));
    tab_group_note.add(new FlxText(10, 50, 0, 'Strum time (in miliseconds):'));
    tab_group_note.add(new FlxText(10, 90, 0, 'Note type:'));
    tab_group_note.add(leftSectionNotetype);
    tab_group_note.add(rightSectionNotetype);
    tab_group_note.add(state.stepperSusLength);
    tab_group_note.add(state.strumTimeInputText);
    tab_group_note.add(state.noteTypeDropDown);

    state.UI_box.addGroup(tab_group_note);
  }

  public static function addNoteStackingUI(state:ChartingState):Void
  {
    var tab_group_stacking = new FlxUI(null, state.UI_box);
    tab_group_stacking.name = 'Note Spamming';

    state.check_stackActive = new FlxUICheckBox(10, 10, null, null, "Enable EZ Spam Mode", 100);
    state.check_stackActive.name = 'check_stackActive';

    state.stepperStackNum = new FlxUINumericStepper(10, 30, 1, 1, 0, 999999, 4);
    state.stepperStackNum.name = 'stack_count';
    state.blockPressWhileTypingOnStepper.push(state.stepperStackNum);

    var doubleSpamNum:FlxButton = new FlxButton(state.stepperStackNum.x, state.stepperStackNum.y + 20, 'x2 Amount', function() {
      state.stepperStackNum.value *= 2;
    });
    doubleSpamNum.setGraphicSize(Std.int(doubleSpamNum.width), Std.int(doubleSpamNum.height));
    doubleSpamNum.color = FlxColor.GREEN;
    doubleSpamNum.label.color = FlxColor.WHITE;

    var halfSpamNum:FlxButton = new FlxButton(doubleSpamNum.x + doubleSpamNum.width + 20, doubleSpamNum.y, 'x0.5 Amount', function() {
      state.stepperStackNum.value /= 2;
    });
    halfSpamNum.setGraphicSize(Std.int(halfSpamNum.width), Std.int(halfSpamNum.height));
    halfSpamNum.color = FlxColor.RED;
    halfSpamNum.label.color = FlxColor.WHITE;

    state.stepperStackOffset = new FlxUINumericStepper(10, 80, 1, 1, 0, 999999, 4);
    state.stepperStackOffset.name = 'stack_offset';
    state.blockPressWhileTypingOnStepper.push(state.stepperStackOffset);

    var doubleSpamMult:FlxButton = new FlxButton(state.stepperStackOffset.x, state.stepperStackOffset.y + 20, 'x2 SM', function() {
      state.stepperStackOffset.value *= 2;
    });
    doubleSpamMult.color = FlxColor.GREEN;
    doubleSpamMult.label.color = FlxColor.WHITE;

    var halfSpamMult:FlxButton = new FlxButton(doubleSpamMult.x + doubleSpamMult.width + 20, doubleSpamMult.y, 'x0.5 SM', function() {
      state.stepperStackOffset.value /= 2;
    });
    halfSpamMult.setGraphicSize(Std.int(halfSpamMult.width), Std.int(halfSpamMult.height));
    halfSpamMult.color = FlxColor.RED;
    halfSpamMult.label.color = FlxColor.WHITE;

    state.stepperStackSideOffset = new FlxUINumericStepper(10, 140, 1, 0, -9999, 9999);
    state.stepperStackSideOffset.name = 'stack_sideways';
    state.blockPressWhileTypingOnStepper.push(state.stepperStackSideOffset);

    state.stepperShrinkAmount = new FlxUINumericStepper(10, state.stepperStackSideOffset.y + 30, 1, 1, 0, 8192, 4);
    state.stepperShrinkAmount.name = 'shrinker_amount';
    state.blockPressWhileTypingOnStepper.push(state.stepperShrinkAmount);

    var doubleShrinker:FlxButton = new FlxButton(state.stepperShrinkAmount.x, state.stepperShrinkAmount.y + 20, 'x2 SH', function() {
      state.stepperShrinkAmount.value *= 2;
    });
    doubleShrinker.color = FlxColor.GREEN;
    doubleShrinker.label.color = FlxColor.WHITE;

    var halfShrinker:FlxButton = new FlxButton(doubleShrinker.x + doubleShrinker.width + 20, doubleShrinker.y, 'x0.5 SH', function() {
      state.stepperShrinkAmount.value /= 2;
    });
    halfShrinker.setGraphicSize(Std.int(halfShrinker.width), Std.int(halfShrinker.height));
    halfShrinker.color = FlxColor.RED;
    halfShrinker.label.color = FlxColor.WHITE;

    var shrinkNotesButton:FlxButton = new FlxButton(10, doubleShrinker.y + 30, "Stretch Notes", function() {
      var minimumTime:Float = state.sectionStartTime();
      var sectionEndTime:Float = state.sectionStartTime(1);
      for (i in 0...state._song.notes[ChartingState.curSec].sectionNotes.length)
      {
        var note:Array<Dynamic> = state._song.notes[ChartingState.curSec].sectionNotes[i];
        if (note[2] > 0) note[2] *= state.stepperShrinkAmount.value;
        var originalStartTime:Float = note[0]; // Original start time (in seconds)
        originalStartTime = originalStartTime - state.sectionStartTime();

        var stretchedStartTime:Float = originalStartTime * state.stepperShrinkAmount.value;

        var newStartTime:Float = state.sectionStartTime() + stretchedStartTime;

        note[0] = Math.max(newStartTime, minimumTime);
        if (note[0] < minimumTime) note[0] = minimumTime;
        state._song.notes[ChartingState.curSec].sectionNotes[i] = note;
      }
      state.updateGrid(false);
    });

    var stepperShiftSteps:FlxUINumericStepper = new FlxUINumericStepper(10, shrinkNotesButton.y + 30, 1, 1, -8192, 8192, 4);
    stepperShiftSteps.name = 'shifter_amount';
    state.blockPressWhileTypingOnStepper.push(stepperShiftSteps);

    var shiftNotesButton:FlxButton = new FlxButton(10, stepperShiftSteps.y + 20, "Shift Notes", function() {
      for (i in 0...state._song.notes[ChartingState.curSec].sectionNotes.length)
      {
        state._song.notes[ChartingState.curSec].sectionNotes[i][0] += (stepperShiftSteps.value) * (15000 / Conductor.bpm);
      }
      state.updateGrid(false);
    });
    shiftNotesButton.setGraphicSize(Std.int(shiftNotesButton.width), Std.int(shiftNotesButton.height));

    // ok im adding way too many spamcharting features LOL

    var stepperDuplicateAmount:FlxUINumericStepper = new FlxUINumericStepper(10, shiftNotesButton.y + 30, 1, 1, 0, 32, 4);
    stepperDuplicateAmount.name = 'duplicater_amount';
    state.blockPressWhileTypingOnStepper.push(stepperDuplicateAmount);

    var dupeNotesButton:FlxButton = new FlxButton(10, stepperDuplicateAmount.y + 20, "Duplicate Notes", function() {
      var copiedNotes:Array<Dynamic> = [];
      for (i in 0...state._song.notes[ChartingState.curSec].sectionNotes.length)
      {
        var note:Array<Dynamic> = state._song.notes[ChartingState.curSec].sectionNotes[i];
        copiedNotes.push(note);
      }
      for (_i in 1...Std.int(stepperDuplicateAmount.value) + 1)
      {
        for (i in 0...copiedNotes.length)
        {
          final copiedNote:Array<Dynamic> = [copiedNotes[i][0], copiedNotes[i][1], copiedNotes[i][2], copiedNotes[i][3]];
          copiedNote[0] += (stepperShiftSteps.value * _i) * (15000 / Conductor.bpm);
          // yeah.. unfortunately this relies on the value of the Shift Notes stepper.. stupid but it works, so im gonna keep it this way until i find a better solution
          state._song.notes[ChartingState.curSec].sectionNotes.push(copiedNote);
        }
      }
      state._song.notes[ChartingState.curSec].sectionNotes.length <= 30000 ? state.updateGrid(false) : state.changeSection(ChartingState.curSec +
        1); // if there's now more than 30,000 notes in the same section then uh.. change to the next section so you don't suffer a crash
    });
    dupeNotesButton.setGraphicSize(Std.int(dupeNotesButton.width), Std.int(dupeNotesButton.height));

    tab_group_stacking.add(state.check_stackActive);
    tab_group_stacking.add(state.stepperStackNum);
    tab_group_stacking.add(state.stepperStackOffset);
    tab_group_stacking.add(state.stepperStackSideOffset);
    tab_group_stacking.add(state.stepperShrinkAmount);
    tab_group_stacking.add(stepperShiftSteps);
    tab_group_stacking.add(stepperDuplicateAmount);
    tab_group_stacking.add(doubleSpamNum);
    tab_group_stacking.add(halfSpamNum);
    tab_group_stacking.add(doubleSpamMult);
    tab_group_stacking.add(halfSpamMult);
    tab_group_stacking.add(doubleShrinker);
    tab_group_stacking.add(halfShrinker);
    tab_group_stacking.add(shrinkNotesButton);
    tab_group_stacking.add(shiftNotesButton);
    tab_group_stacking.add(dupeNotesButton);

    tab_group_stacking.add(new FlxText(100, 30, 0, "Spam Count"));
    tab_group_stacking.add(new FlxText(100, 80, 0, "Spam Multiplier"));
    tab_group_stacking.add(new FlxText(100, 140, 0, "Spam Scroll Amount"));
    tab_group_stacking.add(new FlxText(100, state.stepperShrinkAmount.y, 0, "Stretch Amount"));
    tab_group_stacking.add(new FlxText(100, stepperShiftSteps.y, 0, "Steps to Shift By"));
    tab_group_stacking.add(new FlxText(100, stepperDuplicateAmount.y, 0, "Amount of Duplicates"));

    state.UI_box.addGroup(tab_group_stacking);
  }

  public static function addEventsUI(state:ChartingState):Void
  {
    var tab_group_event = new FlxUI(null, state.UI_box);
    tab_group_event.name = 'Events';

    #if LUA_ALLOWED
    var eventPushedMap:Map<String, Bool> = new Map<String, Bool>();
    var directories:Array<String> = [];

    #if MODS_ALLOWED
    directories.push(Paths.mods('custom_events/'));
    directories.push(Paths.mods(Mods.currentModDirectory + '/custom_events/'));
    for (mod in Mods.getGlobalMods())
      directories.push(Paths.mods(mod + '/custom_events/'));
    #end

    for (i in 0...directories.length)
    {
      var directory:String = directories[i];
      if (FileSystem.exists(directory))
      {
        for (file in FileSystem.readDirectory(directory))
        {
          var path = haxe.io.Path.join([directory, file]);
          if (!FileSystem.isDirectory(path) && file != 'readme.txt' && file.endsWith('.txt'))
          {
            var fileToCheck:String = file.substr(0, file.length - 4);
            if (!eventPushedMap.exists(fileToCheck))
            {
              eventPushedMap.set(fileToCheck, true);
              state.eventStuff.push([fileToCheck, File.getContent(path)]);
            }
          }
        }
      }
    }
    eventPushedMap.clear();
    eventPushedMap = null;
    #end

    state.descText = new FlxText(20, 200, 0, state.eventStuff[0][0]);

    var leEvents:Array<String> = [];
    for (i in 0...state.eventStuff.length)
    {
      leEvents.push(state.eventStuff[i][0]);
    }

    var text:FlxText = new FlxText(20, 30, 0, "Event:");
    tab_group_event.add(text);
    state.eventDropDown = new FlxUIDropDownMenuCustom(20, 50, FlxUIDropDownMenuCustom.makeStrIdLabelArray(leEvents, true), function(pressed:String) {
      var selectedEvent:Int = Std.parseInt(pressed);
      state.descText.text = state.eventStuff[selectedEvent][1];
      if (state.curSelectedNote != null && state.eventStuff != null)
      {
        if (state.curSelectedNote != null && state.curSelectedNote[2] == null)
        {
          state.curSelectedNote[1][state.curEventSelected][0] = state.eventStuff[selectedEvent][0];
        }
        state.updateGrid(false);
      }
    });
    state.blockPressWhileScrolling.push(state.eventDropDown);

    var text:FlxText = new FlxText(20, 90, 0, "Value 1:");
    tab_group_event.add(text);
    state.value1InputText = new FlxUIInputText(20, 110, 100, "");
    state.blockPressWhileTypingOn.push(state.value1InputText);
    state.value1InputText.focusGained = () -> FlxG.stage.window.textInputEnabled = true;

    var text:FlxText = new FlxText(20, 130, 0, "Value 2:");
    tab_group_event.add(text);
    state.value2InputText = new FlxUIInputText(20, 150, 100, "");
    state.blockPressWhileTypingOn.push(state.value2InputText);
    state.value2InputText.focusGained = () -> FlxG.stage.window.textInputEnabled = true;

    var pressing7Events:Array<String> = ['---', 'None', 'Game Over', 'Go to Song', 'Close Game', 'Play Video'];

    state.event7DropDown = new FlxUIDropDownMenuCustom(160, 300, FlxUIDropDownMenuCustom.makeStrIdLabelArray(pressing7Events, true), function(pressed:String) {
      trace('event pressed 1');
      var whatIsIt:Int = Std.parseInt(pressed);
      var arraySelectedShit:String = pressing7Events[whatIsIt];
      state._song.event7 = arraySelectedShit;
    });
    state.event7DropDown.selectedLabel = state._song.event7;
    var text:FlxText = new FlxText(160, 280, 0, "7 Event:");
    tab_group_event.add(text);

    // New event buttons
    var removeButton:FlxButton = new FlxButton(state.eventDropDown.x + state.eventDropDown.width + 10, state.eventDropDown.y, '-', function() {
      if (state.curSelectedNote != null && state.curSelectedNote[2] == null) // Is event note
      {
        if (state.curSelectedNote[1].length < 2)
        {
          state._song.events.remove(state.curSelectedNote);
          state.curSelectedNote = null;
        } else
        {
          state.curSelectedNote[1].remove(state.curSelectedNote[1][state.curEventSelected]);
        }

        var eventsGroup:Array<Dynamic>;
        --state.curEventSelected;
        if (state.curEventSelected < 0) state.curEventSelected = 0;
        else if (state.curSelectedNote != null
          && state.curEventSelected >= (eventsGroup = state.curSelectedNote[1]).length) state.curEventSelected = eventsGroup.length - 1;

        state.changeEventSelected();
        state.updateGrid();
      }
    });
    removeButton.setGraphicSize(Std.int(removeButton.height), Std.int(removeButton.height));
    removeButton.updateHitbox();
    removeButton.color = FlxColor.RED;
    removeButton.label.color = FlxColor.WHITE;
    removeButton.label.size = 12;
    state.setAllLabelsOffset(removeButton, -30, 0);
    tab_group_event.add(removeButton);

    var addButton:FlxButton = new FlxButton(removeButton.x + removeButton.width + 10, removeButton.y, '+', function() {
      if (state.curSelectedNote != null && state.curSelectedNote[2] == null) // Is event note
      {
        var eventsGroup:Array<Dynamic> = state.curSelectedNote[1];
        eventsGroup.push(['', '', '']);

        state.changeEventSelected(1);
        state.updateGrid();
      }
    });
    addButton.setGraphicSize(Std.int(removeButton.width), Std.int(removeButton.height));
    addButton.updateHitbox();
    addButton.color = FlxColor.GREEN;
    addButton.label.color = FlxColor.WHITE;
    addButton.label.size = 12;
    state.setAllLabelsOffset(addButton, -30, 0);
    tab_group_event.add(addButton);

    var moveLeftButton:FlxButton = new FlxButton(addButton.x + addButton.width + 20, addButton.y, '<', function() {
      state.changeEventSelected(-1);
    });
    moveLeftButton.setGraphicSize(Std.int(addButton.width), Std.int(addButton.height));
    moveLeftButton.updateHitbox();
    moveLeftButton.label.size = 12;
    state.setAllLabelsOffset(moveLeftButton, -30, 0);
    tab_group_event.add(moveLeftButton);

    var moveRightButton:FlxButton = new FlxButton(moveLeftButton.x + moveLeftButton.width + 10, moveLeftButton.y, '>', function() {
      state.changeEventSelected(1);
    });
    moveRightButton.setGraphicSize(Std.int(moveLeftButton.width), Std.int(moveLeftButton.height));
    moveRightButton.updateHitbox();
    moveRightButton.label.size = 12;
    state.setAllLabelsOffset(moveRightButton, -30, 0);
    tab_group_event.add(moveRightButton);

    state.selectedEventText = new FlxText(addButton.x - 100, addButton.y + addButton.height + 6, (moveRightButton.x - addButton.x) + 186, 'Selected Event: None');
    state.selectedEventText.alignment = CENTER;
    tab_group_event.add(state.selectedEventText);

    state.event7InputText = new FlxUIInputText(160, state.event7DropDown.y + 40, 100, state._song.event7Value);
    state.blockPressWhileTypingOn.push(state.event7InputText);
    state.event7InputText.focusGained = () -> FlxG.stage.window.textInputEnabled = true;
    state.blockPressWhileScrolling.push(state.event7DropDown);

    tab_group_event.add(state.event7DropDown);
    tab_group_event.add(state.event7InputText);
    tab_group_event.add(state.descText);
    tab_group_event.add(state.value1InputText);
    tab_group_event.add(state.value2InputText);
    tab_group_event.add(state.eventDropDown);

    state.UI_box.addGroup(tab_group_event);
  }

  public static function addChartingUI(state:ChartingState)
  {
    var tab_group_chart = new FlxUI(null, state.UI_box);
    tab_group_chart.name = 'Charting';

    #if (desktop && !air)
    if (FlxG.save.data.chart_waveformInst == null) FlxG.save.data.chart_waveformInst = false;
    if (FlxG.save.data.chart_waveformVoices == null) FlxG.save.data.chart_waveformVoices = false;
    if (FlxG.save.data.chart_waveformOppVoices == null) FlxG.save.data.chart_waveformOppVoices = false;

    var waveformUseInstrumental:FlxUICheckBox = null;
    var waveformUseVoices:FlxUICheckBox = null;
    var waveformUseOppVoices:FlxUICheckBox = null;

    waveformUseInstrumental = new FlxUICheckBox(10, 90, null, null, "Waveform\n(Instrumental)", 85);
    waveformUseInstrumental.checked = FlxG.save.data.chart_waveformInst;
    waveformUseInstrumental.callback = function() {
      waveformUseVoices.checked = false;
      waveformUseOppVoices.checked = false;
      FlxG.save.data.chart_waveformVoices = false;
      FlxG.save.data.chart_waveformOppVoices = false;
      FlxG.save.data.chart_waveformInst = waveformUseInstrumental.checked;
      state.updateWaveform();
    };

    waveformUseVoices = new FlxUICheckBox(waveformUseInstrumental.x + 100, waveformUseInstrumental.y, null, null, "Waveform\n(Main Vocals)", 85);
    waveformUseVoices.checked = FlxG.save.data.chart_waveformVoices && !waveformUseInstrumental.checked;
    waveformUseVoices.callback = function() {
      waveformUseInstrumental.checked = false;
      waveformUseOppVoices.checked = false;
      FlxG.save.data.chart_waveformInst = false;
      FlxG.save.data.chart_waveformOppVoices = false;
      FlxG.save.data.chart_waveformVoices = waveformUseVoices.checked;
      state.updateWaveform();
    };

    waveformUseOppVoices = new FlxUICheckBox(waveformUseInstrumental.x + 200, waveformUseInstrumental.y, null, null, "Waveform\n(Opp. Vocals)", 85);
    waveformUseOppVoices.checked = FlxG.save.data.chart_waveformOppVoices && !waveformUseVoices.checked;
    waveformUseOppVoices.callback = function() {
      waveformUseInstrumental.checked = false;
      waveformUseVoices.checked = false;
      FlxG.save.data.chart_waveformInst = false;
      FlxG.save.data.chart_waveformVoices = false;
      FlxG.save.data.chart_waveformOppVoices = waveformUseOppVoices.checked;
      state.updateWaveform();
    };
    #end

    state.check_mute_inst = new FlxUICheckBox(10, 280, null, null, "Mute Instrumental (in editor)", 100);
    state.check_mute_inst.checked = false;
    state.check_mute_inst.callback = function() {
      var vol:Float = 1;

      if (state.check_mute_inst.checked) vol = 0;

      FlxG.sound.music.volume = vol;
    };
    state.mouseScrollingQuant = new FlxUICheckBox(10, 180, null, null, "Mouse Scrolling Quantization", 100);
    if (FlxG.save.data.state.mouseScrollingQuant == null) FlxG.save.data.state.mouseScrollingQuant = false;
    state.mouseScrollingQuant.checked = FlxG.save.data.state.mouseScrollingQuant;

    state.mouseScrollingQuant.callback = function() {
      FlxG.save.data.state.mouseScrollingQuant = state.mouseScrollingQuant.checked;
      state.mouseQuant = FlxG.save.data.state.mouseScrollingQuant;
    };

    state.lilBuddiesBox = new FlxUICheckBox(state.mouseScrollingQuant.x + 150, state.mouseScrollingQuant.y, null, null, "Lil' Buddies", 100);
    if (FlxG.save.data.lilBuddies == null) FlxG.save.data.lilBuddies = false;
    state.lilBuddiesBox.checked = FlxG.save.data.lilBuddies;
    state.lilBuddiesBox.callback = function() {
      FlxG.save.data.lilBuddies = state.lilBuddiesBox.checked;
      state.lilBf.visible = state.lilBuddiesBox.checked;
      state.lilOpp.visible = state.lilBuddiesBox.checked;
      state.lilStage.visible = state.lilBuddiesBox.checked;
    };

    state.saveUndoCheck = new FlxUICheckBox(state.mouseScrollingQuant.x + 150, state.mouseScrollingQuant.y + 25, null, null, "Save Undos", 100);
    if (FlxG.save.data.allowUndo == null) FlxG.save.data.allowUndo = true;
    state.saveUndoCheck.checked = FlxG.save.data.allowUndo;
    state.saveUndoCheck.callback = function() {
      FlxG.save.data.allowUndo = state.saveUndoCheck.checked;
    };

    state.check_vortex = new FlxUICheckBox(10, 140, null, null, "Vortex Editor (BETA)", 100);
    if (FlxG.save.data.chart_vortex == null) FlxG.save.data.chart_vortex = false;
    state.check_vortex.checked = FlxG.save.data.chart_vortex;

    state.check_vortex.callback = function() {
      FlxG.save.data.chart_vortex = state.check_vortex.checked;
      ChartingState.vortex = FlxG.save.data.chart_vortex;
      state.reloadGridLayer();
    };

    state.check_showGrid = new FlxUICheckBox(10, 205, null, null, "Show Grid", 100);
    if (FlxG.save.data.showGrid == null) FlxG.save.data.showGrid = false;
    state.check_showGrid.checked = FlxG.save.data.showGrid;

    state.check_showGrid.callback = function() {
      FlxG.save.data.showGrid = state.check_showGrid.checked;
      state.showTheGrid = FlxG.save.data.showGrid;
      state.reloadGridLayer();
    };

    state.check_warnings = new FlxUICheckBox(10, 120, null, null, "Ignore Progress Warnings", 100);
    if (FlxG.save.data.state.ignoreWarnings == null) FlxG.save.data.state.ignoreWarnings = false;
    state.check_warnings.checked = FlxG.save.data.state.ignoreWarnings;

    state.check_warnings.callback = function() {
      FlxG.save.data.state.ignoreWarnings = state.check_warnings.checked;
      state.ignoreWarnings = FlxG.save.data.state.ignoreWarnings;
    };

    state.check_mute_vocals = new FlxUICheckBox(state.check_mute_inst.x, state.check_mute_inst.y + 30, null, null, "Mute Main Vocals (in editor)", 100);
    state.check_mute_vocals.checked = false;
    state.check_mute_vocals.callback = function() {
      var vol:Float = state.voicesVolume.value;
      if (state.check_mute_vocals.checked) vol = 0;

      if (state.vocals != null) state.vocals.volume = vol;
    };
    state.check_mute_vocals_opponent = new FlxUICheckBox(state.check_mute_vocals.x + 120, state.check_mute_vocals.y, null, null, "Mute Opp. Vocals (in editor)", 100);
    state.check_mute_vocals_opponent.checked = false;
    state.check_mute_vocals_opponent.callback = function() {
      var vol:Float = state.voicesOppVolume.value;
      if (state.check_mute_vocals_opponent.checked) vol = 0;

      if (state.opponentVocals != null) state.opponentVocals.volume = vol;
    };

    state.playSoundBf = new FlxUICheckBox(state.check_mute_inst.x, state.check_mute_vocals.y + 30, null, null, 'Play Sound (Boyfriend notes)', 100, function() {
      FlxG.save.data.chart_playSoundBf = state.playSoundBf.checked;
    });
    if (FlxG.save.data.chart_playSoundBf == null) FlxG.save.data.chart_playSoundBf = false;
    state.playSoundBf.checked = FlxG.save.data.chart_playSoundBf;

    state.playSoundDad = new FlxUICheckBox(state.check_mute_inst.x + 120, state.playSoundBf.y, null, null, 'Play Sound (Opponent notes)', 100, function() {
      FlxG.save.data.chart_playSoundDad = state.playSoundDad.checked;
    });
    if (FlxG.save.data.chart_playSoundDad == null) FlxG.save.data.chart_playSoundDad = false;
    state.playSoundDad.checked = FlxG.save.data.chart_playSoundDad;

    state.metronome = new FlxUICheckBox(10, 15, null, null, "Metronome Enabled", 100, function() {
      FlxG.save.data.chart_metronome = state.metronome.checked;
    });
    if (FlxG.save.data.chart_metronome == null) FlxG.save.data.chart_metronome = false;
    state.metronome.checked = FlxG.save.data.chart_metronome;

    state.metronomeStepper = new FlxUINumericStepper(15, 55, 5, state._song.bpm, 1, 1500, 1);
    state.metronomeOffsetStepper = new FlxUINumericStepper(state.metronomeStepper.x + 100, state.metronomeStepper.y, 25, 0, 0, 1000, 1);
    state.blockPressWhileTypingOnStepper.push(state.metronomeStepper);
    state.blockPressWhileTypingOnStepper.push(state.metronomeOffsetStepper);

    state.disableAutoScrolling = new FlxUICheckBox(state.metronome.x + 120, state.metronome.y, null, null, "Disable Autoscroll (Not Recommended)", 120, function() {
      FlxG.save.data.chart_noAutoScroll = state.disableAutoScrolling.checked;
    });
    if (FlxG.save.data.chart_noAutoScroll == null) FlxG.save.data.chart_noAutoScroll = false;
    state.disableAutoScrolling.checked = FlxG.save.data.chart_noAutoScroll;

    state.instVolume = new FlxUINumericStepper(state.metronomeStepper.x, 250, 0.1, 1, 0, 1, 1);
    state.instVolume.value = FlxG.sound.music.volume;
    state.instVolume.name = 'inst_volume';
    state.blockPressWhileTypingOnStepper.push(state.instVolume);

    state.voicesVolume = new FlxUINumericStepper(state.instVolume.x + 100, state.instVolume.y, 0.1, 1, 0, 1, 1);
    state.voicesVolume.value = state.vocals.volume;
    state.voicesVolume.name = 'voices_volume';
    state.blockPressWhileTypingOnStepper.push(state.voicesVolume);

    state.voicesOppVolume = new FlxUINumericStepper(state.instVolume.x + 200, state.instVolume.y, 0.1, 1, 0, 1, 1);
    state.voicesOppVolume.value = state.vocals.volume;
    state.voicesOppVolume.name = 'voices_opp_volume';
    state.blockPressWhileTypingOnStepper.push(state.voicesOppVolume);

    if (FlxG.save.data.chart_hitsoundVolume == null) FlxG.save.data.chart_hitsoundVolume = 1;

    state.hitsoundVol = FlxG.save.data.chart_hitsoundVolume;

    state.hitsoundVolume = new FlxUINumericStepper(state.voicesVolume.x + 100, state.voicesVolume.y + 30, 0.1, state.hitsoundVol, 0, 1, 1);
    state.hitsoundVolume.name = 'hitsound_volume';
    state.blockPressWhileTypingOnStepper.push(state.hitsoundVolume);

    #if !html5
    state.sliderRate = new FlxUISlider(state, 'playbackSpeed', 120, 120, 0.25, 4, 150, 15, 5, FlxColor.WHITE, FlxColor.BLACK);
    state.sliderRate.nameLabel.text = 'Playback Rate';
    tab_group_chart.add(state.sliderRate);
    #end

    state.soundEffectsCheck = new FlxUICheckBox(state.metronomeOffsetStepper.x + 70, state.metronomeOffsetStepper.y, null, null, "Sound Effects", 100);
    if (FlxG.save.data.soundEffects == null) FlxG.save.data.soundEffects = true;
    state.soundEffectsCheck.checked = FlxG.save.data.soundEffects;
    state.soundEffectsCheck.callback = function() {
      FlxG.save.data.soundEffects = state.soundEffectsCheck.checked;
    };

    state.idleMusicCheck = new FlxUICheckBox(state.metronomeOffsetStepper.x + 70, state.metronomeOffsetStepper.y - 20, null, null, "Idle Music", 100);
    if (FlxG.save.data.idleMusicAllowed == null) FlxG.save.data.idleMusicAllowed = true;
    state.idleMusicCheck.checked = FlxG.save.data.idleMusicAllowed;
    state.idleMusicCheck.callback = function() {
      FlxG.save.data.idleMusicAllowed = state.idleMusicCheck.checked;
      ChartingState.idleMusicAllow = FlxG.save.data.idleMusicAllowed;
      if (!FlxG.sound.music.playing)
      {
        if (ChartingState.idleMusicAllow)
        {
          if (!state.idleMusic.musicPaused) state.idleMusic.playMusic();
          else
            state.idleMusic.unpauseMusic(0.3);
        } else
          state.idleMusic.pauseMusic();
      }
    };

    tab_group_chart.add(new FlxText(state.metronomeStepper.x, state.metronomeStepper.y - 15, 0, 'BPM:'));
    tab_group_chart.add(new FlxText(state.metronomeOffsetStepper.x, state.metronomeOffsetStepper.y - 15, 0, 'Offset (ms):'));
    tab_group_chart.add(new FlxText(state.instVolume.x, state.instVolume.y - 15, 0, 'Inst Volume'));
    tab_group_chart.add(new FlxText(state.voicesVolume.x, state.voicesVolume.y - 15, 0, 'Main Vocals'));
    tab_group_chart.add(new FlxText(state.voicesOppVolume.x, state.voicesOppVolume.y - 15, 0, 'Opp. Vocals'));
    tab_group_chart.add(new FlxText(state.hitsoundVolume.x, state.hitsoundVolume.y - 15, 0, 'Hitsound Volume'));
    tab_group_chart.add(state.metronome);
    tab_group_chart.add(state.disableAutoScrolling);
    tab_group_chart.add(state.metronomeStepper);
    tab_group_chart.add(state.metronomeOffsetStepper);
    #if (desktop && !air)
    tab_group_chart.add(waveformUseInstrumental);
    tab_group_chart.add(waveformUseVoices);
    tab_group_chart.add(waveformUseOppVoices);
    #end
    tab_group_chart.add(state.lilBuddiesBox);
    tab_group_chart.add(state.soundEffectsCheck);
    tab_group_chart.add(state.saveUndoCheck);
    tab_group_chart.add(state.idleMusicCheck);
    tab_group_chart.add(state.instVolume);
    tab_group_chart.add(state.voicesVolume);
    tab_group_chart.add(state.voicesOppVolume);
    tab_group_chart.add(state.check_mute_inst);
    tab_group_chart.add(state.check_mute_vocals);
    tab_group_chart.add(state.check_mute_vocals_opponent);
    tab_group_chart.add(state.hitsoundVolume);
    tab_group_chart.add(state.check_vortex);
    tab_group_chart.add(state.mouseScrollingQuant);
    tab_group_chart.add(state.check_warnings);
    tab_group_chart.add(state.check_showGrid);
    tab_group_chart.add(state.playSoundBf);
    tab_group_chart.add(state.playSoundDad);
    state.UI_box.addGroup(tab_group_chart);
  }
}
