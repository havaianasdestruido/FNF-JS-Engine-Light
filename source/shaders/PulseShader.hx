package shaders;

import shaders.ErrorHandledShader.ErrorHandledRuntimeShader;

class PulseShader extends ErrorHandledRuntimeShader
{
  public var waveAmplitude(default, set):Float = 0;
  public var frequency(default, set):Float = 1;
  public var speed(default, set):Float = 1;
  public var time(default, set):Float = 0;
  public var enabled(default, set):Bool = false;

  public function new()
  {
    super('Pulse Effect', shaders.RuntimeShaders.pulseEffect);

    // Initialize with default values
    this.setFloat('uWaveAmplitude', waveAmplitude);
    this.setFloat('uFrequency', frequency);
    this.setFloat('uSpeed', speed);
    this.setFloat('uTime', time);
    this.setBool('uEnabled', enabled);
  }

  // Setters to automatically update shader uniforms when properties change
  function set_waveAmplitude(value:Float):Float
  {
    waveAmplitude = value;
    setFloat('uWaveAmplitude', value);
    return value;
  }

  function set_frequency(value:Float):Float
  {
    frequency = value;
    setFloat('uFrequency', value);
    return value;
  }

  function set_speed(value:Float):Float
  {
    speed = value;
    setFloat('uSpeed', value);
    return value;
  }

  function set_time(value:Float):Float
  {
    time = value;
    setFloat('uTime', value);
    return value;
  }

  function set_enabled(value:Bool):Bool
  {
    enabled = value;
    setBool('uEnabled', value);
    return value;
  }

  public function update(elapsed:Float):Void
  {
    if (enabled) time += elapsed * speed;
  }
}
