package editors.charting;

// REFACTOR: extracted from editors.ChartingState (behavior-preserving)
import editors.ChartingState;
import haxe.io.Bytes;
import lime.media.AudioBuffer;

// REFACTOR: imports for relocated root classes
import backend.Conductor;
@:access(flixel.sound.FlxSound._sound)
@:access(openfl.media.Sound.__buffer)

@:access(editors.ChartingState)
@:access(backend.MusicBeatState)
class ChartingUIWaveform
{
  public static function updateWaveform(state:ChartingState)
  {
    #if (desktop && !air)
    if (state.waveformPrinted)
    {
      var width:Int = Std.int(ChartingState.GRID_SIZE * 8);
      var height:Int = Std.int(state.gridBG.height);
      if (state.lastWaveformHeight != height && state.waveformSprite.pixels != null)
      {
        state.waveformSprite.pixels.dispose();
        state.waveformSprite.pixels.disposeImage();
        state.waveformSprite.makeGraphic(width, height, 0x00FFFFFF);
        state.lastWaveformHeight = height;
      }
      state.waveformSprite.pixels.fillRect(new Rectangle(0, 0, width, height), 0x00FFFFFF);
    }
    state.waveformPrinted = false;

    if (!FlxG.save.data.chart_waveformInst && !FlxG.save.data.chart_waveformVoices && !FlxG.save.data.chart_waveformOppVoices)
    {
      // trace('Epic fail on the waveform lol');
      return;
    }

    state.wavData[0][0] = [];
    state.wavData[0][1] = [];
    state.wavData[1][0] = [];
    state.wavData[1][1] = [];

    var steps:Int = Math.round(state.getSectionBeats() * 4);
    var st:Float = state.sectionStartTime();
    var et:Float = st + (Conductor.stepCrochet * steps);

    var sound:FlxSound = FlxG.sound.music;
    if (FlxG.save.data.chart_waveformVoices) sound = state.vocals;
    else if (FlxG.save.data.chart_waveformOppVoices) sound = state.opponentVocals;
    if (sound._sound != null && sound._sound.__buffer != null)
    {
      if (state.waveformCacheBytes == null || state.waveformCacheSound != sound || state.waveformCacheBuffer != sound._sound.__buffer)
      {
        state.waveformCacheBytes = sound._sound.__buffer.data.toBytes();
        state.waveformCacheSound = sound;
        state.waveformCacheBuffer = sound._sound.__buffer;
      }

      state.wavData = waveformData(sound._sound.__buffer, state.waveformCacheBytes, st, et, 1, state.wavData, Std.int(state.gridBG.height));
    }

    // Draws
    var gSize:Int = Std.int(ChartingState.GRID_SIZE * 8);
    var hSize:Int = Std.int(gSize / 2);

    var lmin:Float = 0;
    var lmax:Float = 0;

    var rmin:Float = 0;
    var rmax:Float = 0;

    var size:Float = 1;

    var leftLength:Int = (state.wavData[0][0].length > state.wavData[0][1].length ? state.wavData[0][0].length : state.wavData[0][1].length);

    var rightLength:Int = (state.wavData[1][0].length > state.wavData[1][1].length ? state.wavData[1][0].length : state.wavData[1][1].length);

    var length:Int = leftLength > rightLength ? leftLength : rightLength;

    var index:Int;
    for (i in 0...length)
    {
      index = i;

      lmin = FlxMath.bound(((index < state.wavData[0][0].length && index >= 0) ? state.wavData[0][0][index] : 0) * (gSize / 1.12), -hSize, hSize) / 2;
      lmax = FlxMath.bound(((index < state.wavData[0][1].length && index >= 0) ? state.wavData[0][1][index] : 0) * (gSize / 1.12), -hSize, hSize) / 2;

      rmin = FlxMath.bound(((index < state.wavData[1][0].length && index >= 0) ? state.wavData[1][0][index] : 0) * (gSize / 1.12), -hSize, hSize) / 2;
      rmax = FlxMath.bound(((index < state.wavData[1][1].length && index >= 0) ? state.wavData[1][1][index] : 0) * (gSize / 1.12), -hSize, hSize) / 2;

      state.waveformSprite.pixels.fillRect(new Rectangle(hSize - (lmin + rmin), i * size, (lmin + rmin) + (lmax + rmax), size), FlxColor.BLUE);
    }

    state.waveformPrinted = true;
    #end
  }

  public static function waveformData(buffer:AudioBuffer, bytes:Bytes, time:Float, endTime:Float, multiply:Float = 1, ?array:Array<Array<Array<Float>>>,
      ?steps:Float):Array<Array<Array<Float>>>
  {
    #if (lime_cffi && !macro)
    if (buffer == null || buffer.data == null) return [[[0], [0]], [[0], [0]]];

    var khz:Float = (buffer.sampleRate / 1000);
    var channels:Int = buffer.channels;

    var index:Int = Std.int(time * khz);

    var samples:Float = ((endTime - time) * khz);

    if (steps == null) steps = 1280;

    var samplesPerRow:Float = samples / steps;
    var samplesPerRowI:Int = Std.int(samplesPerRow);

    var gotIndex:Int = 0;

    var lmin:Float = 0;
    var lmax:Float = 0;

    var rmin:Float = 0;
    var rmax:Float = 0;

    var rows:Float = 0;

    var simpleSample:Bool = true; // samples > 17200;
    var v1:Bool = false;

    if (array == null) array = [[[0], [0]], [[0], [0]]];

    while (index < (bytes.length - 1))
    {
      if (index >= 0)
      {
        var byte:Int = bytes.getUInt16(index * channels * 2);

        if (byte > 65535 / 2) byte -= 65535;

        var sample:Float = (byte / 65535);

        if (sample > 0)
        {
          if (sample > lmax) lmax = sample;
        } else if (sample < 0)
        {
          if (sample < lmin) lmin = sample;
        }

        if (channels >= 2)
        {
          byte = bytes.getUInt16((index * channels * 2) + 2);

          if (byte > 65535 / 2) byte -= 65535;

          sample = (byte / 65535);

          if (sample > 0)
          {
            if (sample > rmax) rmax = sample;
          } else if (sample < 0)
          {
            if (sample < rmin) rmin = sample;
          }
        }
      }

      v1 = samplesPerRowI > 0 ? (index % samplesPerRowI == 0) : false;
      while (simpleSample ? v1 : rows >= samplesPerRow)
      {
        v1 = false;
        rows -= samplesPerRow;

        gotIndex++;

        var lRMin:Float = Math.abs(lmin) * multiply;
        var lRMax:Float = lmax * multiply;

        var rRMin:Float = Math.abs(rmin) * multiply;
        var rRMax:Float = rmax * multiply;

        if (gotIndex > array[0][0].length) array[0][0].push(lRMin);
        else
          array[0][0][gotIndex - 1] = array[0][0][gotIndex - 1] + lRMin;

        if (gotIndex > array[0][1].length) array[0][1].push(lRMax);
        else
          array[0][1][gotIndex - 1] = array[0][1][gotIndex - 1] + lRMax;

        if (channels >= 2)
        {
          if (gotIndex > array[1][0].length) array[1][0].push(rRMin);
          else
            array[1][0][gotIndex - 1] = array[1][0][gotIndex - 1] + rRMin;

          if (gotIndex > array[1][1].length) array[1][1].push(rRMax);
          else
            array[1][1][gotIndex - 1] = array[1][1][gotIndex - 1] + rRMax;
        } else
        {
          if (gotIndex > array[1][0].length) array[1][0].push(lRMin);
          else
            array[1][0][gotIndex - 1] = array[1][0][gotIndex - 1] + lRMin;

          if (gotIndex > array[1][1].length) array[1][1].push(lRMax);
          else
            array[1][1][gotIndex - 1] = array[1][1][gotIndex - 1] + lRMax;
        }

        lmin = 0;
        lmax = 0;

        rmin = 0;
        rmax = 0;
      }

      index++;
      rows++;
      if (gotIndex > steps) break;
    }

    return array;
    #else
    return [[[0], [0]], [[0], [0]]];
    #end
  }
}
