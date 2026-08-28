package editors.charting;

// REFACTOR: extracted from editors.ChartingState (behavior-preserving)
import backend.ClientPrefs;
import backend.Paths;
import flixel.FlxSprite;
import objects.Note;
import headers.Objects;
import play.PlayState;
import shaders.RGBPalette.RGBShaderReference;

class SelectionNote extends FlxSprite
{
	public var rgbShader:RGBShaderReference;
	public var resetAnim:Float = 0;
	public var noteData:Int = 0;
	public var size:Int = 40;
	public var useRGBShader:Bool = true;

	public var texture(default, set):String = null;

	private function set_texture(value:String):String
	{
		if (texture != value)
		{
			texture = (value != null ? value : "NOTE_assets");
			reloadNote();
		}
		return value;
	}

	public function new(x:Float, y:Float, leData:Int)
	{
		rgbShader = new RGBShaderReference(this, NoteHelpers.initializeGlobalRGBShader(leData));
		rgbShader.enabled = false;
		if (PlayState.SONG != null && PlayState.SONG.disableNoteRGB || !ClientPrefs.enableColorShader) useRGBShader = false;
		var arr:Array<FlxColor> = ClientPrefs.arrowRGB[leData];
		if (PlayState.isPixelStage) arr = ClientPrefs.arrowRGBPixel[leData];
		if (leData <= arr.length && useRGBShader)
		{
			@:bypassAccessor
			{
				rgbShader.r = arr[0];
				rgbShader.g = arr[1];
				rgbShader.b = arr[2];
			}
		}
		noteData = leData;
		super(x, y);

		scrollFactor.set(1, 1);
	}

	public function reloadNote()
	{
		var lastAnim:String = null;
		if (animation.curAnim != null) lastAnim = animation.curAnim.name;

		if (PlayState.isPixelStage)
		{
			loadGraphic(Paths.image('pixelUI/' + texture));
			width = width / 4;
			height = height / 5;
			loadGraphic(Paths.image('pixelUI/' + texture), true, Math.floor(width), Math.floor(height));

			antialiasing = false;
			setGraphicSize(size, size);

			animation.add('static0', [0]);
			animation.add('pressed0', [4, 8], 12, false);
			animation.add('confirm0', [12, 16], 24, false);
			animation.add('static1', [1]);
			animation.add('pressed1', [5, 9], 12, false);
			animation.add('confirm1', [13, 17], 24, false);
			animation.add('static2', [2]);
			animation.add('pressed2', [6, 10], 12, false);
			animation.add('confirm2', [14, 18], 12, false);
			animation.add('static3', [3]);
			animation.add('pressed3', [7, 11], 12, false);
			animation.add('confirm3', [15, 19], 24, false);
		} else
		{
			frames = Paths.getSparrowAtlas(texture);

			antialiasing = ClientPrefs.globalAntialiasing;
			setGraphicSize(size, size);

			animation.addByPrefix('static0', 'arrowLEFT');
			animation.addByPrefix('pressed0', 'left press', 24, false);
			animation.addByPrefix('confirm0', 'left confirm', 24, false);
			animation.addByPrefix('static1', 'arrowDOWN');
			animation.addByPrefix('pressed1', 'down press', 24, false);
			animation.addByPrefix('confirm1', 'down confirm', 24, false);
			animation.addByPrefix('static2', 'arrowUP');
			animation.addByPrefix('pressed2', 'up press', 24, false);
			animation.addByPrefix('confirm2', 'up confirm', 24, false);
			animation.addByPrefix('static3', 'arrowRIGHT');
			animation.addByPrefix('pressed3', 'right press', 24, false);
			animation.addByPrefix('confirm3', 'right confirm', 24, false);
		}
		updateHitbox();

		if (lastAnim != null)
		{
			playAnim(lastAnim, true);
		}
		animation.callback = function(name:String, frameNumber:Int, frameIndex:Int) {
			if (name != 'confirm' + noteData) return;
			centerOrigin();
		}
	}

	override function update(elapsed:Float)
	{
		if (ClientPrefs.ffmpegMode) elapsed = 1 / ClientPrefs.targetFPS;
		if (resetAnim > 0)
		{
			resetAnim -= elapsed;
			if (resetAnim <= 0)
			{
				playAnim('static' + noteData);
				resetAnim = 0;
			}
		}
		super.update(elapsed);
	}

	public function playAnim(anim:String, ?force:Bool = false)
	{
		animation.play(anim, force);
		if (animation.curAnim != null)
		{
			centerOffsets();
			centerOrigin();
		}
		resetAnim = 0.15;
		if (rgbShader != null && useRGBShader)
		{
			rgbShader.enabled = (animation.curAnim != null && animation.curAnim.name != 'static');
			updateRGBColors();
		}
	}

	public function updateRGBColors()
	{
		if (rgbShader == null || rgbShader != null && !rgbShader.enabled) return;

		var arr:Array<FlxColor> = ClientPrefs.arrowRGB[noteData];
		if (PlayState.isPixelStage) arr = ClientPrefs.arrowRGBPixel[noteData];
		if (noteData <= arr.length)
		{
			@:bypassAccessor
			{
				rgbShader.r = arr[0];
				rgbShader.g = arr[1];
				rgbShader.b = arr[2];
			}
		}
	}
}
