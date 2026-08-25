package shaders;

class TiltshiftEffect extends Effect
{
  public var shader:Tiltshift;

  public function new(blurAmount:Float, center:Float)
  {
    shader = new Tiltshift();
    shader.bluramount.value = [blurAmount];
    shader.center.value = [center];
  }
}
