package editors.charting;

// REFACTOR: extracted from editors.ChartingState (behavior-preserving)
import backend.CoolUtil;
import backend.Paths;
import data.Song;
import data.Song.SwagSong;
import editors.ChartingState;
import flixel.util.FlxSort;
import lime.ui.FileDialog;
import lime.ui.FileDialogType;
import objects.Prompt;
import openfl.events.Event;
import openfl.events.IOErrorEvent;
import openfl.net.FileReference;
import play.PlayState;

// REFACTOR: imports for relocated root classes
import objects.Character;

@:access(editors.ChartingState)
@:access(backend.MusicBeatState)
class ChartingSaveLoad
{
  public static function songJsonPopup(state:ChartingState)
  { // you tried reloading the json, but it doesn't exist
    CoolUtil.coolError("The engine failed to load the JSON! \nEither it doesn't exist, or the name doesn't match with the one you're putting?",
      "JS Engine Anti-Crash Tool");
  }

  public static function promptBackup(state:ChartingState)
  {
    var fD:FileDialog = new FileDialog();

    fD.onOpen.add(f -> {
      // Kinda stupid but it works
      state.openSubState(new Prompt('This action will clear current progress.\n\nProceed?', 0, function() {
        try
        {
          var wrapper:SwagSong = Song.parseJSON(f);
          if (wrapper.song == null)
          {
            CoolUtil.coolError("Failed to load JSON â€“ not a valid chart.json.", "JS Engine Anti-Crash Tool");
            return;
          }

          PlayState.SONG = wrapper;
          CoolUtil.currentDifficulty = "backup";

          FlxG.resetState();
        }
        catch (e)
        {
          CoolUtil.coolError('Failed to load JSON, is it a character.json or a stage.json instead of a chart.json?\nError: $e', "JS Engine Anti-Crash Tool");
        };
      }, null, state.ignoreWarnings));
    });

    fD.open("json", null, "Choose a Psych Engine Compatible Chart JSON to load as.");
  }

  public static function saveUndo(state:ChartingState, songData:SwagSong)
  {
    if (CoolUtil.getNoteAmount(songData) <= 50000 && FlxG.save.data.allowUndo)
    {
      var shit = Json.stringify(
        { // doin this so it doesnt act as a reference
          "song": songData
        });
      if (state.lastUndoShit == shit) return;
      state.lastUndoShit = shit;
      var song:SwagSong = Song.parseJSON(shit);

      state.undos.unshift(song.notes);
      state.redos = []; // Reset state.redos
      if (state.undos.length > 50) // keep at most 50 state.undos, drop the oldest (last element after unshift)
        state.undos.pop();
    }
  }

  public static function undo(state:ChartingState)
  {
    if (state.undos.length > 0 && state.saveUndoCheck.checked)
    {
      state._song.notes = state.undos[0];
      state.redos.unshift(state.undos[0]);
      state.undos.splice(0, 1);
      state.lastUndoShit = null;
      trace("Performed an Undo! Undos remaining: " + state.undos.length);
      ChartingState.unsavedChanges = true;
      if (state.curSection > state._song.notes.length) state.changeSection(state._song.notes.length - 1);
      state.updateGrid();
    }
  }

  public static function getNotes(state:ChartingState):Array<Dynamic>
  {
    return [for (i in state._song.notes) i.sectionNotes];
  }

  public static function loadJson(state:ChartingState, song:String, ?diff:String = ''):Void
  {
    // shitty null fix, i fucking hate it when this happens
    // make it look sexier if possible
    var songName:String = Paths.formatToSongPath(state._song.song);
    var jsonExists = sys.FileSystem.exists(Paths.json(songName + '/' + songName))
      || sys.FileSystem.exists(Paths.modsJson(songName + '/' + songName));
    var diffJsonExists = sys.FileSystem.exists(Paths.json(songName + '/' + songName + '-$diff'))
      || sys.FileSystem.exists(Paths.modsJson(songName + '/' + songName + '-$diff'));
    if (jsonExists || diffJsonExists)
    {
      if (diff != CoolUtil.defaultDifficulty.toLowerCase())
      {
        if (CoolUtil.difficulties[PlayState.storyDifficulty] == null || !diffJsonExists)
        {
          PlayState.SONG = Song.loadFromJson(songName.toLowerCase(), songName.toLowerCase());
        } else
        {
          PlayState.SONG = Song.loadFromJson(songName.toLowerCase() + "-" + diff, songName.toLowerCase());
        }
      } else
      {
        PlayState.SONG = Song.loadFromJson(songName.toLowerCase(), songName.toLowerCase());
      }
      CoolUtil.currentDifficulty = diff;
      FlxG.resetState();
      if (state.idleMusic != null && state.idleMusic.music != null) state.idleMusic.destroy();
    } else
    {
      trace(songName + "'s JSON doesn't exist!");
      state.songJsonPopup(); // HAH, IT AINT CRASHING NOW
    }
  }

  public static function clearEvents(state:ChartingState)
  {
    state._song.events = [];
    ChartingState.unsavedChanges = true;
    state.updateGrid();
  }

  public static function saveLevel(state:ChartingState, ?compressed:Bool = false, ?isAuto:Bool = false)
  {
    Paths.gc(true);
    if (CoolUtil.getNoteAmount(state._song) > 1000000)
    {
      cpp.vm.Gc.enable(false);
    }
    if (state._song.events != null && state._song.events.length > 1) state._song.events.sort(sortByTime);

    final json =
      {
        "song": state._song
      };

    final data:String = !compressed ? Json.stringify(json, "\t") : Json.stringify(json);

    if ((data != null) && (data.length > 0))
    {
      var gamingName:String = Paths.formatToSongPath(state._song.song);

      if (state.difficulty.toLowerCase() != 'normal') gamingName = gamingName + '-' + Paths.formatToSongPath(state.difficulty);

      if (!isAuto)
      {
        state._file = new FileReference();
        state._file.addEventListener(Event.COMPLETE, state.onSaveComplete);
        state._file.addEventListener(Event.CANCEL, state.onSaveCancel);
        state._file.addEventListener(IOErrorEvent.IO_ERROR, state.onSaveError);

        state._file.save(data.trim(), gamingName + ".json");
      } else
      {
        // create backups folder if it doesn't exist yet
        if (!FileSystem.exists('backups/'))
        {
          FileSystem.createDirectory("backups/");
          File.saveContent('backups/README.txt',
            "This is where your backups are stored.\nIf your engine freezes/crashes and you didn't save it, you will be happy that the backups are now stored in there instead of the single autosave so you can restore it whenever you want!");
        }

        // Get list of backup files
        var backups = FileSystem.readDirectory('backups/')
          .filter(f -> f.endsWith(".json"))
          .map(f -> 'backups/' + f)
          .filter(f -> FileSystem.exists(f) && !FileSystem.isDirectory(f));

        // Then, sort by modification time (oldest first)
        backups.sort((a, b) -> {
          return FlxSort.byValues(FlxSort.ASCENDING, FileSystem.stat(a).mtime.getTime(), FileSystem.stat(b).mtime.getTime());
        });

        // If the limit is exceeded, delete the oldest backups.
        while (backups.length >= 5)
          FileSystem.deleteFile(backups.shift());

        var dateNow:String = Date.now().toString();
        dateNow = dateNow.replace(" ", "_");
        dateNow = dateNow.replace(":", "'");

        File.saveContent('backups/${gamingName}_$dateNow.json', data.trim());
      }
    }

    cpp.vm.Gc.enable(true);
    ChartingState.unsavedChanges = false;
    if (state.autoSaveTimer != null) state.autoSaveTimer.reset(state.autoSaveLength);
  }

  public static function sortByTime(Obj1:Array<Dynamic>, Obj2:Array<Dynamic>):Int
  {
    return FlxSort.byValues(FlxSort.ASCENDING, Obj1[0], Obj2[0]);
  }

  public static function saveEvents(state:ChartingState)
  {
    if (state._song.events != null && state._song.events.length > 1) state._song.events.sort(sortByTime);
    var eventsSong:Dynamic =
      {
        events: state._song.events
      };
    var json =
      {
        "song": eventsSong
      }

    var data:String = Json.stringify(json, "\t");

    if ((data != null) && (data.length > 0))
    {
      state._file = new FileReference();
      state._file.addEventListener(Event.COMPLETE, state.onSaveComplete);
      state._file.addEventListener(Event.CANCEL, state.onSaveCancel);
      state._file.addEventListener(IOErrorEvent.IO_ERROR, state.onSaveError);
      state._file.save(data.trim(), "events.json");
    }
  }

  public static function onSaveComplete(state:ChartingState, _):Void
  {
    state._file.removeEventListener(Event.COMPLETE, state.onSaveComplete);
    state._file.removeEventListener(Event.CANCEL, state.onSaveCancel);
    state._file.removeEventListener(IOErrorEvent.IO_ERROR, state.onSaveError);
    state._file = null;
    FlxG.log.notice("Successfully saved LEVEL DATA.");
  }

  public static function onSaveCancel(state:ChartingState, _):Void
  {
    state._file.removeEventListener(Event.COMPLETE, state.onSaveComplete);
    state._file.removeEventListener(Event.CANCEL, state.onSaveCancel);
    state._file.removeEventListener(IOErrorEvent.IO_ERROR, state.onSaveError);
    state._file = null;
  }

  /**
   * Called if there is an error while saving the gameplay recording.
   */
  public static function onSaveError(state:ChartingState, _):Void
  {
    state._file.removeEventListener(Event.COMPLETE, state.onSaveComplete);
    state._file.removeEventListener(Event.CANCEL, state.onSaveCancel);
    state._file.removeEventListener(IOErrorEvent.IO_ERROR, state.onSaveError);
    state._file = null;
    FlxG.log.error("Problem saving Level data");
  }
}
