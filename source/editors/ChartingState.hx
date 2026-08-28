package editors;

// REFACTOR: explicit imports for shader subtypes
import editors.charting.ChartingUISections;
import shaders.RGBPalette.RGBShaderReference;

import objects.Character.CharacterFile;
import backend.Conductor.BPMChangeEvent;
import data.Section.SwagSection;
import data.Song.SwagSong;
import backend.MusicBeatState;
import backend.Paths;
import backend.CoolUtil;
import backend.Conductor;
import backend.ClientPrefs;
import backend.DiscordClient;
import states.TitleState;
import states.LoadingState;
import play.PlayState;
import objects.AttachedSprite;
import objects.HealthIcon;
import objects.StrumNote;
import objects.Note;
import objects.NoteHelpers;
import objects.FlxUIDropDownMenuCustom;
import objects.Prompt;
import data.Song;
import data.Section;
import data.StageData;
import editors.charting.AttachedFlxText;
import editors.charting.ChartingSaveLoad;
import editors.charting.ChartingUIGrid;
import editors.charting.ChartingUIWaveform;
import editors.charting.ChartingEvents;
import editors.charting.SelectionNote;
import flixel.addons.ui.FlxInputText;
import flixel.addons.ui.FlxUI9SliceSprite;
import flixel.addons.ui.FlxUI;
import flixel.addons.ui.FlxUICheckBox;
import flixel.addons.ui.FlxUIInputText;
import flixel.addons.ui.FlxUINumericStepper;
import flixel.addons.ui.FlxUISlider;
import flixel.addons.ui.FlxUITabMenu;
import flixel.group.FlxGroup;
import flixel.input.keyboard.FlxKey;
import flixel.ui.FlxButton;
import flixel.ui.FlxSpriteButton;
import flixel.util.FlxSort;
import haxe.format.JsonParser;
import haxe.io.Bytes;
import lime.media.AudioBuffer;
import lime.ui.FileDialog;
import lime.ui.FileDialogType;
import openfl.Lib;
import openfl.events.Event;
import openfl.events.IOErrorEvent;
import openfl.events.UncaughtErrorEvent;
import openfl.geom.Rectangle;
import openfl.media.Sound;
import openfl.net.FileReference;
import openfl.utils.ByteArray;
import shaders.RGBPalette;

// REFACTOR: imports for relocated root classes
import backend.Controls;
import objects.Character;

@:access(flixel.sound.FlxSound._sound)
@:access(openfl.media.Sound.__buffer)
class ChartingState extends MusicBeatState
{
  public static var noteTypeList:Array<String> = // Used for backwards compatibility with 0.1 - 0.3.2 charts, though, you should add your hardcoded custom note types here too.
    [
      '',
      'Alt Animation',
      'Hey!',
      'Hurt Note',
      'GF Sing',
      'No Animation',
	  'Cross Fade',
	  'GF Cross Fade'
    ];

  private var noteTypeIntMap:Map<Int, String> = new Map<Int, String>();
  private var noteTypeMap:Map<String, Null<Int>> = new Map<String, Null<Int>>();

  public var ignoreWarnings = false;
  public var showTheGrid = false;
  public var undos = [];
  public var redos = [];
  var lastUndoShit:String = null;

  var eventStuff:Array<Dynamic> = [
    ['', "Nothing. Yep, that's right."],
    ['Nothing', "Nothing 2: Electric Boogaloo"],
    [
      'Dadbattle Spotlight',
      "Used in Dad Battle,\nValue 1: 0/1 = ON/OFF,\n2 = Target Dad\n3 = Target BF"
    ],
    [
      'Hey!',
      "Plays the \"Hey!\" animation from Bopeebo,\nValue 1: BF = Only Boyfriend, GF = Only Girlfriend,\nSomething else = Both.\nValue 2: Custom animation duration,\nleave it blank for 0.6s"
    ],
    [
      'Set GF Speed',
      "Sets GF head bopping speed,\nValue 1: 1 = Normal speed,\n2 = 1/2 speed, 4 = 1/4 speed etc.\nUsed on Fresh during the beatbox parts.\n\nWarning: Value must be integer!"
    ],
    [
      'Set Camera Zoom',
      "Sets the camera zoom. Used in the Erect Remixes\nValue 1: New zoom value"
    ],
    [
      'Philly Glow',
      "Exclusive to Week 3\nValue 1: 0/1/2 = OFF/ON/Reset Gradient\n \nNo, i won't add it to other weeks."
    ],
    ['Kill Henchmen', "For Mom's songs, don't use this please, i love them :("],
    [
      'Add Camera Zoom',
      "Used on MILF on that one \"hard\" part\nValue 1: Camera zoom add (Default: 0.015)\nValue 2: UI zoom add (Default: 0.03)\nLeave the values blank if you want to use Default."
    ],
    ['BG Freaks Expression', "Should be used only in \"school\" Stage!"],
    ['Trigger BG Ghouls', "Should be used only in \"schoolEvil\" Stage!"],
    [
      'Play Animation',
      "Plays an animation on a Character,\nonce the animation is completed,\nthe animation changes to Idle\n\nValue 1: Animation to play.\nValue 2: Character (Dad, BF, GF)"
    ],
    [
      'Camera Follow Pos',
      "Value 1: X\nValue 2: Y\n\nThe camera won't change the follow point\nafter using this, for getting it back\nto normal, leave both values blank."
    ],
    [
      'Alt Idle Animation',
      "Sets a specified suffix after the idle animation name.\nYou can use this to trigger 'idle-alt' if you set\nValue 2 to -alt\n\nValue 1: Character to set (Dad, BF or GF)\nValue 2: New suffix (Leave it blank to disable)"
    ],
    [
      'Enable Camera Bop',
      "Enables camera bopping. Useful if you don't want the\nopponent to hit a note, but you want camera bouncing."
    ],
    [
      'Disable Camera Bop',
      "Same thing as 'Enable Camera Bopping', but disables it\ninstead."
    ],
    ['Enable Bot Energy', "Enables Bot Energy. It's useful for spamcharts!"],
    [
      'Disable Bot Energy',
      "Same thing as 'Enable Bot Energy', but disables it\ninstead."
    ],
    [
      'Set Bot Energy Speeds',
      "Sets the speeds of Bot Energy draining and refilling.\n\nValue 1: Drain speed.\nValue 2: Refill speed"
    ],
    [
      'Change Song Name',
      "Changes the song name to whatever value 1 is set to.\nIf value 1 is empty, the name will reset back to the original song name."
    ],
    [
      'Rainbow Eyesore',
      "Flashing lights that might hurt your eyes,\nhence the name.\n\nValue 1: Step to end at\nValue 2: Speed"
    ],
    [
      'Popup',
      "Value 1: Title\nValue 2: Message\nMakes a window popup with a message in it."
    ],
    [
      'Popup (No Pause)',
      "Value 1: Title\nValue 2: Message\nSame as popup but without a pause."
    ],
    [
      'Credits Popup',
      "Makes some credits pop up. \n\nValue 1: The title. \nValue 2: The composer(s)"
    ],
    [
      'Screen Shake',
      "Value 1: Camera shake\nValue 2: HUD shake\n\nEvery value works as the following example: \"1, 0.05\".\nThe first number (1) is the duration.\nThe second number (0.05) is the intensity."
    ],
    [
      'Tween Camera Zoom',
      "Cool Camera Zoom Tween\n\nValue 1: Zoom level(leave empty OR put 'default' for default)\nValue 2: Duration\nValue 3 (split value 2 with a ','): Ease"
    ],
    [
      'Camera Bopping',
      "Makes the camera do funny bopping\n\nValue 1: Bopping Speed (how many beats you want before it bops)\nValue 2: Bopping Intensity (how hard you want it to bop, default is 1)\n\nTo reset camera bopping, place a new event and put both values as '4' and '1' respectively."
    ],
    [
      'Camera Twist',
      "Makes the camera spin!! or twist ig\nValue 1: Twist intensity\nValue 2: Twist intensity 2"
    ],
    [
      'Change Note Multiplier',
      "Changes the amount of notes played every time you hit a note.\n\nValue 1 for NM\nValue 2 for Which (1 = Oppo, 2 = BF)\nLeave V2 empty for both."
    ], // nael revamped this!
    [
      'Fake Song Length',
      "Shows a fake song length on the time bar.\n\nValue 1: The fake length (in seconds)\nValue 2: Should it tween? (true = yes, anything else = no)\nTo reset the song length to normal, make Value 1 null."
    ],
    [
      'Change Character',
      "Value 1: Character to change (Dad, BF, GF)\nValue 2: New character's name"
    ],
    [
      'Change Scroll Speed',
      "Value 1: Scroll Speed Multiplier (1 is default)\nValue 2: Time it takes to change fully in seconds."
    ],
    ['Set Property', "Value 1: Variable name\nValue 2: New value"],
    [
      'Windows Notification',
      "Value 1: Notification title\n    - Defaults to \"JS Engine\" if empty.\n\nValue 2: Notification message / info\n    - Defaults to \"Are you doing that one bambi song?\" if empty."
    ]
  ];

  var _file:FileReference;

  var UI_box:FlxUITabMenu;

  public static var goToPlayState:Bool = false;

  /**
   * Array of notes showing when each section STARTS in STEPS
   * Usually rounded up??
   */
  public static var curSec:Int = 0;

  public static var lastSection:Int = 0;
  private static var lastSong:String = '';

  var difficulty:String = 'normal';
  var specialAudioName:String = '';
  var specialEventsName:String = '';

  var bpmTxt:FlxText;
  var songSlider:FlxUISlider;

  var camPos:FlxObject;
  var strumLine:FlxSprite;
  var quant:AttachedSprite;
  var strumLineNotes:FlxTypedGroup<StrumNote>;
  var curSong:String = 'Test';
  var amountSteps:Int = 0;
  var bullshitUI:FlxGroup;

  var highlight:FlxSprite;

  public static inline var GRID_SIZE:Int = 40;

  var CAM_OFFSET:Int = 360;

  var selectionNote:SelectionNote;
  var selectionEvent:FlxSprite;

  var curRenderedSustains:FlxTypedGroup<FlxSprite>;
  var curRenderedNotes:FlxTypedGroup<Note>;
  var curRenderedNoteType:FlxTypedGroup<AttachedFlxText>;
  var curRenderedEventText:FlxTypedGroup<AttachedFlxText>;

  var nextRenderedSustains:FlxTypedGroup<FlxSprite>;
  var nextRenderedNotes:FlxTypedGroup<Note>;

  var gridBG:FlxSprite;
  var nextGridBG:FlxSprite;

  var daquantspot = 0;
  var curEventSelected:Int = 0;
  var curUndoIndex = 0;
  var curRedoIndex = 0;
  var _song:SwagSong;
  /*
   * WILL BE THE CURRENT / LAST PLACED NOTE
  **/
  var curSelectedNote:Array<Dynamic> = null;

  var playbackSpeed:Float = 1;

  var vocals:FlxSound = null;
  var opponentVocals:FlxSound = null;

  var idleMusic:EditingMusic;

  var leftIcon:HealthIcon;
  var rightIcon:HealthIcon;

  var lilStage:FlxSprite;
  var lilBf:FlxSprite;
  var lilOpp:FlxSprite;

  var value1InputText:FlxUIInputText;
  var value2InputText:FlxUIInputText;
  var currentSongName:String;
  var autosaveIndicator:FlxSprite;
  var hitsound:FlxSound = null;

  var zoomTxt:FlxText;

  var zoomList:Array<Float> = [0.0625, 0.125, 0.25, 0.5, 1, 2, 3, 4, 6, 8, 12, 16, 24, 32, 48, 64, 96, 128, 192];
  var curZoom:Int = 4;

  private var blockPressWhileTypingOn:Array<FlxUIInputText> = [];
  private var blockPressWhileTypingOnStepper:Array<FlxUINumericStepper> = [];
  private var blockPressWhileScrolling:Array<FlxUIDropDownMenuCustom> = [];

  var waveformSprite:FlxSprite;
  var gridLayer:FlxTypedGroup<FlxSprite>;

  public static var quantization:Int = 16;
  public static var curQuant = 3;

  public var quantizations:Array<Int> = [4, 8, 12, 16, 20, 24, 32, 48, 64, 96, 192, 384, 768];

  public static var idleMusicAllow:Bool = false;
  public static var unsavedChanges:Bool = false;

  var text:String = "";

  public static var vortex:Bool = false;

  public var mouseQuant:Bool = false;
  public var hitsoundVol:Float = 1;

  var autoSaveTimer:FlxTimer;

  public var autoSaveLength:Int = 240; // 4 minutes (DEFAULT), probably long but less lag

  override function create()
  {
    idleMusic = new EditingMusic();
    undos = [];
    redos = [];
    if (PlayState.SONG != null) _song = PlayState.SONG;
    else
    {
      CoolUtil.difficulties = CoolUtil.defaultDifficulties.copy();

      _song =
        {
          song: 'Test',
          notes: [],
          events: [],
          bpm: 150.0,
          needsVoices: true,
          arrowSkin: '',
          splashSkin: 'noteSplashes', // idk it would crash if i didn't
          player1: 'bf',
          player2: 'dad',
          gfVersion: 'gf',
          songCredit: '',
          songCreditBarPath: '',
          songCreditIcon: '',
          windowName: '',
          specialAudioName: '',
          specialEventsName: '',
          event7: '',
          event7Value: '',
          speed: 1,
          stage: 'stage'
        };
      addSection();
      PlayState.SONG = _song;
    }
    difficulty = CoolUtil.currentDifficulty;
    specialAudioName = _song.specialAudioName;
    specialEventsName = _song.specialEventsName;
    hitsound = FlxG.sound.load(Paths.sound("hitsounds/osu!mania"));
    hitsound.volume = 1;

    if (Note.globalRgbShaders.length > 0) Note.globalRgbShaders = [];
    Paths.initDefaultSkin(_song.arrowSkin, true);

    #if DISCORD_ALLOWED
    // Updating Discord Rich Presence
    DiscordClient.changePresence("Chart Editor - Charting " + StringTools.replace(_song.song, '-', ' '),
      '${FlxStringUtil.formatMoney(CoolUtil.getNoteAmount(_song), false)} Notes');
    #end

    FlxG.autoPause = true; // this might help with some issues

    vortex = FlxG.save.data.chart_vortex;
    showTheGrid = FlxG.save.data.showGrid;
    idleMusicAllow = FlxG.save.data.idleMusicAllowed;

    ignoreWarnings = FlxG.save.data.ignoreWarnings;
    var bg:FlxSprite = new FlxSprite().loadGraphic(Paths.image('menuDesat'));
    bg.scrollFactor.set();
    bg.color = 0xFF222222;
    add(bg);

    lilStage = new FlxSprite(32, 432).loadGraphic(Paths.image("chartEditor/lilStage"));
    lilStage.scrollFactor.set();
    add(lilStage);

    lilBf = new FlxSprite(32, 432).loadGraphic(Paths.image("chartEditor/lilBf"), true, 300, 256);
    lilBf.animation.add("idle", [0, 1], 12, true);
    lilBf.animation.add("0", [3, 4, 5], 12, false);
    lilBf.animation.add("1", [6, 7, 8], 12, false);
    lilBf.animation.add("2", [9, 10, 11], 12, false);
    lilBf.animation.add("3", [12, 13, 14], 12, false);
    lilBf.animation.add("yeah", [17, 20, 23], 12, false);
    lilBf.animation.play("idle");
    lilBf.animation.finishCallback = function(name:String) {
      lilBf.animation.play(name, true, false, lilBf.animation.getByName(name).numFrames - 2);
    }
    lilBf.scrollFactor.set();
    add(lilBf);

    lilOpp = new FlxSprite(32, 432).loadGraphic(Paths.image("chartEditor/lilOpp"), true, 300, 256);
    lilOpp.animation.add("idle", [0, 1], 12, true);
    lilOpp.animation.add("0", [3, 4, 5], 12, false);
    lilOpp.animation.add("1", [6, 7, 8], 12, false);
    lilOpp.animation.add("2", [9, 10, 11], 12, false);
    lilOpp.animation.add("3", [12, 13, 14], 12, false);
    lilOpp.animation.play("idle");
    lilOpp.animation.finishCallback = function(name:String) {
      lilOpp.animation.play(name, true, false, lilOpp.animation.getByName(name).numFrames - 2);
    }
    lilOpp.scrollFactor.set();
    add(lilOpp);
    lilBf.visible = FlxG.save.data.lilBuddies;
    lilOpp.visible = FlxG.save.data.lilBuddies;
    lilStage.visible = FlxG.save.data.lilBuddies;

    gridLayer = new FlxTypedGroup<FlxSprite>();
    add(gridLayer);

    waveformSprite = new FlxSprite(GRID_SIZE, 0).makeGraphic(FlxG.width, FlxG.height, 0x00FFFFFF);
    add(waveformSprite);

    var eventIcon:FlxSprite = new FlxSprite(-GRID_SIZE - 5, -90).loadGraphic(Paths.image('eventArrow'));
    leftIcon = new HealthIcon('bf');
    rightIcon = new HealthIcon('dad');
    eventIcon.scrollFactor.set(1, 1);
    leftIcon.scrollFactor.set(1, 1);
    rightIcon.scrollFactor.set(1, 1);

    eventIcon.setGraphicSize(30, 30);
    leftIcon.setGraphicSize(0, 45);
    rightIcon.setGraphicSize(0, 45);

    add(eventIcon);
    add(leftIcon);
    add(rightIcon);

    leftIcon.setPosition(GRID_SIZE + 10, -100);
    rightIcon.setPosition(GRID_SIZE * 5.2, -100);

    selectionNote = new SelectionNote(0, 0, 0);
    selectionNote.visible = false;
    var skin:String = Note.defaultNoteSkin + NoteHelpers.getNoteSkinPostfix();
    if (_song.arrowSkin != null && _song.arrowSkin.length > 1) skin = _song.arrowSkin;
    selectionNote.texture = skin;
    selectionNote.setGraphicSize(GRID_SIZE, GRID_SIZE);
    selectionNote.updateHitbox();
    selectionNote.playAnim('static', true);
    selectionNote.alpha = 0.75;
    add(selectionNote);

    selectionEvent = new FlxSprite().loadGraphic(Paths.image('eventArrow'));
    selectionEvent.setGraphicSize(GRID_SIZE, GRID_SIZE);
    selectionEvent.updateHitbox();
    selectionEvent.active = selectionEvent.visible = false;
    selectionEvent.alpha = 0.5;
    add(selectionEvent);

    curRenderedSustains = new FlxTypedGroup<FlxSprite>();
    curRenderedNotes = new FlxTypedGroup<Note>();
    curRenderedNoteType = new FlxTypedGroup<AttachedFlxText>();
    curRenderedEventText = new FlxTypedGroup<AttachedFlxText>();

    nextRenderedSustains = new FlxTypedGroup<FlxSprite>();
    nextRenderedNotes = new FlxTypedGroup<Note>();

    if (curSec >= _song.notes.length) curSec = _song.notes.length - 1;

    FlxG.mouse.visible = true;

    addSection();

    updateJsonData();
    currentSongName = Paths.formatToSongPath(_song.song);
    loadSong();
    reloadGridLayer();
    Conductor.changeBPM(_song.bpm);
    Conductor.mapBPMChanges(_song);

    bpmTxt = new FlxText(1000, 50, 0, "", 16);
    bpmTxt.scrollFactor.set();
    add(bpmTxt);

    strumLine = new FlxSprite(0, 50).makeGraphic(Std.int(GRID_SIZE * 9), 4);
    add(strumLine);

    quant = new AttachedSprite('chart_quant', 'chart_quant');
    quant.animation.addByPrefix('q', 'chart_quant', 0, false);
    quant.animation.play('q', true, false, 0);
    quant.sprTracker = strumLine;
    quant.xAdd = -32;
    quant.yAdd = 8;
    add(quant);

    strumLineNotes = new FlxTypedGroup<StrumNote>();
    for (i in 0...8)
    {
      var note:StrumNote = new StrumNote(GRID_SIZE * (i + 1), strumLine.y, i % 4, 0, true);
      note.setGraphicSize(GRID_SIZE, GRID_SIZE);
      note.updateHitbox();
      note.playAnim('static', true);
      strumLineNotes.add(note);
      note.scrollFactor.set(1, 1);
    }
    add(strumLineNotes);

    camPos = new FlxObject(0, 0, 1, 1);
    camPos.setPosition(strumLine.x + CAM_OFFSET, strumLine.y);

    var tabs = [
      {name: "Song", label: 'Song'},
      {name: "Section", label: 'Section'},
      {name: "Note", label: 'Note'},
      {name: "Events", label: 'Events'},
      {name: "Charting", label: 'Charting'},
      {name: "Data", label: 'Data'},
      {name: "Note Spamming", label: 'Note Spamming'},
    ];

    UI_box = new FlxUITabMenu(null, tabs, true);

    UI_box.resize(300, 400);
    UI_box.x = 640 + GRID_SIZE / 2;
    UI_box.y = 25;
    UI_box.scrollFactor.set();

    text = "W/S or Mouse Wheel - Change Conductor's strum time
		\nA/D - Go to the previous/next section
		\nLeft/Right - Change Snap
		\nUp/Down - Change Conductor's Strum Time with Snapping
		\nLeft Bracket / Right Bracket - Change Song Playback Rate (SHIFT to go Faster)
		\nALT + Left Bracket / Right Bracket - Reset Song Playback Rate
		\nHold Shift to move 4x faster
		\nHold CTRL to move 4x slower
		\nHold Control and click on an arrow to select it
		\nHold Alt and click on a note to change it to the selected note type
		\nHold CTRL and use the Mouse Wheel to decrease/increase the note's sustain length
		\nZ/X - Zoom in/out
		\nCTRL + Z - Undo
		\n
		\n(Hold) CTRL + Left/Right - Shift the currently selected note
		\nEsc - Test your chart inside Chart Editor
		\nEnter - Play your chart
		\nShift + Enter - Play your chart at the current section
		\nQ/E - Decrease/Increase Note Sustain Length
		\nSpace - Stop/Resume song";

		var tipTextArray:Array<String> = text.split('\n');
		for (i in 0...tipTextArray.length) {
			var tipText:FlxText = new FlxText(UI_box.x, UI_box.y + UI_box.height + 8, 0, tipTextArray[i], 20);
			tipText.y += i * 8;
			tipText.setFormat(Paths.font("vcr.ttf"), 12, FlxColor.WHITE, LEFT);
			tipText.scrollFactor.set();
			add(tipText);
		}
		add(UI_box);

	autoSaveLength = ClientPrefs.autosaveTime ?? 240;

    autosaveIndicator = new FlxSprite(-30, FlxG.height - 90).loadGraphic(Paths.image('autosaveIndicator'));
    autosaveIndicator.setGraphicSize(200, 70);
    autosaveIndicator.alpha = 0;
    autosaveIndicator.scrollFactor.set();
    autosaveIndicator.antialiasing = ClientPrefs.globalAntialiasing;
    add(autosaveIndicator);
    if (autoSaveTimer != null)
    {
      autoSaveTimer.cancel();
      autoSaveTimer = null;
      autosaveIndicator.alpha = 0;
    }
    // TODO: expand this more & maybe port the 1.0 system to here
    autoSaveTimer = new FlxTimer().start(autoSaveLength, function(tmr:FlxTimer) {
      if (!ClientPrefs.autosaveCharts) return;
      FlxTween.tween(autosaveIndicator, {alpha: 1}, 1,
        {
          ease: FlxEase.quadInOut,
          onComplete: function(twn:FlxTween) {
            FlxTween.tween(autosaveIndicator, {alpha: 0}, 1,
              {
                startDelay: 0.1,
                ease: FlxEase.quadInOut
              });
          }
        });
      saveLevel(true, true);
    }, 0);

    addSongUI();
    addSectionUI();
    addNoteUI();
    addEventsUI();
    addChartingUI();
    addNoteStackingUI();
    addSongDataUI();
    updateHeads();
    updateWaveform();
    // UI_box.selected_tab = 4;

    add(curRenderedSustains);
    add(curRenderedNotes);
    add(curRenderedNoteType);
    add(curRenderedEventText);
    add(nextRenderedSustains);
    add(nextRenderedNotes);

    songSlider = new FlxUISlider(FlxG.sound.music, 'time', 1000, 15, 0, FlxG.sound.music.length, 250, 15, 5);
    songSlider.valueLabel.visible = false;
    songSlider.maxLabel.visible = false;
    songSlider.minLabel.visible = false;
    add(songSlider);
    songSlider.scrollFactor.set();
    songSlider.callback = function(fuck:Float) {
      vocals.time = opponentVocals.time = FlxG.sound.music.time;
      var shit = Std.int(FlxG.sound.music.time / (Conductor.crochet * 4)); // TODO uhh make this work properly with bpm changes or somethin

      if (Conductor.bpmChangeMap.length > 0)
      {
        var foundSection:Bool = false;
        var sec:Int = 1;
        var lastSecStartTime:Float = 0;
        while (!foundSection)
        {
          var secStartTime = sectionStartTime(sec);
          if (FlxG.sound.music.time >= lastSecStartTime && FlxG.sound.music.time <= secStartTime)
          {
            shit = sec;
            foundSection = true;
          } else if (secStartTime >= FlxG.sound.music.length)
          {
            shit = 0;
            foundSection = true;
          }
          sec++;
          lastSecStartTime = secStartTime;
        }
      }

      changeSection(shit);
    };

    if (lastSong != currentSongName)
    {
      changeSection();
    }
    lastSong = currentSongName;

    zoomTxt = new FlxText(10, 10, 0, "Zoom: 1 / 1", 16);
    zoomTxt.scrollFactor.set();
    add(zoomTxt);

    if (idleMusicAllow) idleMusic.playMusic();
    else
      idleMusic.pauseMusic();

    updateGrid();

    super.create();
  }

  var check_mute_inst:FlxUICheckBox = null;
  var check_mute_vocals:FlxUICheckBox = null;
  var check_mute_vocals_opponent:FlxUICheckBox = null;
  var check_vortex:FlxUICheckBox = null;
  var check_showGrid:FlxUICheckBox = null;
  var check_warnings:FlxUICheckBox = null;
  var playSoundBf:FlxUICheckBox = null;
  var playSoundDad:FlxUICheckBox = null;
  var UI_songTitle:FlxUIInputText;
  var UI_songDiff:FlxUIInputText;
  var UI_specAudio:FlxUIInputText;
  var UI_specEvents:FlxUIInputText;
  var noteSkinInputText:FlxUIInputText;
  var noteSplashesInputText:FlxUIInputText;
  var stageDropDown:FlxUIDropDownMenuCustom;
  var sliderRate:FlxUISlider;

  // REFACTOR: delegated to editors.charting.ChartingUISections
  function addSongUI():Void
  {
    ChartingUISections.addSongUI(this);
  }

  // REFACTOR: delegated to editors.charting.ChartingSaveLoad
  function songJsonPopup()
  {
    ChartingSaveLoad.songJsonPopup(this);
  }

  // REFACTOR: delegated to editors.charting.ChartingSaveLoad
  function promptBackup()
  {
    ChartingSaveLoad.promptBackup(this);
  }

  var gameOverCharacterInputText:FlxUIInputText;
  var gameOverSoundInputText:FlxUIInputText;
  var gameOverLoopInputText:FlxUIInputText;
  var gameOverEndInputText:FlxUIInputText;
  var creditInputText:FlxUIInputText;
  var creditPathInputText:FlxUIInputText;
  var creditIconInputText:FlxUIInputText;
  var winNameInputText:FlxUIInputText;

  // REFACTOR: delegated to editors.charting.ChartingUISections
  function addSongDataUI():Void // therell be more added here later
  {
    ChartingUISections.addSongDataUI(this);
  }

  var stepperBeats:FlxUINumericStepper;
  var check_mustHitSection:FlxUICheckBox;
  var check_gfSection:FlxUICheckBox;
  var check_changeBPM:FlxUICheckBox;
  var stepperSectionBPM:FlxUINumericStepper;
  var check_altAnim:FlxUICheckBox;
  var check_crossFade:FlxUICheckBox;

  var sectionToCopy:Int = 0;
  var notesCopied:Array<Dynamic>;
  var CopyLastSectionCount:FlxUINumericStepper;
  var CopyFutureSectionCount:FlxUINumericStepper;
  var CopyLoopCount:FlxUINumericStepper;
  var copyMultiSectButton:FlxButton;

  var deleteSecStart:FlxUINumericStepper;
  var deleteSecEnd:FlxUINumericStepper;
  var deleteSections:FlxButton;

  // REFACTOR: delegated to editors.charting.ChartingUISections
  function addSectionUI():Void
  {
    ChartingUISections.addSectionUI(this);
  }

  var stepperSusLength:FlxUINumericStepper;
  var strumTimeInputText:FlxUIInputText; // I wanted to use a stepper but we can't scale these as far as i know :(
  var noteTypeDropDown:FlxUIDropDownMenuCustom;
  var currentType:Int = 0;

  // REFACTOR: delegated to editors.charting.ChartingUISections
  function addNoteUI():Void
  {
    ChartingUISections.addNoteUI(this);
  }

  var check_stackActive:FlxUICheckBox;
  var stepperStackNum:FlxUINumericStepper;
  var stepperStackOffset:FlxUINumericStepper;
  var stepperStackSideOffset:FlxUINumericStepper;
  var stepperShrinkAmount:FlxUINumericStepper;

  // REFACTOR: delegated to editors.charting.ChartingUISections
  function addNoteStackingUI():Void
  {
    ChartingUISections.addNoteStackingUI(this);
  }

  var eventDropDown:FlxUIDropDownMenuCustom;
  var descText:FlxText;
  var selectedEventText:FlxText;
  var event7DropDown:FlxUIDropDownMenuCustom;
  var event7InputText:FlxUIInputText;

  // REFACTOR: delegated to editors.charting.ChartingUISections
  function addEventsUI():Void
  {
    ChartingUISections.addEventsUI(this);
  }

  // REFACTOR: delegated to editors.charting.ChartingEvents
  function changeEventSelected(change:Int = 0)
  {
    ChartingEvents.changeEventSelected(this, change);
  }

  // REFACTOR: delegated to editors.charting.ChartingEvents
  function setAllLabelsOffset(button:FlxButton, x:Float, y:Float)
  {
    ChartingEvents.setAllLabelsOffset(button, x, y);
  }

  var metronome:FlxUICheckBox;
  var mouseScrollingQuant:FlxUICheckBox;
  var metronomeStepper:FlxUINumericStepper;
  var metronomeOffsetStepper:FlxUINumericStepper;
  var disableAutoScrolling:FlxUICheckBox;
  var lilBuddiesBox:FlxUICheckBox;
  var saveUndoCheck:FlxUICheckBox;
  var soundEffectsCheck:FlxUICheckBox;
  var idleMusicCheck:FlxUICheckBox;
  var instVolume:FlxUINumericStepper;
  var voicesVolume:FlxUINumericStepper;
  var voicesOppVolume:FlxUINumericStepper;
  var hitsoundVolume:FlxUINumericStepper;

  // REFACTOR: delegated to editors.charting.ChartingUISections
  function addChartingUI()
  {
    ChartingUISections.addChartingUI(this);
  }

  function pauseVocals()
  {
    if (vocals != null) vocals.pause();
    if (opponentVocals != null) opponentVocals.pause();
  }

  function pauseAndSetVocalsTime()
  {
    pauseVocals();
    if (vocals != null) vocals.time = FlxG.sound.music.time;

    if (opponentVocals != null) opponentVocals.time = FlxG.sound.music.time;
  }

  function loadSong():Void
  {
    if (FlxG.sound.music != null)
    {
      FlxG.sound.music.stop();
    }
    if (vocals != null)
    {
      vocals.stop();
      vocals.destroy();
    }
    if (opponentVocals != null)
    {
      opponentVocals.stop();
      opponentVocals.destroy();
    }

    waveformCacheSound = null;
    waveformCacheBytes = null;
    waveformCacheBuffer = null;

    var diff:String = (specialAudioName.length > 1 ? specialAudioName : difficulty).toLowerCase();
    vocals = new FlxSound();
    opponentVocals = new FlxSound();
    try
    {
      var playerVocals = Paths.voices(currentSongName, diff,
        (characterData.vocalsP1 == null || characterData.vocalsP1.length < 1) ? 'Player' : characterData.vocalsP1);
      vocals.loadEmbedded(playerVocals != null ? playerVocals : Paths.voices(currentSongName, diff));
    }
    vocals.autoDestroy = false;
    FlxG.sound.list.add(vocals);

    opponentVocals = new FlxSound();
    try
    {
      var oppVocals = Paths.voices(currentSongName, diff,
        (characterData.vocalsP2 == null || characterData.vocalsP2.length < 1) ? 'Opponent' : characterData.vocalsP2);
      if (oppVocals != null) opponentVocals.loadEmbedded(oppVocals);
    }
    opponentVocals.autoDestroy = false;
    FlxG.sound.list.add(opponentVocals);

    generateSong(diff);
    FlxG.sound.music.pause();
    FlxG.sound.music.onComplete = function() {
      pauseVocals();
      vocals.time = opponentVocals.time = 0;
      FlxG.sound.music.pause();
      FlxG.sound.music.time = 0;
      songSlider.maxValue = FlxG.sound.music.length;
      changeSection();
    };
    Conductor.songPosition = sectionStartTime();
    FlxG.sound.music.time = Conductor.songPosition;
  }

  function generateSong(?diff:String = '')
  {
    FlxG.sound.playMusic(Paths.inst(currentSongName, diff), 0.6 /*, false*/);
    if (instVolume != null) FlxG.sound.music.volume = instVolume.value;
    if (check_mute_inst != null && check_mute_inst.checked) FlxG.sound.music.volume = 0;

    FlxG.sound.music.onComplete = function() {
      FlxG.sound.music.pause();
      Conductor.songPosition = 0;
      if (vocals != null)
      {
        vocals.pause();
        vocals.time = 0;
      }
      if (opponentVocals != null)
      {
        opponentVocals.pause();
        opponentVocals.time = 0;
      }
      changeSection();
      curSec = 0;
      updateGrid();
      updateSectionUI();
      if (vocals != null) vocals.play();
      if (opponentVocals != null) opponentVocals.play();
    };
  }

  function generateUI():Void
  {
    while (bullshitUI.members.length > 0)
    {
      bullshitUI.remove(bullshitUI.members[0], true);
    }

    // general shit
    var title:FlxText = new FlxText(UI_box.x + 20, UI_box.y + 20, 0);
    bullshitUI.add(title);
  }

  override function getEvent(id:String, sender:Dynamic, data:Dynamic, ?params:Array<Dynamic>)
  {
    if (id == FlxUICheckBox.CLICK_EVENT)
    {
      var check:FlxUICheckBox = cast sender;
      var label = check.getLabel().text;
      switch (label)
      {
        case 'Must hit section':
          _song.notes[curSec].mustHitSection = check.checked;

          // updateGrid(); No need to update the grid if there's literally nothing to change
          updateHeads();

        case 'GF section':
          _song.notes[curSec].gfSection = check.checked;

          // updateGrid(); No need to update the grid if there's literally nothing to change
          updateHeads();

        case 'Change BPM':
          _song.notes[curSec].changeBPM = check.checked;
          FlxG.log.add('changed bpm shit');
        case "Alt Animation":
          _song.notes[curSec].altAnim = check.checked;
        case "Cross Fade":
					_song.notes[curSec].crossFade = check.checked;
      }
    } else if (id == FlxUINumericStepper.CHANGE_EVENT && (sender is FlxUINumericStepper))
    {
      var nums:FlxUINumericStepper = cast sender;
      var wname = nums.name;
      switch (wname)
      {
        case 'section_beats':
          _song.notes[curSec].sectionBeats = nums.value;
          reloadGridLayer();

        case 'song_speed':
          _song.speed = nums.value;

        case 'song_bpm':
          _song.bpm = nums.value;
          Conductor.mapBPMChanges(_song);
          Conductor.changeBPM(nums.value);

        case 'note_susLength':
          if (curSelectedNote != null && curSelectedNote[2] != null)
          {
            curSelectedNote[2] = nums.value;
            updateGrid();
          }

        case 'section_bpm':
          _song.notes[curSec].bpm = nums.value;
          updateGrid();

        case 'inst_volume':
          FlxG.sound.music.volume = nums.value;
          if (check_mute_inst.checked) FlxG.sound.music.volume = 0;

        case 'voices_volume':
          vocals.volume = nums.value;
          if (check_mute_vocals.checked) vocals.volume = 0;

        case 'voices_opp_volume':
          opponentVocals.volume = nums.value;
          if (check_mute_vocals_opponent.checked) opponentVocals.volume = 0;

        case 'hitsound_volume':
          FlxG.save.data.chart_hitsoundVolume = nums.value;
      }
    } else if (id == FlxUIInputText.CHANGE_EVENT && (sender is FlxUIInputText))
    {
      if (sender == noteSplashesInputText)
      {
        _song.splashSkin = noteSplashesInputText.text;
      } else if (sender == gameOverCharacterInputText)
      {
        _song.gameOverChar = gameOverCharacterInputText.text;
      } else if (sender == gameOverSoundInputText)
      {
        _song.gameOverSound = gameOverSoundInputText.text;
      } else if (sender == gameOverLoopInputText)
      {
        _song.gameOverLoop = gameOverLoopInputText.text;
      } else if (sender == gameOverEndInputText)
      {
        _song.gameOverEnd = gameOverEndInputText.text;
      } else if (curSelectedNote != null)
      {
        if (sender == value1InputText)
        {
          if (curSelectedNote[1][curEventSelected] != null)
          {
            curSelectedNote[1][curEventSelected][1] = value1InputText.text;
            updateGrid(false, true);
          }
        } else if (sender == value2InputText)
        {
          if (curSelectedNote[1][curEventSelected] != null)
          {
            curSelectedNote[1][curEventSelected][2] = value2InputText.text;
            updateGrid(false, true);
          }
        }
      }
    } else if (id == FlxUISlider.CHANGE_EVENT && (sender is FlxUISlider))
    {
      switch (sender)
      {
        case 'playbackSpeed':
          playbackSpeed = Std.int(sliderRate.value);
      }
    }

    // FlxG.log.add(id + " WEED " + sender + " WEED " + data + " WEED " + params);
  }

  var updatedSection:Bool = false;

  // REFACTOR: delegated to editors.charting.ChartingUIGrid
  function sectionStartTime(add:Int = 0):Float
  {
    return ChartingUIGrid.sectionStartTime(this, add);
  }

  var lastConductorPos:Float;
  var colorSine:Float = 0;

  override function update(elapsed:Float)
  {
    curStep = recalculateSteps();

    if (FlxG.sound.music.time < 0)
    {
      if (idleMusic != null && idleMusic.music != null && idleMusicAllow) idleMusic.unpauseMusic(2);
      FlxG.sound.music.pause();
      FlxG.sound.music.time = 0;
    } else if (FlxG.sound.music.time > FlxG.sound.music.length)
    {
      if (idleMusic != null && idleMusic.music != null && idleMusicAllow) idleMusic.unpauseMusic(2);
      FlxG.sound.music.pause();
      FlxG.sound.music.time = 0;
      changeSection();
    }
    Conductor.songPosition = FlxG.sound.music.time;
    _song.song = UI_songTitle.text;
    difficulty = UI_songDiff.text.toLowerCase();
    specialAudioName = _song.specialAudioName = UI_specAudio.text.toLowerCase();
    specialEventsName = _song.specialEventsName = UI_specEvents.text.toLowerCase();

    if (idleMusic != null && idleMusic.music != null && idleMusic.music.playing && !idleMusicAllow) idleMusic.pauseMusic();

    _song.songCredit = creditInputText.text;
    _song.songCreditIcon = creditIconInputText.text;
    _song.songCreditBarPath = creditPathInputText.text;

    _song.windowName = winNameInputText.text;

    if (event7InputText.text == null || event7InputText.text == '')
    {
      _song.event7Value = null;
    } else
    {
      _song.event7Value = event7InputText.text;
    }

    copyMultiSectButton.text = "Copy from the last " + Std.int(CopyLastSectionCount.value) + " to the next " + Std.int(CopyFutureSectionCount.value)
      + " sections, " + Std.int(CopyLoopCount.value) + " times";
    deleteSections.text = "Delete sections " + Std.int(deleteSecStart.value) + " to " + Std.int(deleteSecEnd.value);

    strumLineUpdateY();
    for (i in 0...8)
    {
      strumLineNotes.members[i].y = strumLine.y;
    }

    FlxG.mouse.visible = true; // cause reasons. trust me
    camPos.y = strumLine.y;
    if (!disableAutoScrolling.checked)
    {
      if (Math.ceil(strumLine.y) >= gridBG.height)
      {
        if (_song.notes[curSec + 1] == null)
        {
          addSection(getSectionBeats());
        }

        changeSection(curSec + 1, false);
      } else if (strumLine.y < -10)
      {
        changeSection(curSec - 1, false);
      }
    }
    FlxG.watch.addQuick('daBeat', curBeat);
    FlxG.watch.addQuick('daStep', curStep);

    selectionEvent.visible = false;
    if (FlxG.mouse.x > gridBG.x
      && FlxG.mouse.x < gridBG.x + gridBG.width
      && FlxG.mouse.y > gridBG.y
      && FlxG.mouse.y < gridBG.y + (GRID_SIZE * getSectionBeats() * 4) * zoomList[curZoom])
    {
      selectionNote.visible = true;
      selectionNote.x = Math.floor(FlxG.mouse.x / GRID_SIZE) * GRID_SIZE;
      if (FlxG.keys.pressed.SHIFT) selectionNote.y = FlxG.mouse.y;
      else
      {
        var gridmult = GRID_SIZE / (quantization / 16);
        selectionNote.y = Math.floor(FlxG.mouse.y / gridmult) * gridmult;
      }
      selectionNote.noteData = Math.floor(FlxG.mouse.x / GRID_SIZE - 1) % 4;
      if (selectionNote.noteData < 0)
      {
        selectionNote.noteData = 0;
        selectionNote.visible = false;
        selectionEvent.visible = true;
        selectionEvent.setGraphicSize(GRID_SIZE, GRID_SIZE);
        selectionEvent.x = selectionNote.x;
        selectionEvent.y = selectionNote.y;
      }
      if (selectionNote.animation.curAnim == null) selectionNote.playAnim('static' + selectionNote.noteData, false);
      else if (!selectionNote.animation.curAnim.name.endsWith(Std.string(selectionNote.noteData))) selectionNote.playAnim('static' + selectionNote.noteData,
        false);
    } else
    {
      selectionNote.visible = false;
    }

    if (FlxG.mouse.justPressed)
    {
      if (FlxG.mouse.overlaps(curRenderedNotes))
      {
        if (!FlxG.keys.pressed.CONTROL && !FlxG.keys.pressed.ALT)
        {
          saveUndo(_song);
          if (soundEffectsCheck.checked) FlxG.sound.play(Paths.sound('removeNote'), 0.7);
        }
        if (FlxG.keys.pressed.CONTROL || FlxG.keys.pressed.ALT)
        {
          if (soundEffectsCheck.checked) FlxG.sound.play(Paths.sound('selectNote'), 0.7);
        }
        curRenderedNotes.forEachAlive(function(note:Note) {
          if (FlxG.mouse.overlaps(note))
          {
            if (FlxG.keys.pressed.CONTROL)
            {
              selectNote(note);
            } else if (FlxG.keys.pressed.ALT)
            {
              selectNote(note);
              curSelectedNote[3] = noteTypeIntMap.get(currentType);
              updateGrid(false);
            } else
            {
              selectionNote.playAnim('pressed' + selectionNote.noteData, true);
              // trace('tryin to delete note...');
              deleteNote(note);
            }
          }
        });
      } else
      {
        if (FlxG.mouse.x > gridBG.x
          && FlxG.mouse.x < gridBG.x + gridBG.width
          && FlxG.mouse.y > gridBG.y
          && FlxG.mouse.y < gridBG.y + (GRID_SIZE * getSectionBeats() * 4) * zoomList[curZoom])
        {
          saveUndo(_song);
          FlxG.log.add('added note');
          addNote();
          var addCount:Float = 0;
          if (check_stackActive.checked)
          {
            addCount = stepperStackNum.value * stepperStackOffset.value - 1;
          }
          for (i in 0...Std.int(addCount))
          {
            addNote(curSelectedNote[0] + (15000 / Conductor.bpm) / stepperStackOffset.value, curSelectedNote[1] + Math.floor(stepperStackSideOffset.value),
              currentType);
          }
          selectionNote.playAnim('confirm' + selectionNote.noteData, true);
          if (soundEffectsCheck.checked) FlxG.sound.play(Paths.sound('addedNote'), 0.7);

          // updateGrid(false);
          updateNoteUI();
        } else if (soundEffectsCheck.checked) FlxG.sound.play(Paths.sound('click'));
      }
    }

    var blockInput:Bool = false;
    for (inputText in blockPressWhileTypingOn)
    {
      if (inputText.hasFocus)
      {
        FlxG.sound.muteKeys = [];
        FlxG.sound.volumeDownKeys = [];
        FlxG.sound.volumeUpKeys = [];
        blockInput = true;
        break;
      }
    }

    if (!blockInput)
    {
      for (stepper in blockPressWhileTypingOnStepper)
      {
        @:privateAccess
        var leText:Dynamic = stepper.text_field;
        var leText:FlxUIInputText = leText;
        if (leText.hasFocus)
        {
          FlxG.sound.muteKeys = [];
          FlxG.sound.volumeDownKeys = [];
          FlxG.sound.volumeUpKeys = [];
          blockInput = true;
          break;
        }
      }
    }

    if (!blockInput)
    {
      FlxG.sound.muteKeys = TitleState.muteKeys;
      FlxG.sound.volumeDownKeys = TitleState.volumeDownKeys;
      FlxG.sound.volumeUpKeys = TitleState.volumeUpKeys;
      for (dropDownMenu in blockPressWhileScrolling)
      {
        if (dropDownMenu.dropPanel.visible)
        {
          blockInput = true;
          break;
        }
      }
    }

    if (!blockInput)
    {
      if (FlxG.keys.justPressed.ESCAPE)
      {
        saveLevel(true, true);
        FlxG.sound.music.pause();
        pauseVocals();
        LoadingState.loadAndSwitchState(() -> new editors.EditorPlayState(sectionStartTime()));
        if (idleMusic != null && idleMusic.music != null) idleMusic.destroy();
        FlxG.sound.music.onComplete = null; // So that it doesn't crash when you reach the end
      }
      if (FlxG.keys.justPressed.ENTER)
      {
        if (CoolUtil.getNoteAmount(_song) <= 1000000) saveLevel(true, true);
        FlxG.mouse.visible = false;
        PlayState.SONG = _song;
        FlxG.sound.music.stop();
        if (vocals != null) vocals.stop();
        if (opponentVocals != null) opponentVocals.stop();
        if (FlxG.keys.pressed.SHIFT)
        {
          PlayState.startOnTime = sectionStartTime();
        }
        CoolUtil.currentDifficulty = difficulty;
        StageData.loadDirectory(_song);
        LoadingState.loadAndSwitchState(PlayState.new);
        if (idleMusic != null && idleMusic.music != null) idleMusic.destroy();
      }

      if (curSelectedNote != null && curSelectedNote[1] > -1)
      {
        if (FlxG.keys.justPressed.E || FlxG.keys.pressed.CONTROL && FlxG.mouse.wheel < 0)
        {
          changeNoteSustain(Conductor.stepCrochet);
        }
        if (FlxG.keys.justPressed.Q || FlxG.keys.pressed.CONTROL && FlxG.mouse.wheel > 0)
        {
          changeNoteSustain(-Conductor.stepCrochet);
        }
      }

      if (FlxG.keys.justPressed.BACKSPACE)
      {
        if (!unsavedChanges)
        {
          // Protect against lost data when quickly leaving the chart editor.
          saveLevel(true, true);

          CoolUtil.currentDifficulty = difficulty;
          PlayState.chartingMode = false;
          FlxG.switchState(editors.MasterEditorMenu.new);
          FlxG.sound.playMusic(Paths.music('freakyMenu-' + ClientPrefs.daMenuMusic));
          FlxG.mouse.visible = false;
          if (idleMusic != null && idleMusic.music != null) idleMusic.destroy();
          return;
        } else
          openSubState(new Prompt('WARNING! This action will clear unsaved progress.\n\nProceed?', 0,
            function() FlxG.switchState(editors.MasterEditorMenu.new), null, ignoreWarnings));
      }

      if (FlxG.keys.pressed.CONTROL)
      {
        if (FlxG.keys.justPressed.Z) undo();
      }

      if (FlxG.keys.justPressed.Z && curZoom > 0 && !FlxG.keys.pressed.CONTROL)
      {
        --curZoom;
        updateZoom();
        updateGrid();
      }
      if (FlxG.keys.justPressed.X && curZoom < zoomList.length - 1)
      {
        curZoom++;
        updateZoom();
        updateGrid();
      }

      if (FlxG.keys.pressed.C && !FlxG.keys.pressed.CONTROL)
        if (!FlxG.mouse.overlaps(curRenderedNotes)) // lmao cant place notes when your cursor already overlaps one
        if (FlxG.mouse.x > gridBG.x
          && FlxG.mouse.x < gridBG.x + gridBG.width
          && FlxG.mouse.y > gridBG.y
          && FlxG.mouse.y < gridBG.y + gridBG.height) if (!FlxG.keys.pressed.CONTROL) // stop crashing
          {
            addNote(); // allows you to draw notes by holding C
            var addCount:Float = 0;
            if (check_stackActive.checked)
            {
              addCount = stepperStackNum.value * stepperStackOffset.value - 1;
            }
            for (i in 0...Std.int(addCount))
            {
              addNote(curSelectedNote[0] + (15000 / Conductor.bpm) / stepperStackOffset.value, curSelectedNote[1] + Math.floor(stepperStackSideOffset.value),
                currentType);
            }
          }
      if (FlxG.keys.pressed.C && FlxG.keys.pressed.CONTROL) if (FlxG.mouse.overlaps(curRenderedNotes)) if (FlxG.mouse.x > gridBG.x
        && FlxG.mouse.x < gridBG.x + gridBG.width
        && FlxG.mouse.y > gridBG.y
        && FlxG.mouse.y < gridBG.y + gridBG.height) curRenderedNotes.forEach(function(note:Note) {
          if (FlxG.mouse.overlaps(note)) deleteNote(note); // mass deletion of notes
        });

      if (FlxG.keys.justPressed.TAB)
      {
        if (FlxG.keys.pressed.SHIFT)
        {
          UI_box.selected_tab -= 1;
          if (UI_box.selected_tab < 0) UI_box.selected_tab = 2;
        } else
        {
          UI_box.selected_tab += 1;
          if (UI_box.selected_tab >= 3) UI_box.selected_tab = 0;
        }
      }

      if (FlxG.keys.justPressed.SPACE)
      {
        if (FlxG.sound.music.playing)
        {
          FlxG.sound.music.pause();
          pauseVocals();
          resetBuddies();
          lilBf.color = lilOpp.color = FlxColor.WHITE;
          if (idleMusic != null && idleMusic.music != null && idleMusicAllow) idleMusic.unpauseMusic(2);
        } else
        {
          pauseAndSetVocalsTime();
          if (!FlxG.sound.music.playing)
          {
            FlxG.sound.music.play();
            if (vocals != null) vocals.play();
            if (opponentVocals != null) opponentVocals.play();
          }
          if (idleMusic != null && idleMusic.music != null && idleMusicAllow) idleMusic.pauseMusic();
          resetBuddies();
          lilBf.color = lilOpp.color = FlxColor.WHITE;
        }
      }

      if (!FlxG.keys.pressed.ALT && FlxG.keys.justPressed.R)
      {
        if (FlxG.keys.pressed.SHIFT) resetSection(true);
        else
          resetSection();
      }
      if (FlxG.keys.pressed.CONTROL)
      {
        if (FlxG.keys.justPressed.RIGHT) if (curSelectedNote != null && curSelectedNote[1] > -1 && curSelectedNote[2] != null)
        {
          if (curSelectedNote[1] < 6 + 1)
          {
            curSelectedNote[1] += 1;
          } else if (curSelectedNote[1] == 6 + 1)
          {
            curSelectedNote[1] = 0;
          }
          updateGrid(false);
        }
        if (FlxG.keys.justPressed.LEFT) if (curSelectedNote != null && curSelectedNote[1] > -1 && curSelectedNote[2] != null)
        {
          if (curSelectedNote[1] > 0)
          {
            curSelectedNote[1] -= 1;
          } else if (curSelectedNote[1] == 0)
          {
            curSelectedNote[1] = 7;
          }
          updateGrid(false);
        }
      }

      if (FlxG.mouse.wheel != 0 == !FlxG.keys.pressed.CONTROL)
      {
        if (idleMusic != null && idleMusic.music != null && idleMusicAllow) idleMusic.unpauseMusic(2);
        FlxG.sound.music.pause();
        resetBuddies();
        lilBf.color = lilOpp.color = FlxColor.WHITE;
        if (!mouseQuant) FlxG.sound.music.time -= (FlxG.mouse.wheel * Conductor.stepCrochet * 0.8);
        else
        {
          var time:Float = FlxG.sound.music.time;
          var beat:Float = curDecBeat;
          var snap:Float = quantization / 4;
          var increase:Float = 1 / snap;
          if (FlxG.mouse.wheel > 0)
          {
            var fuck:Float = CoolUtil.quantize(beat, snap) - increase;
            FlxG.sound.music.time = Conductor.beatToSeconds(fuck);
          } else
          {
            var fuck:Float = CoolUtil.quantize(beat, snap) + increase;
            FlxG.sound.music.time = Conductor.beatToSeconds(fuck);
          }
        }
        pauseAndSetVocalsTime();
      }

      if (FlxG.keys.pressed.W || FlxG.keys.pressed.S)
      {
        if (idleMusic != null && idleMusic.music != null && idleMusicAllow) idleMusic.unpauseMusic(2);
        resetBuddies();
        lilBf.color = lilOpp.color = FlxColor.WHITE;
        FlxG.sound.music.pause();

        var holdingShift:Float = 1;
        if (FlxG.keys.pressed.CONTROL) holdingShift = 0.25;
        else if (FlxG.keys.pressed.SHIFT) holdingShift = 4;

        var daTime:Float = 700 * FlxG.elapsed * holdingShift;

        if (FlxG.keys.pressed.W)
        {
          FlxG.sound.music.time -= daTime;
        } else
          FlxG.sound.music.time += daTime;

        pauseAndSetVocalsTime();
      }

      if (!vortex)
      {
        if (FlxG.keys.justPressed.UP || FlxG.keys.justPressed.DOWN)
        {
          if (idleMusic != null && idleMusic.music != null && idleMusicAllow) idleMusic.unpauseMusic(2);
          FlxG.sound.music.pause();
          updateCurStep();
          var time:Float = FlxG.sound.music.time;
          var beat:Float = curDecBeat;
          var snap:Float = quantization / 4;
          var increase:Float = 1 / snap;
          if (FlxG.keys.pressed.UP)
          {
            var fuck:Float = CoolUtil.quantize(beat, snap) - increase; // (Math.floor((beat+snap) / snap) * snap);
            FlxG.sound.music.time = Conductor.beatToSeconds(fuck);
          } else
          {
            var fuck:Float = CoolUtil.quantize(beat, snap) + increase; // (Math.floor((beat+snap) / snap) * snap);
            FlxG.sound.music.time = Conductor.beatToSeconds(fuck);
          }
        }
      }

      var style = currentType;

      if (FlxG.keys.pressed.SHIFT)
      {
        style = 3;
      }

      var conductorTime = Conductor.songPosition; // + sectionStartTime();Conductor.songPosition / Conductor.stepCrochet;

      // AWW YOU MADE IT SEXY <3333 THX SHADMAR

      if (!blockInput && !FlxG.keys.pressed.CONTROL)
      {
        if (FlxG.keys.justPressed.RIGHT)
        {
          curQuant++;
          if (curQuant > quantizations.length - 1) curQuant = 0;

          quantization = quantizations[curQuant];
        }

        if (FlxG.keys.justPressed.LEFT)
        {
          curQuant--;
          if (curQuant < 0) curQuant = quantizations.length - 1;

          quantization = quantizations[curQuant];
        }
        quant.animation.play('q', true, false, curQuant);
      }
      if (vortex && !blockInput && !FlxG.keys.pressed.CONTROL)
      {
        var controlArray:Array<Bool> = [
           FlxG.keys.justPressed.ONE, FlxG.keys.justPressed.TWO, FlxG.keys.justPressed.THREE, FlxG.keys.justPressed.FOUR,
          FlxG.keys.justPressed.FIVE, FlxG.keys.justPressed.SIX, FlxG.keys.justPressed.SEVEN, FlxG.keys.justPressed.EIGHT
        ];

        if (controlArray.contains(true))
        {
          for (i in 0...controlArray.length)
          {
            if (controlArray[i]) doANoteThing(conductorTime, i, style);
            updateGrid(false);
          }
        }

        var feces:Float;
        if (FlxG.keys.justPressed.UP || FlxG.keys.justPressed.DOWN)
        {
          FlxG.sound.music.pause();

          if (idleMusic != null && idleMusic.music != null && idleMusicAllow) idleMusic.unpauseMusic(2);

          updateCurStep();

          var time:Float = FlxG.sound.music.time;
          var beat:Float = curDecBeat;
          var snap:Float = quantization / 4;
          var increase:Float = 1 / snap;
          if (FlxG.keys.pressed.UP)
          {
            var fuck:Float = CoolUtil.quantize(beat, snap) - increase;
            feces = Conductor.beatToSeconds(fuck);
          } else
          {
            var fuck:Float = CoolUtil.quantize(beat, snap) + increase; // (Math.floor((beat+snap) / snap) * snap);
            feces = Conductor.beatToSeconds(fuck);
          }
          FlxTween.tween(FlxG.sound.music, {time: feces}, 0.1, {ease: FlxEase.circOut});
          pauseAndSetVocalsTime();

          var dastrum = 0;

          if (curSelectedNote != null)
          {
            dastrum = curSelectedNote[0];
          }

          var secStart:Float = sectionStartTime();
          var datime = (feces - secStart) - (dastrum - secStart); // idk math find out why it doesn't work on any other section other than 0
          if (curSelectedNote != null)
          {
            var controlArray:Array<Bool> = [
               FlxG.keys.pressed.ONE, FlxG.keys.pressed.TWO, FlxG.keys.pressed.THREE, FlxG.keys.pressed.FOUR,
              FlxG.keys.pressed.FIVE, FlxG.keys.pressed.SIX, FlxG.keys.pressed.SEVEN, FlxG.keys.pressed.EIGHT
            ];

            if (controlArray.contains(true))
            {
              for (i in 0...controlArray.length)
              {
                if (controlArray[i]) if (curSelectedNote[1] == i) curSelectedNote[2] += datime - curSelectedNote[2] - Conductor.stepCrochet;
              }
              updateGrid(false);
              updateNoteUI();
            }
          }
        }
      }
      var shiftThing:Int = 1;
      if (FlxG.keys.pressed.SHIFT) shiftThing = 4;

      if (FlxG.keys.justPressed.D)
      {
        if (_song.notes[curSec + shiftThing] == null)
        {
          addSection(getSectionBeats());
        }

        changeSection(curSec + shiftThing);
      }
      if (FlxG.keys.justPressed.A)
      {
        if (curSec <= 0)
        {
          changeSection(_song.notes.length - 1);
        } else
        {
          changeSection(curSec - shiftThing);
        }
      }
    } else if (FlxG.keys.justPressed.ENTER)
    {
      for (i in 0...blockPressWhileTypingOn.length)
      {
        if (blockPressWhileTypingOn[i].hasFocus)
        {
          blockPressWhileTypingOn[i].hasFocus = false;
        }
      }
    }

    strumLineNotes.visible = quant.visible = vortex;

    if (FlxG.sound.music.time < 0)
    {
      FlxG.sound.music.pause();
      FlxG.sound.music.time = 0;
    } else if (FlxG.sound.music.time > FlxG.sound.music.length)
    {
      FlxG.sound.music.pause();
      FlxG.sound.music.time = 0;
      changeSection();
    }
    Conductor.songPosition = FlxG.sound.music.time;
    strumLineUpdateY();
    camPos.y = strumLine.y;
    for (i in 0...8)
    {
      strumLineNotes.members[i].y = strumLine.y;
      strumLineNotes.members[i].alpha = FlxG.sound.music.playing ? 1 : 0.35;
    }

    #if FLX_PITCH
    // PLAYBACK SPEED CONTROLS //
    var holdingShift = FlxG.keys.pressed.SHIFT;
    var holdingLB = FlxG.keys.pressed.LBRACKET;
    var holdingRB = FlxG.keys.pressed.RBRACKET;
    var pressedLB = FlxG.keys.justPressed.LBRACKET;
    var pressedRB = FlxG.keys.justPressed.RBRACKET;

    if (!holdingShift && pressedLB || holdingShift && holdingLB) playbackSpeed -= 0.01;
    if (!holdingShift && pressedRB || holdingShift && holdingRB) playbackSpeed += 0.01;
    if (FlxG.keys.pressed.ALT && (pressedLB || pressedRB || holdingLB || holdingRB)) playbackSpeed = 1;
    //

    if (playbackSpeed <= 0.25) playbackSpeed = 0.25;
    if (playbackSpeed >= 4) playbackSpeed = 4;

    FlxG.sound.music.pitch = playbackSpeed;
    vocals.pitch = playbackSpeed;
    opponentVocals.pitch = playbackSpeed;
    #end

    if (bpmTxt != null)
    {
      bpmTxt.text = CoolUtil.formatTime(Conductor.songPosition, 2)
        + ' / '
        + CoolUtil.formatTime(FlxG.sound.music.length, 2)
        + "\nSection: "
        + curSec
        + "\n\nBeat: "
        + Std.string(curDecBeat).substring(0, 4)
        + "\nStep: "
        + curStep
        + "\nBeat Snap: "
        + quantization
        + "th"
        + "\n\n"
        + FlxStringUtil.formatMoney(CoolUtil.getNoteAmount(_song), false)
        + ' Notes'
        + "\n\nRendered Notes: "
        + FlxStringUtil.formatMoney(Math.abs(curRenderedNotes.length + nextRenderedNotes.length), false);

      if (_song.notes[curSec] != null) bpmTxt.text += "\n\nSection Notes: " + FlxStringUtil.formatMoney(_song.notes[curSec].sectionNotes.length, false);
    }

    var playedSound:Array<Bool> = [false, false, false, false]; // Prevents ouchy GF sex sounds
    curRenderedNotes.forEachAlive(function(note:Note) {
      note.alpha = 1;
      if (curSelectedNote != null)
      {
        var noteDataToCheck:Int = note.noteData;
        if (noteDataToCheck > -1 && note.mustPress != _song.notes[curSec].mustHitSection) noteDataToCheck += 4;

        if (curSelectedNote[0] == note.strumTime
          && ((curSelectedNote[2] == null && noteDataToCheck < 0)
            || (curSelectedNote[2] != null && curSelectedNote[1] == noteDataToCheck)))
        {
          colorSine += elapsed;
          var colorVal:Float = 0.7 + Math.sin(Math.PI * colorSine) * 0.3;
          note.color = FlxColor.fromRGBFloat(colorVal, colorVal, colorVal,
            0.999); // Alpha can't be 100% or the color won't be updated for some reason, guess i will die
        }
      }

      if (note.strumTime <= Conductor.songPosition)
      {
        note.alpha = 0.4;
        if (note.strumTime > lastConductorPos && FlxG.sound.music.playing && note.noteData > -1)
        {
          var data:Int = note.noteData % 4;
          var noteDataToCheck:Int = note.noteData;
          if (noteDataToCheck > -1 && note.mustPress != _song.notes[curSec].mustHitSection) noteDataToCheck += 4;
          if ((ClientPrefs.enableColorShader || ClientPrefs.showNotes && ClientPrefs.enableColorShader)
            && vortex) strumLineNotes.members[noteDataToCheck].playAnim('confirm', true, note.rgbShader.r, note.rgbShader.g, note.rgbShader.b);
          else
            strumLineNotes.members[noteDataToCheck].playAnim('confirm', true);
          strumLineNotes.members[noteDataToCheck].resetAnim = ((note.sustainLength / 1000) + 0.15) / playbackSpeed;

          if (!playedSound[data])
          {
            if ((playSoundBf.checked && note.mustPress) || (playSoundDad.checked && !note.mustPress))
            {
              if (_song.player1 == 'gf')
              { // Easter egg
                hitsound = FlxG.sound.load(Paths.sound("hitsounds/" + 'GF_' + Std.string(data + 1)));
              }

              hitsound.play(true);
              hitsound.volume = hitsoundVolume.value;
              hitsound.pan = note.noteData < 4 ? -0.3 : 0.3; // would be coolio
              playedSound[data] = true;
            }

            data = note.noteData;
            if (note.mustPress && lilBuddiesBox.checked)
            {
              if (ClientPrefs.enableColorShader || ClientPrefs.showNotes && ClientPrefs.enableColorShader)
              {
                lilBf.color = note.rgbShader.r;
              }
              lilBf.animation.play("" + (data % 4), true);
            }
            if (!note.mustPress && lilBuddiesBox.checked)
            {
              if (ClientPrefs.enableColorShader || ClientPrefs.showNotes && ClientPrefs.enableColorShader)
              {
                lilOpp.color = note.rgbShader.r;
              }
              lilOpp.animation.play("" + (data % 4), true);
            }
            if (note.mustPress != _song.notes[curSec].mustHitSection)
            {
              data += 4;
            }
          }
        }
      }
    });

    if (metronome.checked && lastConductorPos != Conductor.songPosition)
    {
      var metroInterval:Float = 60 / metronomeStepper.value;
      var metroStep:Int = Math.floor(((Conductor.songPosition + metronomeOffsetStepper.value) / metroInterval) / 1000);
      var lastMetroStep:Int = Math.floor(((lastConductorPos + metronomeOffsetStepper.value) / metroInterval) / 1000);
      if (metroStep != lastMetroStep)
      {
        FlxG.sound.play(Paths.sound('Metronome_Tick'));
        // trace('Ticked');
      }
    }
    lastConductorPos = Conductor.songPosition;
    super.update(elapsed);
    idleMusic.update(elapsed);
  }

  function resetBuddies()
  {
    lilBf.animation.play("idle");
    lilOpp.animation.play("idle");
  }

  // REFACTOR: delegated to editors.charting.ChartingUIGrid
  function updateZoom()
  {
    ChartingUIGrid.updateZoom(this);
  }

  var lastSecBeats:Float = 0;
  var lastSecBeatsNext:Float = 0;
  var lastGridZoom:Int = -1;
  var lastGridBeats:Float = -1;
  var lastGridBeatsNext:Float = -1;
  var lastGridShow:Bool = false;
  var lastGridVortex:Bool = false;
  var lastGridHasNext:Bool = false;
  var lastGridBGHeight:Int = -1;

  // REFACTOR: delegated to editors.charting.ChartingUIGrid
  function reloadGridLayer()
  {
    ChartingUIGrid.reloadGridLayer(this);
  }

  // REFACTOR: delegated to editors.charting.ChartingUIGrid
  function strumLineUpdateY()
  {
    ChartingUIGrid.strumLineUpdateY(this);
  }

  var waveformPrinted:Bool = true;
  var wavData:Array<Array<Array<Float>>> = [[[0], [0]], [[0], [0]]];

  var lastWaveformHeight:Int = 0;
  var waveformCacheSound:FlxSound = null;
  var waveformCacheBuffer:AudioBuffer = null;
  var waveformCacheBytes:Bytes = null;

  // REFACTOR: delegated to editors.charting.ChartingUIWaveform
  function updateWaveform()
  {
    ChartingUIWaveform.updateWaveform(this);
  }

  // REFACTOR: delegated to editors.charting.ChartingUIWaveform
  function waveformData(buffer:AudioBuffer, bytes:Bytes, time:Float, endTime:Float, multiply:Float = 1, ?array:Array<Array<Array<Float>>>,
      ?steps:Float):Array<Array<Array<Float>>>
  {
    return ChartingUIWaveform.waveformData(buffer, bytes, time, endTime, multiply, array, steps);
  }

  // REFACTOR: delegated to editors.charting.ChartingEvents
  function changeNoteSustain(value:Float):Void
  {
    ChartingEvents.changeNoteSustain(this, value);
  }

  function recalculateSteps(add:Float = 0):Int
  {
    var lastChange:BPMChangeEvent =
      {
        stepTime: 0,
        songTime: 0,
        bpm: 0
      }
    for (i in 0...Conductor.bpmChangeMap.length)
    {
      if (FlxG.sound.music.time > Conductor.bpmChangeMap[i].songTime) lastChange = Conductor.bpmChangeMap[i];
    }

    curStep = lastChange.stepTime + Math.floor((FlxG.sound.music.time - lastChange.songTime + add) / Conductor.stepCrochet);
    updateBeat();

    return curStep;
  }

  function resetSection(songBeginning:Bool = false):Void
  {
    resetBuddies();

    updateGrid((songBeginning ? true : false));

    if (FlxG.sound.music.playing && idleMusic != null && idleMusic.music != null && idleMusicAllow) idleMusic.pauseMusic();

    FlxG.sound.music.pause();
    // Basically old shit from changeSection???
    FlxG.sound.music.time = sectionStartTime();

    if (songBeginning)
    {
      FlxG.sound.music.time = 0;
      curSec = 0;
    }

    pauseAndSetVocalsTime();
    updateCurStep();
    updateSectionUI();
    updateWaveform();
  }

  function changeSection(sec:Int = 0, ?updateMusic:Bool = true, ?updateTheGridBITCH:Bool = true):Void
  {
    if (_song.notes[sec] != null)
    {
      if (FlxG.sound.music.playing && idleMusic != null && idleMusic.music != null && idleMusicAllow) idleMusic.pauseMusic();
      resetBuddies();
      lilBf.color = lilOpp.color = FlxColor.WHITE;
      curSec = sec;
      if (updateMusic)
      {
        FlxG.sound.music.pause();

        FlxG.sound.music.time = sectionStartTime();
        pauseAndSetVocalsTime();
        updateCurStep();
      }

      var blah1:Float = getSectionBeats();
      var blah2:Float = getSectionBeats(curSec + 1);
      if (sectionStartTime(1) > FlxG.sound.music.length) blah2 = 0;

      if (blah1 != lastSecBeats || blah2 != lastSecBeatsNext)
      {
        reloadGridLayer();
      } else
      {
        if (updateTheGridBITCH) updateGrid();
      }
      updateSectionUI();
    } else
    {
      changeSection();
    }
    Conductor.songPosition = FlxG.sound.music.time;
    updateWaveform();
    if (updateTheGridBITCH) updateGrid(true);
  }

  function updateSectionUI():Void
  {
    var sec = _song.notes[curSec];

    stepperBeats.value = getSectionBeats();
    check_mustHitSection.checked = sec.mustHitSection;
    check_gfSection.checked = sec.gfSection;
    check_altAnim.checked = sec.altAnim;
    check_crossFade.checked = sec.crossFade;
    check_changeBPM.checked = sec.changeBPM;
    stepperSectionBPM.value = sec.bpm;

    updateHeads();
  }

  var characterData:Dynamic =
    {
      iconP1: null,
      iconP2: null,
      vocalsP1: null,
      vocalsP2: null
    };

  function updateJsonData():Void
  {
    for (i in 1...3)
    {
      var data:CharacterFile = loadCharacterFile(Reflect.field(_song, 'player$i'));
      Reflect.setField(characterData, 'iconP$i', !characterFailed ? data.healthicon : 'face');
      Reflect.setField(characterData, 'vocalsP$i', data.vocals_file != null ? data.vocals_file : '');
    }
  }

  function updateHeads():Void
  {
    if (_song.notes[curSec] != null)
    {
      if (_song.notes[curSec].mustHitSection)
      {
        leftIcon.changeIcon(characterData.iconP1);
        rightIcon.changeIcon(characterData.iconP2);
        if (_song.notes[curSec].gfSection) leftIcon.changeIcon('gf');
      } else
      {
        leftIcon.changeIcon(characterData.iconP2);
        rightIcon.changeIcon(characterData.iconP1);
        if (_song.notes[curSec].gfSection) leftIcon.changeIcon('gf');
      }
    }
  }

  var characterFailed:Bool = false;

  function loadCharacterFile(char:String):CharacterFile
  {
    characterFailed = false;
    var characterPath:String = 'characters/' + char + '.json';
    #if MODS_ALLOWED
    var path:String = Paths.modFolders(characterPath);
    if (!FileSystem.exists(path))
    {
      path = Paths.getPreloadPath(characterPath);
    }

    if (!FileSystem.exists(path))
    #else
    var path:String = Paths.getPreloadPath(characterPath);
    if (!OpenFlAssets.exists(path))
    #end
    {
      path = Paths.getPreloadPath('characters/' + Character.DEFAULT_CHARACTER +
        '.json'); // If a character couldn't be found, change him to BF just to prevent a crash
      characterFailed = true;
    }

    #if MODS_ALLOWED
    var rawJson = File.getContent(path);
    #else
    var rawJson = OpenFlAssets.getText(path);
    #end
    return cast Json.parse(rawJson);
  }

  // REFACTOR: delegated to editors.charting.ChartingUIGrid
  function updateNoteUI():Void
  {
    ChartingUIGrid.updateNoteUI(this);
  }

  // REFACTOR: delegated to editors.charting.ChartingUIGrid
  function updateGrid(?andNext:Bool = true, ?onlyEvents:Bool = false):Void
  {
    ChartingUIGrid.updateGrid(this, andNext, onlyEvents);
  }

  // REFACTOR: delegated to editors.charting.ChartingUIGrid
  function setupNoteData(i:Array<Dynamic>, isNextSection:Bool):Note
  {
    return ChartingUIGrid.setupNoteData(this, i, isNextSection);
  }

  // REFACTOR: delegated to editors.charting.ChartingUIGrid
  function getEventName(names:Array<Dynamic>):String
  {
    return ChartingUIGrid.getEventName(names);
  }

  // REFACTOR: delegated to editors.charting.ChartingUIGrid
  function setupSusNote(note:Note, beats:Float):FlxSprite
  {
    return ChartingUIGrid.setupSusNote(this, note, beats);
  }

  // REFACTOR: delegated to editors.charting.ChartingUIGrid
  private function addSection(sectionBeats:Float = 4):Void
  {
    ChartingUIGrid.addSection(this, sectionBeats);
  }

  // REFACTOR: delegated to editors.charting.ChartingEvents
  function selectNote(note:Note, ?updateTheGrid:Bool = true):Void
  {
    ChartingEvents.selectNote(this, note, updateTheGrid);
  }

  // REFACTOR: delegated to editors.charting.ChartingEvents
  function deleteNote(note:Note, ?usingVortex:Bool = false):Void
  {
    ChartingEvents.deleteNote(this, note, usingVortex);
  }

  // REFACTOR: delegated to editors.charting.ChartingEvents
  public function doANoteThing(cs, d, style)
  {
    ChartingEvents.doANoteThing(this, cs, d, style);
  }

  // REFACTOR: delegated to editors.charting.ChartingEvents
  function clearSong():Void
  {
    ChartingEvents.clearSong(this);
  }

  // REFACTOR: delegated to editors.charting.ChartingEvents
  private function addNote(strum:Null<Float> = null, data:Null<Int> = null, type:Null<Int> = null, ?gridUpdate:Bool = true):Void
  {
    ChartingEvents.addNote(this, strum, data, type, gridUpdate);
  }

  // REFACTOR: delegated to editors.charting.ChartingEvents
  function redo()
  {
    ChartingEvents.redo(this);
  }

  // REFACTOR: delegated to editors.charting.ChartingUIGrid
  function getStrumTime(yPos:Float, doZoomCalc:Bool = true):Float
  {
    return ChartingUIGrid.getStrumTime(this, yPos, doZoomCalc);
  }

  // REFACTOR: delegated to editors.charting.ChartingUIGrid
  function getYfromStrum(strumTime:Float, doZoomCalc:Bool = true):Float
  {
    return ChartingUIGrid.getYfromStrum(this, strumTime, doZoomCalc);
  }

  // REFACTOR: delegated to editors.charting.ChartingUIGrid
  function getYfromStrumNotes(strumTime:Float, beats:Float):Float
  {
    return ChartingUIGrid.getYfromStrumNotes(this, strumTime, beats);
  }

  // REFACTOR: delegated to editors.charting.ChartingSaveLoad
  public function saveUndo(songData:SwagSong)
  {
    ChartingSaveLoad.saveUndo(this, songData);
  }

  // REFACTOR: delegated to editors.charting.ChartingSaveLoad
  public function undo()
  {
    ChartingSaveLoad.undo(this);
  }

  // REFACTOR: delegated to editors.charting.ChartingSaveLoad
  function getNotes():Array<Dynamic>
  {
    return ChartingSaveLoad.getNotes(this);
  }

  // REFACTOR: delegated to editors.charting.ChartingSaveLoad
  function loadJson(song:String, ?diff:String = ''):Void
  {
    ChartingSaveLoad.loadJson(this, song, diff);
  }

  // REFACTOR: delegated to editors.charting.ChartingSaveLoad
  function clearEvents()
  {
    ChartingSaveLoad.clearEvents(this);
  }

  // REFACTOR: delegated to editors.charting.ChartingSaveLoad
  private function saveLevel(?compressed:Bool = false, ?isAuto:Bool = false)
  {
    ChartingSaveLoad.saveLevel(this, compressed, isAuto);
  }

  // REFACTOR: delegated to editors.charting.ChartingSaveLoad
  function sortByTime(Obj1:Array<Dynamic>, Obj2:Array<Dynamic>):Int
  {
    return ChartingSaveLoad.sortByTime(Obj1, Obj2);
  }

  // REFACTOR: delegated to editors.charting.ChartingSaveLoad
  private function saveEvents()
  {
    ChartingSaveLoad.saveEvents(this);
  }

  // REFACTOR: delegated to editors.charting.ChartingSaveLoad
  function onSaveComplete(_):Void
  {
    ChartingSaveLoad.onSaveComplete(this, _);
  }

  /**
   * Called when the save file dialog is cancelled.
   */
  // REFACTOR: delegated to editors.charting.ChartingSaveLoad
  function onSaveCancel(_):Void
  {
    ChartingSaveLoad.onSaveCancel(this, _);
  }

  // REFACTOR: delegated to editors.charting.ChartingSaveLoad
  function onSaveError(_):Void
  {
    ChartingSaveLoad.onSaveError(this, _);
  }

  // REFACTOR: delegated to editors.charting.ChartingUIGrid
  function getSectionBeats(?section:Null<Int> = null)
  {
    return ChartingUIGrid.getSectionBeats(this, section);
  }

  override public function onFocusLost():Void
  {
    if (idleMusic != null && idleMusic.music != null) idleMusic.pauseMusic();

    super.onFocusLost();
  }

  override public function onFocus():Void
  {
    if (idleMusic != null && idleMusic.music != null) idleMusic.unpauseMusic();

    super.onFocus();
  }

  override public function destroy():Void
  {
    Paths.noteSkinFramesMap.clear();
    Paths.noteSkinAnimsMap.clear();
    Paths.splashSkinFramesMap.clear();
    Paths.splashSkinAnimsMap.clear();
    Paths.splashConfigs.clear();
    Paths.splashAnimCountMap.clear();
    Note.globalRgbShaders = [];
    FlxG.autoPause = ClientPrefs.autoPause;

    super.destroy();
  }
}
