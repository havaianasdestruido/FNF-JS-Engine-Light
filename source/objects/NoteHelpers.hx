package objects;

// REFACTOR: explicit imports for relocated root classes
import backend.ClientPrefs;
import play.PlayState;
import shaders.RGBPalette;
import flixel.util.FlxColor;

// REFACTOR: stateless helper functions extracted from objects.Note
@:access(objects.Note)
class NoteHelpers
{
	public static function initializeGlobalRGBShader(noteData:Int = 0, ?note:Note = null)
	{
		if (note == null)
		{
			if(Note.globalRgbShaders[noteData] == null)
			{
				var newRGB:RGBPalette = new RGBPalette();
				Note.globalRgbShaders[noteData] = newRGB;

				var arr:Array<FlxColor> = ClientPrefs.noteColorStyle != 'Quant-Based' ? (!PlayState.isPixelStage) ? ClientPrefs.arrowRGB[noteData] : ClientPrefs.arrowRGBPixel[noteData] : ClientPrefs.quantRGB[noteData];
				if (arr != null && noteData > -1 && noteData <= arr.length)
				{
					newRGB.r = arr[0];
					newRGB.g = arr[1];
					newRGB.b = arr[2];
				}
			}
			return Note.globalRgbShaders[noteData];
		}
		else switch(ClientPrefs.noteColorStyle)
		{
			case 'Quant-Based':
			if(Note.globalRgbShaders[0] == null)
			{
				var newRGB:RGBPalette = new RGBPalette();
				Note.globalRgbShaders[0] = newRGB;

				var arr:Array<FlxColor> = (!note.pixelNote) ? ClientPrefs.arrowRGB[3] : ClientPrefs.arrowRGBPixel[3];
				if (noteData > -1)
				{
					newRGB.r = arr[0];
					newRGB.g = arr[1];
					newRGB.b = arr[2];
				}
			}
			return Note.globalRgbShaders[0];
			case 'Grayscale', 'Rainbow', 'Char-Based':
			if(Note.globalRgbShaders[0] == null)
			{
				var newRGB:RGBPalette = new RGBPalette();
				Note.globalRgbShaders[0] = newRGB;

				if (noteData > -1)
				{
					newRGB.r = 0xFFA0A0A0;
					newRGB.g = FlxColor.WHITE;
					newRGB.b = 0xFF424242;
				}
			}
			return Note.globalRgbShaders[0];
			default:
			if(Note.globalRgbShaders[noteData] == null)
			{
				var newRGB:RGBPalette = new RGBPalette();
				Note.globalRgbShaders[noteData] = newRGB;

				var arr:Array<FlxColor> = (!note.pixelNote) ? ClientPrefs.arrowRGB[noteData] : ClientPrefs.arrowRGBPixel[noteData];
				if (noteData > -1 && noteData <= arr.length)
				{
					newRGB.r = arr[0];
					newRGB.g = arr[1];
					newRGB.b = arr[2];
				}
			}
			return Note.globalRgbShaders[noteData];
		}
	}

	public static function getNoteSkinPostfix()
	{
		var skin:String = '';
		if(ClientPrefs.noteSkin != 'Default')
			skin = '-' + ClientPrefs.noteSkin.trim().toLowerCase().replace(' ', '_');
		return skin;
	}
}
