package shaders;

import play.PlayState;

class BlockedGlitchEffect
{
  public var shader(default, null):BlockedGlitchShader = new BlockedGlitchShader();

  public var time(default, set):Float = 0;
  public var resolution(default, set):Float = 0;
  public var colorMultiplier(default, set):Float = 0;
  public var hasColorTransform(default, set):Bool = false;

  public function new(res:Float, time:Float, colorMultiplier:Float, colorTransform:Bool):Void
  {
    set_time(time);
    set_resolution(res);
    set_colorMultiplier(colorMultiplier);
    set_hasColorTransform(colorTransform);
    PlayState.instance.shaderUpdates.push(update);
  }

  public function update(elapsed:Float):Void
  {
    shader.time.value[0] += elapsed;
  }

  public function set_resolution(v:Float):Float
  {
    resolution = v;
    shader.screenSize.value = [resolution];
    return this.resolution;
  }

  function set_hasColorTransform(value:Bool):Bool
  {
    this.hasColorTransform = value;
    shader.hasColorTransform.value = [hasColorTransform];
    return hasColorTransform;
  }

  function set_colorMultiplier(value:Float):Float
  {
    this.colorMultiplier = value;
    shader.colorMultiplier.value = [value];
    return this.colorMultiplier;
  }

  function set_time(value:Float):Float
  {
    this.time = value;
    shader.time.value = [value];
    return this.time;
  }
}
