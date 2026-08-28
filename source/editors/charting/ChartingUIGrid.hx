package editors.charting;

// REFACTOR: extracted from editors.ChartingState (behavior-preserving)
import backend.ClientPrefs;
import backend.Conductor;
import backend.CoolUtil;
import backend.DiscordClient;
import backend.Paths;
import data.Section.SwagSection;
import editors.ChartingState;
import editors.charting.AttachedFlxText;
import objects.Note;
import play.PlayState;

// REFACTOR: imports for relocated root classes
import shaders.CrossFade;

@:access(editors.ChartingState)
@:access(backend.MusicBeatState)
class ChartingUIGrid
{
  public static function sectionStartTime(state:ChartingState, add:Int = 0):Float
  {
    var daBPM:Float = state._song.bpm;
    var daPos:Float = 0;
    for (i in 0...ChartingState.curSec + add)
    {
      if (state._song.notes[i] != null)
      {
        if (state._song.notes[i].changeBPM)
        {
          daBPM = state._song.notes[i].bpm;
        }
        daPos += state.getSectionBeats(i) * (1000 * 60 / daBPM);
      }
    }
    return daPos;
  }

  public static function getSectionBeats(state:ChartingState, ?section:Null<Int> = null)
  {
    if (section == null) section = ChartingState.curSec;
    var val:Null<Float> = null;

    if (state._song.notes[section] != null) val = state._song.notes[section].sectionBeats;
    return val != null ? val : 4;
  }

  public static function addSection(state:ChartingState, sectionBeats:Float = 4):Void
  {
    var sec:SwagSection =
      {
        sectionBeats: (state._song.notes[ChartingState.curSec] != null ? state.getSectionBeats() : sectionBeats),
        bpm: state._song.bpm,
        changeBPM: false,
        mustHitSection: (state._song.notes[ChartingState.curSec] != null ? state._song.notes[ChartingState.curSec].mustHitSection : true),
        gfSection: false,
        sectionNotes: [],
        typeOfSection: 0,
        altAnim: false,
			  crossFade: false
      };

    state._song.notes.push(sec);
  }

  public static function getStrumTime(state:ChartingState, yPos:Float, doZoomCalc:Bool = true):Float
  {
    var leZoom:Float = state.zoomList[state.curZoom];
    if (!doZoomCalc) leZoom = 1;
    return FlxMath.remapToRange(yPos, state.gridBG.y, state.gridBG.y + state.gridBG.height * leZoom, 0, 16 * Conductor.stepCrochet);
  }

  public static function getYfromStrum(state:ChartingState, strumTime:Float, doZoomCalc:Bool = true):Float
  {
    var leZoom:Float = state.zoomList[state.curZoom];
    if (!doZoomCalc) leZoom = 1;
    return FlxMath.remapToRange(strumTime, 0, 16 * Conductor.stepCrochet, state.gridBG.y, state.gridBG.y + state.gridBG.height * leZoom);
  }

  public static function getYfromStrumNotes(state:ChartingState, strumTime:Float, beats:Float):Float
  {
    var value:Float = strumTime / (beats * 4 * Conductor.stepCrochet);
    return ChartingState.GRID_SIZE * beats * 4 * state.zoomList[state.curZoom] * value + state.gridBG.y;
  }

  public static function strumLineUpdateY(state:ChartingState)
  {
    state.strumLine.y = state.getYfromStrum((Conductor.songPosition - state.sectionStartTime()) / state.zoomList[state.curZoom] % (Conductor.stepCrochet * 16)) / (state.getSectionBeats() / 4);
  }

  public static function updateZoom(state:ChartingState)
  {
    var daZoom:Float = state.zoomList[state.curZoom];
    var zoomThing:String = '1 / ' + daZoom;
    if (daZoom < 1) zoomThing = Math.round(1 / daZoom) + ' / 1';
    state.zoomTxt.text = 'Zoom: ' + zoomThing;
    state.reloadGridLayer();
  }

  public static function reloadGridLayer(state:ChartingState)
  {
    var curBeats:Float = state.getSectionBeats();
    var hasNextSec:Bool = state.sectionStartTime(1) <= FlxG.sound.music.length;
    var nextBeats:Float = hasNextSec ? state.getSectionBeats(ChartingState.curSec + 1) : 0;

    if (state.gridBG != null && state.gridLayer != null && state.curZoom == state.lastGridZoom && curBeats == state.lastGridBeats && nextBeats == state.lastGridBeatsNext
      && state.showTheGrid == state.lastGridShow && ChartingState.vortex == state.lastGridVortex && hasNextSec == state.lastGridHasNext && Std.int(state.gridBG.height) == state.lastGridBGHeight)
    {
      state.lastSecBeats = curBeats;
      state.lastSecBeatsNext = nextBeats;
      return;
    }

    state.gridLayer.clear();
    if (state.showTheGrid) state.gridBG = FlxGridOverlay.create(ChartingState.GRID_SIZE, ChartingState.GRID_SIZE, ChartingState.GRID_SIZE * 9, Std.int(ChartingState.GRID_SIZE * curBeats * 4 * state.zoomList[state.curZoom]));
    else
      state.gridBG = new FlxSprite().makeGraphic(Std.int(ChartingState.GRID_SIZE * 9), Std.int(ChartingState.GRID_SIZE * curBeats * 4 * state.zoomList[state.curZoom]), 0xffe7e6e6);

    #if desktop
    if (FlxG.save.data.chart_waveformInst || FlxG.save.data.chart_waveformVoices || FlxG.save.data.chart_waveformOppVoices)
    {
      state.updateWaveform();
    }
    #end

    var leHeight:Int = Std.int(state.gridBG.height);
    var foundNextSec:Bool = false;
    if (hasNextSec)
    {
      if (state.showTheGrid)
      {
        // If state.showTheGrid is enabled, create a grid overlay for the next section
        var nextHeight:Int = Std.int(ChartingState.GRID_SIZE * nextBeats * 4 * state.zoomList[state.curZoom]);
        if (nextHeight == Std.int(state.gridBG.height))
        {
          state.nextGridBG = new FlxSprite(state.gridBG.x, state.gridBG.height, state.gridBG.graphic);
        } else
        {
          state.nextGridBG = FlxGridOverlay.create(ChartingState.GRID_SIZE, ChartingState.GRID_SIZE, ChartingState.GRID_SIZE * 9, nextHeight);
        }
        leHeight = Std.int(state.gridBG.height + state.nextGridBG.height);
        foundNextSec = true;
      } else
      { // Else, make a simple gray graphic
        state.nextGridBG = new FlxSprite().makeGraphic(1, 1, FlxColor.TRANSPARENT);
      }
    }
    if (foundNextSec) state.nextGridBG.y = state.gridBG.height;

    if (state.nextGridBG != null) state.gridLayer.add(state.nextGridBG);
    state.gridLayer.add(state.gridBG);

    if (foundNextSec)
    {
      var gridBlack:FlxSprite = new FlxSprite(0, state.gridBG.height).makeGraphic(Std.int(ChartingState.GRID_SIZE * 9), Std.int(state.nextGridBG.height), FlxColor.BLACK);
      gridBlack.alpha = 0.4;
      state.gridLayer.add(gridBlack);
    }

    var gridBlackLine:FlxSprite = new FlxSprite(state.gridBG.x + state.gridBG.width - (ChartingState.GRID_SIZE * 4)).makeGraphic(2, leHeight, FlxColor.BLACK);
    state.gridLayer.add(gridBlackLine);

    for (i in 1...4)
    {
      var beatsep1:FlxSprite = new FlxSprite(state.gridBG.x, (ChartingState.GRID_SIZE * (4 * state.curZoom)) * i).makeGraphic(Std.int(state.gridBG.width), 1, 0x44FF0000);
      if (ChartingState.vortex)
      {
        state.gridLayer.add(beatsep1);
      }
    }

    var gridBlackLine:FlxSprite = new FlxSprite(state.gridBG.x + ChartingState.GRID_SIZE).makeGraphic(2, leHeight, FlxColor.BLACK);
    state.gridLayer.add(gridBlackLine);
    state.updateGrid(false);

    state.lastSecBeats = curBeats;
    state.lastSecBeatsNext = nextBeats;
    state.lastGridZoom = state.curZoom;
    state.lastGridBeats = curBeats;
    state.lastGridBeatsNext = nextBeats;
    state.lastGridShow = state.showTheGrid;
    state.lastGridVortex = ChartingState.vortex;
    state.lastGridHasNext = hasNextSec;
    state.lastGridBGHeight = Std.int(state.gridBG.height);
  }

  public static function setupNoteData(state:ChartingState, i:Array<Dynamic>, isNextSection:Bool):Note
  {
    var daNoteInfo = i[1];
    var daStrumTime = i[0];
    var daSus:Dynamic = i[2];

    var note:Note = new Note(daStrumTime, daNoteInfo % 4);
    note.strumTime = daStrumTime;
    note.noteData = daNoteInfo % 4;
    if (daSus != null)
    { // Common note
      if (!Std.isOfType(i[3], String)) // Convert old note type to new note type format
      {
        i[3] = state.noteTypeIntMap.get(i[3]);
      }
      if (i.length > 3 && (i[3] == null || i[3].length < 1))
      {
        i.remove(i[3]);
      }
      note.sustainLength = daSus;
      note.noteType = i[3];
      note.animation.play(Note.colArray[daNoteInfo % 4] + 'Scroll');
      if (ClientPrefs.enableColorShader) note.updateRGBColors();
    } else
    { // Event note
      note.loadGraphic(Paths.image('eventArrow'));
      note.eventName = state.getEventName(i[1]);
      note.eventLength = i[1].length;
      if (i[1].length < 2)
      {
        note.eventVal1 = i[1][0][1];
        note.eventVal2 = i[1][0][2];
      }
      note.noteData = -1;
      daNoteInfo = -1;
      note.useRGBShader = false;
    }

    note.setGraphicSize(ChartingState.GRID_SIZE, ChartingState.GRID_SIZE);
    note.updateHitbox();
    note.x = Math.floor(daNoteInfo * ChartingState.GRID_SIZE) + ChartingState.GRID_SIZE;
    if (isNextSection && state._song.notes[ChartingState.curSec].mustHitSection != state._song.notes[ChartingState.curSec + 1].mustHitSection)
    {
      if (daNoteInfo > 3)
      {
        note.x -= ChartingState.GRID_SIZE * 4;
      } else if (daSus != null)
      {
        note.x += ChartingState.GRID_SIZE * 4;
      }
    }

    var beats:Float = state.getSectionBeats(isNextSection ? 1 : 0);
    note.y = state.getYfromStrumNotes(daStrumTime - state.sectionStartTime(), beats);
    // if(isNextSection) note.y += state.gridBG.height;
    if (note.y < -150) note.y = -150;
    return note;
  }

  public static function getEventName(names:Array<Dynamic>):String
  {
    var retStr:String = '';
    var addedOne:Bool = false;
    for (i in 0...names.length)
    {
      if (addedOne) retStr += ', ';
      retStr += names[i][0];
      addedOne = true;
    }
    return retStr;
  }

  public static function setupSusNote(state:ChartingState, note:Note, beats:Float):FlxSprite
  {
    var height:Int = Math.floor(FlxMath.remapToRange(note.sustainLength, 0, Conductor.stepCrochet * 16, 0, ChartingState.GRID_SIZE * 16 * state.zoomList[state.curZoom])
      + (ChartingState.GRID_SIZE * state.zoomList[state.curZoom])
      - ChartingState.GRID_SIZE / 2);
    var minHeight:Int = Std.int((ChartingState.GRID_SIZE * state.zoomList[state.curZoom] / 2) + ChartingState.GRID_SIZE / 2);
    if (height < minHeight) height = minHeight;
    if (height < 1) height = 1; // Prevents error of invalid height

    var color:FlxColor = (!PlayState.isPixelStage) ? ClientPrefs.arrowRGB[note.noteData][0] : ClientPrefs.arrowRGBPixel[note.noteData][0];

    if (note.noteType == "Hurt Note") color = CoolUtil.dominantColor(note); // Make black if hurt note

    var spr:FlxSprite = new FlxSprite(note.x + (ChartingState.GRID_SIZE * 0.5) - 4, note.y + ChartingState.GRID_SIZE / 2).makeGraphic(8, height, color);
    if (note.noteType != 'Hurt Note')
    {
      spr.color = color;
    }
    return spr;
  }

  public static function updateGrid(state:ChartingState, ?andNext:Bool = true, ?onlyEvents:Bool = false):Void
  {
    state.curRenderedEventText.forEach(txt -> {
      state.curRenderedEventText.remove(txt, true);
      txt.destroy();
    });
    state.curRenderedNotes.forEach(note -> {
      if (note.noteData == -1)
      {
        state.curRenderedNotes.remove(note, true);
        note.destroy();
      }
    });
    state.curRenderedEventText.clear();
    if (andNext)
    {
      state.nextRenderedNotes.forEach(event -> {
        if (event.noteData == -1)
        {
          state.nextRenderedNotes.remove(event, true);
          event.destroy();
        }
      });
    }
    state.curRenderedSustains.clear();
    if (!onlyEvents)
    {
      // classic fnf styled grid updating
      while (state.curRenderedNotes.length > 0)
      {
        state.curRenderedNotes.remove(state.curRenderedNotes.members[0], true);
      }

      while (state.curRenderedSustains.length > 0)
      {
        state.curRenderedSustains.remove(state.curRenderedSustains.members[0], true);
      }
      state.curRenderedNotes.clear();
      state.curRenderedSustains.clear();
      state.curRenderedNoteType.forEach(txt -> {
        state.curRenderedNoteType.remove(txt, true);
        txt.destroy();
      });
      state.curRenderedNoteType.clear();
      // Why did i remove this?
      if (andNext)
      {
        state.nextRenderedNotes.forEach(TheNoteThatShouldBeKilledBecauseWeDontNeedIt -> {
          state.nextRenderedNotes.remove(TheNoteThatShouldBeKilledBecauseWeDontNeedIt, true);
          TheNoteThatShouldBeKilledBecauseWeDontNeedIt.destroy();
        });
        state.nextRenderedNotes.clear();
        state.nextRenderedSustains.clear();
      }

      if (state._song.notes[ChartingState.curSec] != null)
      {
        if (state._song.notes[ChartingState.curSec].changeBPM && state._song.notes[ChartingState.curSec].bpm > 0)
        {
          Conductor.changeBPM(state._song.notes[ChartingState.curSec].bpm);
          // trace('BPM of this section:');
        } else
        {
          // get last bpm
          var daBPM:Float = state._song.bpm;
          for (i in 0...ChartingState.curSec)
            if (state._song.notes[i].changeBPM) daBPM = state._song.notes[i].bpm;
          Conductor.changeBPM(daBPM);
        }

        // CURRENT SECTION
        var beats:Float = state.getSectionBeats();
        for (i in state._song.notes[ChartingState.curSec].sectionNotes)
        {
          var note:Note = state.setupNoteData(i, false);
          state.curRenderedNotes.add(note);
          if (note.sustainLength > 0)
          {
            state.curRenderedSustains.add(state.setupSusNote(note, beats));
          }

          if (i[3] != null && note.noteType != null && note.noteType.length > 0)
          {
            var typeInt:Null<Int> = state.noteTypeMap.get(i[3]);
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
          if (i[1] > 3) note.mustPress = !note.mustPress;
        }
      }
    }

    // CURRENT EVENTS
    var startThing:Float = state.sectionStartTime();
    var endThing:Float = state.sectionStartTime(1);
    for (i in state._song.events)
    {
      if (endThing > i[0] && i[0] >= startThing)
      {
        var note:Note = state.setupNoteData(i, false);
        state.curRenderedNotes.add(note);

        var text:String = 'Event: ' + note.eventName + ' (' + Math.floor(note.strumTime) + ' ms)' + '\nValue 1: ' + note.eventVal1 + '\nValue 2: '
          + note.eventVal2;
        if (note.eventLength > 1) text = note.eventLength + ' Events:\n' + note.eventName;

        var daText:AttachedFlxText = new AttachedFlxText(0, 0, 400, text, 12);
        daText.setFormat(Paths.font("vcr.ttf"), 12, FlxColor.WHITE, RIGHT, FlxTextBorderStyle.OUTLINE_FAST, FlxColor.BLACK);
        daText.xAdd = -410;
        daText.borderSize = 1;
        if (note.eventLength > 1) daText.yAdd += 8;
        state.curRenderedEventText.add(daText);
        daText.sprTracker = note;
        // trace('test: ' + i[0], 'startThing: ' + startThing, 'endThing: ' + endThing);
      }
    }

    if (andNext)
    {
      if (!onlyEvents)
      {
        // NEXT SECTION, which shouldnt even update if you're in the current section
        var beats:Float = state.getSectionBeats(1);
        if (ChartingState.curSec < state._song.notes.length - 1)
        {
          for (i in state._song.notes[ChartingState.curSec + 1].sectionNotes)
          {
            var note:Note = state.setupNoteData(i, true);
            note.alpha = 0.6;
            state.nextRenderedNotes.add(note);
            if (note.sustainLength > 0)
            {
              state.nextRenderedSustains.add(state.setupSusNote(note, beats));
            }
          }
        }
      }

      // NEXT EVENTS
      var startThing:Float = state.sectionStartTime(1);
      var endThing:Float = state.sectionStartTime(2);
      for (i in state._song.events)
      {
        if (endThing > i[0] && i[0] >= startThing)
        {
          var note:Note = state.setupNoteData(i, true);
          note.alpha = 0.6;
          state.nextRenderedNotes.add(note);
        }
      }
    }
    #if DISCORD_ALLOWED
    // Updating Discord Rich Presence (for updating Note Count)
    DiscordClient.changePresence("Chart Editor - Charting " + StringTools.replace(state._song.song, '-', ' '),
      '${FlxStringUtil.formatMoney(CoolUtil.getNoteAmount(state._song), false)} Notes');
    #end
  }

  public static function updateNoteUI(state:ChartingState):Void
  {
    if (state.curSelectedNote != null)
    {
      if (state.curSelectedNote[2] != null)
      {
        state.stepperSusLength.value = state.curSelectedNote[2];
        if (state.curSelectedNote[3] != null)
        {
          state.currentType = state.noteTypeMap.get(state.curSelectedNote[3]);
          if (state.currentType <= 0)
          {
            state.noteTypeDropDown.selectedLabel = '';
          } else
          {
            state.noteTypeDropDown.selectedLabel = state.currentType + '. ' + state.curSelectedNote[3];
          }
        }
      } else
      {
        state.eventDropDown.selectedLabel = state.curSelectedNote[1][state.curEventSelected][0];
        var selected:Int = Std.parseInt(state.eventDropDown.selectedId);
        if (selected > 0 && selected < state.eventStuff.length)
        {
          state.descText.text = state.eventStuff[selected][1];
        }
        state.value1InputText.text = state.curSelectedNote[1][state.curEventSelected][1];
        state.value2InputText.text = state.curSelectedNote[1][state.curEventSelected][2];
      }
      state.strumTimeInputText.text = '' + state.curSelectedNote[0];
    }
  }
}
