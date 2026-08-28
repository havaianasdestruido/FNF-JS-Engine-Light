package editors.charting;

// REFACTOR: extracted from editors.ChartingState (behavior-preserving)
import backend.Conductor;
import backend.Paths;
import editors.ChartingState;
import editors.charting.AttachedFlxText;
import flixel.ui.FlxButton;
import objects.Note;

@:access(editors.ChartingState)
@:access(backend.MusicBeatState)
class ChartingEvents
{
  public static function changeEventSelected(state:ChartingState, change:Int = 0)
  {
    if (state.curSelectedNote != null && state.curSelectedNote[2] == null) // Is event note
    {
      state.curEventSelected += change;
      if (state.curEventSelected < 0) state.curEventSelected = Std.int(state.curSelectedNote[1].length) - 1;
      else if (state.curEventSelected >= state.curSelectedNote[1].length) state.curEventSelected = 0;
      state.selectedEventText.text = 'Selected Event: ' + (state.curEventSelected + 1) + ' / ' + state.curSelectedNote[1].length;
    } else
    {
      state.curEventSelected = 0;
      state.selectedEventText.text = 'Selected Event: None';
    }
    state.updateNoteUI();
  }

  public static function setAllLabelsOffset(button:FlxButton, x:Float, y:Float)
  {
    for (point in button.labelOffsets)
    {
      point.set(x, y);
    }
  }

  public static function selectNote(state:ChartingState, note:Note, ?updateTheGrid:Bool = true):Void
  {
    var noteDataToCheck:Int = note.noteData;

    if (noteDataToCheck > -1)
    {
      if (note.mustPress != state._song.notes[ChartingState.curSec].mustHitSection) noteDataToCheck += 4;
      for (i in state._song.notes[ChartingState.curSec].sectionNotes)
      {
        if (i != state.curSelectedNote && i.length > 2 && i[0] == note.strumTime && i[1] == noteDataToCheck)
        {
          state.curSelectedNote = i;
          break;
        }
      }
    } else
    {
      for (i in state._song.events)
      {
        if (i != state.curSelectedNote && i[0] == note.strumTime)
        {
          state.curSelectedNote = i;
          state.curEventSelected = Std.int(state.curSelectedNote[1].length) - 1;
          break;
        }
      }
    }
    state.changeEventSelected();

    if (updateTheGrid)
    {
      state.updateGrid(false);
      state.updateNoteUI();
    }
  }

  public static function deleteNote(state:ChartingState, note:Note, ?usingVortex:Bool = false):Void
  {
    var noteDataToCheck:Int = note.noteData;
    if (noteDataToCheck > -1 && note.mustPress != state._song.notes[ChartingState.curSec].mustHitSection) noteDataToCheck += 4;

    if (note.noteData > -1) // Normal Notes
    {
      for (i in state._song.notes[ChartingState.curSec].sectionNotes)
      {
        if (i[0] == note.strumTime && i[1] == noteDataToCheck)
        {
          if (i == state.curSelectedNote) state.curSelectedNote = null;
          // FlxG.log.add('FOUND EVIL NOTE');
          state._song.notes[ChartingState.curSec].sectionNotes.remove(i);
          break;
        }
      }
    } else // Events
    {
      for (i in state._song.events)
      {
        if (i[0] == note.strumTime)
        {
          if (i == state.curSelectedNote)
          {
            state.curSelectedNote = null;
            state.changeEventSelected();
          }
          // FlxG.log.add('FOUND EVIL EVENT');
          state._song.events.remove(i);
          break;
        }
      }
    }
    state.curRenderedNoteType.forEach(txt -> {
      if (txt.sprTracker == note)
      {
        state.curRenderedNoteType.remove(txt, true);
        txt.destroy();
      }
    });
    state.curRenderedEventText.forEach(txt -> {
      if (txt.sprTracker == note)
      {
        state.curRenderedEventText.remove(txt, true);
        txt.destroy();
      }
    });
    if (note.sustainLength > 0)
    {
      state.curRenderedSustains.remove(note, true);
      state.updateGrid(false);
    }
    state.curRenderedNotes.remove(note, true);
    note.destroy();

    ChartingState.unsavedChanges = true;
  }

  public static function doANoteThing(state:ChartingState, cs, d, style)
  {
    var delnote = false;
    if (state.strumLineNotes.members[d].overlaps(state.curRenderedNotes))
    {
      state.curRenderedNotes.forEachAlive(function(note:Note) {
        if (note.overlapsPoint(new FlxPoint(state.strumLineNotes.members[d].x + 1, state.strumLine.y + 1)) && note.noteData == d % 4)
        {
          // trace('tryin to delete note...');
          state.saveUndo(state._song);
          if (!delnote) state.deleteNote(note, true);
          delnote = true;
        }
      });
    }

    if (!delnote)
    {
      state.saveUndo(state._song);
      state.addNote(cs, d, style);
    }
  }

  public static function clearSong(state:ChartingState):Void
  {
    for (daSection in 0...state._song.notes.length)
    {
      state._song.notes[daSection].sectionNotes = [];
    }

    ChartingState.unsavedChanges = true;
    state.updateGrid();
  }

  public static function addNote(state:ChartingState, strum:Null<Float> = null, data:Null<Int> = null, type:Null<Int> = null, ?gridUpdate:Bool = true):Void
  {
    var noteStrum = state.getStrumTime(state.selectionNote.y * (state.getSectionBeats() / 4), false) + state.sectionStartTime();
    var noteData:Int = Math.floor((FlxG.mouse.x - ChartingState.GRID_SIZE) / ChartingState.GRID_SIZE);
    var noteSus = 0;
    var daAlt = false;
    var daType = state.currentType;

    if (strum != null) noteStrum = strum;
    if (data != null) noteData = data;
    if (type != null) daType = type;

    if (noteData > -1)
    {
      state._song.notes[ChartingState.curSec].sectionNotes.push([noteStrum, noteData, noteSus, state.noteTypeIntMap.get(daType)]);
      state.curSelectedNote = state._song.notes[ChartingState.curSec].sectionNotes[state._song.notes[ChartingState.curSec].sectionNotes.length - 1];
    } else
    {
      var event = state.eventStuff[Std.parseInt(state.eventDropDown.selectedId)][0];
      var text1 = state.value1InputText.text;
      var text2 = state.value2InputText.text;
      state._song.events.push([noteStrum, [[event, text1, text2]]]);
      state.curSelectedNote = state._song.events[state._song.events.length - 1];
      state.curEventSelected = 0;
    }
    state.changeEventSelected();

    if (FlxG.keys.pressed.CONTROL && noteData > -1)
    {
      state._song.notes[ChartingState.curSec].sectionNotes.push([noteStrum, (noteData + 4) % 8, noteSus, state.noteTypeIntMap.get(daType)]);
      state.updateGrid();
    }

    state.strumTimeInputText.text = '' + state.curSelectedNote[0];
    // wow its not laggy who wouldve guessed
    if (gridUpdate)
    {
      switch (noteData)
      {
        case -1:
          var note:Note = state.setupNoteData(state.curSelectedNote, false);
          state.curRenderedNotes.add(note);

          var text:String = 'Event: ' + note.eventName + ' (' + Math.floor(note.strumTime) + ' ms)' + '\nValue 1: ' + note.eventVal1 + '\nValue 2: '
            + note.eventVal2;
          if (note.eventLength > 1) text = note.eventLength + ' Events:\n' + note.eventName;

          var daText:AttachedFlxText = new AttachedFlxText(0, 0, 400, text, 12);
          daText.setFormat(Paths.font("vcr.ttf"), 12, FlxColor.WHITE, RIGHT, FlxTextBorderStyle.OUTLINE_FAST, FlxColor.BLACK);
          daText.xAdd = -410;
          daText.borderSize = 1;
          if (note.eventLength > 1) daText.yAdd += 8;
          state.curRenderedNoteType.add(daText);
          daText.sprTracker = note;
        // trace('test: ' + i[0], 'startThing: ' + startThing, 'endThing: ' + endThing);
        default:
          var beats:Float = state.getSectionBeats();
          var note:Note = state.setupNoteData(state.curSelectedNote, false);
          state.curRenderedNotes.add(note);
          if (note.sustainLength > 0)
          {
            state.curRenderedSustains.add(state.setupSusNote(note, beats));
          }

          if (state.curSelectedNote[3] != null && note.noteType != null && note.noteType.length > 0)
          {
            var typeInt:Null<Int> = state.noteTypeMap.get(state.curSelectedNote[3]);
            var theType:String = '' + typeInt;
            if (typeInt == null) theType = '?';

            var daText:AttachedFlxText = new AttachedFlxText(0, 0, 100, theType, 24);
            daText.setFormat(Paths.font("vcr.ttf"), 24, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
            daText.xAdd = -32;
            daText.yAdd = 6;
            daText.borderSize = 1;
            state.curRenderedNoteType.add(daText);
            daText.sprTracker = note;
          }
          note.mustPress = state._song.notes[ChartingState.curSec].mustHitSection;
          if (state.curSelectedNote[1] > 3) note.mustPress = !note.mustPress;
      }
      state.updateNoteUI();
    }
    ChartingState.unsavedChanges = true;
  }

  public static function changeNoteSustain(state:ChartingState, value:Float):Void
  {
    if (state.curSelectedNote != null)
    {
      if (state.curSelectedNote[2] != null)
      {
        state.curSelectedNote[2] += value;

        // actually fixes an issue where step-long sustain lengths would round down instead of up
        state.curSelectedNote[2] = Math.ceil(state.curSelectedNote[2] * 13) / 13;
        state.curSelectedNote[2] = Math.max(state.curSelectedNote[2], 0);
      }
    }

    state.updateNoteUI();
    state.updateGrid(false);
  }

  // will figure this out l8r
  public static function redo(state:ChartingState)
  {
    // state._song = state.redos[state.curRedoIndex];
  }
}
