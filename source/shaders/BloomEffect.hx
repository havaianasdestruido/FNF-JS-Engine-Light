package shaders;

import flixel.system.FlxAssets.FlxShader;

class BloomEffect extends Effect
{
  public var shader:BloomShader = new BloomShader();

  public function new(blurSize:Float, intensity:Float)
  {
    shader.blurSize.value = [blurSize];
    shader.intensity.value = [intensity];
  }
}
