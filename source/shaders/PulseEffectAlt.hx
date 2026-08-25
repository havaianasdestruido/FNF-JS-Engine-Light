package shaders;

class PulseEffectAlt
{
  public var shader(default, null):PulseShader;

  public var waveSpeed(default, set):Float = 0;
  public var waveFrequency(default, set):Float = 0;
  public var waveAmplitude(default, set):Float = 0;
  public var enabled(default, set):Bool = false;

  public function new():Void
  {
    shader = new PulseShader();
    shader.speed = 0;
    shader.frequency = 0;
    shader.waveAmplitude = 0;
    shader.enabled = false;
  }

  public function update(elapsed:Float):Void
  {
    shader.update(elapsed);
  }

  function set_waveSpeed(v:Float):Float
  {
    waveSpeed = v;
    shader.speed = v;
    return v;
  }

  function set_enabled(v:Bool):Bool
  {
    enabled = v;
    shader.enabled = v;
    return v;
  }

  function set_waveFrequency(v:Float):Float
  {
    waveFrequency = v;
    shader.frequency = v;
    return v;
  }

  function set_waveAmplitude(v:Float):Float
  {
    waveAmplitude = v;
    shader.waveAmplitude = v;
    return v;
  }
}
