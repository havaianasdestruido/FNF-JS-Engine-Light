package options.helpers;

// REFACTOR: explicit imports for note visual subtypes
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.util.FlxColor;
import objects.Alphabet;
import objects.Alphabet.Alignment;
import objects.AttachedText;
import objects.Note;
import headers.Objects;
import objects.StrumNote;
import shaders.RGBPalette;
import shaders.RGBPalette.RGBShaderReference;

// REFACTOR: imports for relocated root classes
import backend.ClientPrefs;
import backend.CoolUtil;
import backend.Paths;
import options.NotesSubState;
import play.PlayState;

// REFACTOR: note visual settings / preview note grid / color readout helpers extracted from options.NotesSubState
@:access(options.NotesSubState)
@:access(objects.Note)
@:access(backend.MusicBeatState)
class NotesSubStateHelpers
{
	public static function centerHexTypeLine(state:NotesSubState)
	{
		//trace(hexTypeNum);
		if(state.hexTypeNum > 0)
		{
			var letter = state.alphabetHex.letters[state.hexTypeNum-1];
			state.hexTypeLine.x = letter.x - letter.offset.x + letter.width;
		}
		else
		{
			var letter = state.alphabetHex.letters[0];
			state.hexTypeLine.x = letter.x - letter.offset.x;
		}
		state.hexTypeLine.x += state.hexTypeLine.width;
		state.hexTypeVisibleTimer = 0;
	}

	public static function changeSelectionMode(state:NotesSubState, change:Int = 0) {
		state.curSelectedMode += change;
		if (state.curSelectedMode < 0)
			state.curSelectedMode = 2;
		if (state.curSelectedMode >= 3)
			state.curSelectedMode = 0;

		state.modeBG.visible = true;
		state.notesBG.visible = false;
		updateNotes(state);
		FlxG.sound.play(Paths.sound('scrollMenu'));
	}

	public static function changeSelectionNote(state:NotesSubState, change:Int = 0) {
		state.curSelectedNote += change;
		if (state.curSelectedNote < 0)
			state.curSelectedNote = state.dataArray.length-1;
		if (state.curSelectedNote >= state.dataArray.length)
			state.curSelectedNote = 0;

		state.modeBG.visible = false;
		state.notesBG.visible = true;
		state.bigNote.rgbShader.parent = Note.globalRgbShaders[state.curSelectedNote];
		state.bigNote.shader = Note.globalRgbShaders[state.curSelectedNote].shader;
		updateNotes(state);
		FlxG.sound.play(Paths.sound('scrollMenu'));
	}

	// alphabets
	public static function makeColorAlphabet(state:NotesSubState, x:Float = 0, y:Float = 0):Alphabet
	{
		var text:Alphabet = new Alphabet(x, y, '', true);
		text.alignment = CENTERED;
		text.setScale(0.6);
		state.add(text);
		return text;
	}

	// notes sprites functions
	public static function spawnNotes(state:NotesSubState)
	{
		Paths.initDefaultSkin(Note.defaultNoteSkin + NoteHelpers.getNoteSkinPostfix());
		if (state.onPixel && !Paths.fileExists('images/pixelUI/' + Paths.defaultSkin + '.png', IMAGE))
		{
			CoolUtil.coolError("HEY! Your Noteskin doesn't have any Pixel sprites. The game will revert to non-pixel notes to prevent a crash."
			+ "\n\nIf it DOES have Pixel sprites, make sure they're located in 'images/pixelUI/noteskins/'.", "JS Engine Anti-Crash Tool");
			state.onPixel = false;
			spawnNotes(state);
			return;
		}
		state.dataArray = ClientPrefs.noteColorStyle != 'Quant-Based' ? !state.onPixel ? ClientPrefs.arrowRGB : ClientPrefs.arrowRGBPixel : ClientPrefs.quantRGB;
		if (state.onPixel) PlayState.stageUI = "pixel";

		//clear groups
		state.modeNotes.forEachAlive(function(note:FlxSprite) {
			note.kill();
			note.destroy();
		});
		state.modeNotes.clear();

		state.myNotes.forEachAlive(function(note:StrumNote) {
			note.kill();
			note.destroy();
		});
		state.myNotes.clear();

		state.noteTxts.forEachAlive(function(txt:AttachedText) {
			txt.kill();
			txt.destroy();
		});
		state.noteTxts.clear();

		if(state.skinNote != null)
		{
			state.remove(state.skinNote);
			state.skinNote.destroy();
		}
		if(state.bigNote != null)
		{
			state.remove(state.bigNote);
			state.bigNote.destroy();
		}

		// respawn stuff
		var res:Int = state.onPixel ? 160 : 17;
		state.skinNote = new FlxSprite(48, 24).loadGraphic(Paths.image('noteColorMenu/' + (state.onPixel ? 'note' : 'notePixel')), true, res, res);
		state.skinNote.antialiasing = ClientPrefs.globalAntialiasing;
		state.skinNote.setGraphicSize(68);
		state.skinNote.updateHitbox();
		state.skinNote.animation.add('anim', [0], 24, true);
		state.skinNote.animation.play('anim', true);
		if(!state.onPixel) state.skinNote.antialiasing = false;
		state.add(state.skinNote);

		var res:Int = !state.onPixel ? 160 : 17;
		for (i in 0...3)
		{
			var newNote:FlxSprite = new FlxSprite(230 + (100 * i), 100).loadGraphic(Paths.image('noteColorMenu/' + (!state.onPixel ? 'note' : 'notePixel')), true, res, res);
			newNote.antialiasing = ClientPrefs.globalAntialiasing;
			newNote.setGraphicSize(85);
			newNote.updateHitbox();
			newNote.animation.add('anim', [i], 24, true);
			newNote.animation.play('anim', true);
			newNote.ID = i;
			if(state.onPixel) newNote.antialiasing = false;
			state.modeNotes.add(newNote);
		}

		Note.globalRgbShaders = [];
		for (i in 0...state.dataArray.length)
		{
			NoteHelpers.initializeGlobalRGBShader(i);
			Note.globalRgbShaders[i].r = state.dataArray[i][0];
			Note.globalRgbShaders[i].g = state.dataArray[i][1];
			Note.globalRgbShaders[i].b = state.dataArray[i][2];

			var newNote:StrumNote = new StrumNote(150 + (120 * i), 200, i%4, 0);
			newNote.rgbShader.r = state.dataArray[i][0];
			newNote.rgbShader.g = state.dataArray[i][1];
			newNote.rgbShader.b = state.dataArray[i][2];

			if (ClientPrefs.noteColorStyle == 'Quant-Based')
			{
				var txt:AttachedText = new AttachedText(state.quantNames[i], 0, 0, true);
				txt.sprTracker = newNote;
				txt.copyAlpha = true;
				txt.scaleX = txt.scaleY = 2 / txt.letters.length;
				state.noteTxts.add(txt);
			}

			newNote.useRGBShader = true;
			newNote.setGraphicSize(102);
			newNote.updateHitbox();
			newNote.ID = i;
			state.myNotes.add(newNote);
		}

		state.bigNote = new Note(0, 0);
		state.bigNote.setPosition(250, 325);
		state.bigNote.pixelNote = state.onPixel;
		if (state.onPixel) @:privateAccess state.bigNote.reloadNote(Paths.defaultSkin);
		else state.bigNote.texture = Paths.defaultSkin;
		state.bigNote.setGraphicSize(250);
		state.bigNote.updateHitbox();
		state.bigNote.rgbShader.parent = Note.globalRgbShaders[state.curSelectedNote];
		state.bigNote.shader = Note.globalRgbShaders[state.curSelectedNote].shader;
		for (i in 0...state.dataArray.length)
		{
			if(!state.onPixel) state.bigNote.animation.addByPrefix('note$i', Note.colArray[i%4] + '0', 24, true);
			else state.bigNote.animation.add('note$i', [i%4 + 4], 24, true);
		}
		state.insert(state.members.indexOf(state.myNotes) + 1, state.bigNote);
		state._storedColor = getShaderColor(state);
		PlayState.stageUI = "normal";
	}

	public static function updateNotes(state:NotesSubState, ?instant:Bool = false)
	{
		for (note in state.modeNotes)
			note.alpha = (state.curSelectedMode == note.ID) ? 1 : 0.6;

		for (note in state.myNotes)
		{
			var newAnim:String = state.curSelectedNote == note.ID ? 'confirm' : 'pressed';
			note.alpha = (state.curSelectedNote == note.ID) ? 1 : 0.6;
			if(note.animation.curAnim == null || note.animation.curAnim.name != newAnim) note.playAnim(newAnim, true);
			if(instant) note.animation.curAnim.finish();
		}
		state.bigNote.animation.play('note${state.curSelectedNote}', true);
		updateColors(state);
	}

	public static function updateColors(state:NotesSubState, specific:Null<FlxColor> = null)
	{
		var color:FlxColor = getShaderColor(state);
		var wheelColor:FlxColor = specific == null ? getShaderColor(state) : specific;
		state.alphabetR.text = Std.string(color.red);
		state.alphabetG.text = Std.string(color.green);
		state.alphabetB.text = Std.string(color.blue);
		state.alphabetHex.text = color.toHexString(false, false);
		for (letter in state.alphabetHex.letters) letter.color = color;

		state.colorWheel.color = FlxColor.fromHSB(0, 0, color.brightness);
		state.colorWheelSelector.setPosition(state.colorWheel.x + state.colorWheel.width/2, state.colorWheel.y + state.colorWheel.height/2);
		if(wheelColor.brightness != 0)
		{
			var hueWrap:Float = wheelColor.hue * Math.PI / 180;
			state.colorWheelSelector.x += Math.sin(hueWrap) * state.colorWheel.width/2 * wheelColor.saturation;
			state.colorWheelSelector.y -= Math.cos(hueWrap) * state.colorWheel.height/2 * wheelColor.saturation;
		}
		state.colorGradientSelector.y = state.colorGradient.y + state.colorGradient.height * (1 - color.brightness);

		var strumRGB:RGBShaderReference = state.myNotes.members[state.curSelectedNote].rgbShader;
		switch(state.curSelectedMode)
		{
			case 0:
				getShader(state).r = strumRGB.r = color;
			case 1:
				getShader(state).g = strumRGB.g = color;
			case 2:
				getShader(state).b = strumRGB.b = color;
		}
	}

	public static function setShaderColor(state:NotesSubState, value:FlxColor) state.dataArray[state.curSelectedNote][state.curSelectedMode] = value;
	public static function getShaderColor(state:NotesSubState):FlxColor return state.dataArray[state.curSelectedNote][state.curSelectedMode];
	public static function getShader(state:NotesSubState):RGBPalette return Note.globalRgbShaders[state.curSelectedNote];
}