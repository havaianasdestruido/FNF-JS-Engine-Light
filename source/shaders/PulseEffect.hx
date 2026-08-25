package shaders;

import play.PlayState;

class PulseEffect extends Effect
{
  public var shader:PulseShader;

  public var waveSpeed(default, set):Float = 0;
  public var waveFrequency(default, set):Float = 0;
  public var waveAmplitude(default, set):Float = 0;
  public var enabled(default, set):Bool = false;

  public function new(waveSpeed:Float, waveFrequency:Float, waveAmplitude:Float):Void
  {
    shader = new PulseShader();

    this.waveSpeed = waveSpeed;
    this.waveFrequency = waveFrequency;
    this.waveAmplitude = waveAmplitude;
    this.enabled = false;

    // PulseShader constructor already sets defaults,
    // but we override with our specific values
    shader.speed = waveSpeed;
    shader.frequency = waveFrequency;
    shader.waveAmplitude = waveAmplitude;
    shader.enabled = false;
    shader.time = 0;

    PlayState.instance.shaderUpdates.push(update);
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
