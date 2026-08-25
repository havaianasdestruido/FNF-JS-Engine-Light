package shaders;

class FuckingTriangleEffect extends Effect
{
  public var shader:FuckingTriangle = new FuckingTriangle();

  public function new(rotx:Float, roty:Float)
  {
    shader.rotX.value = [rotx];
    shader.rotY.value = [roty];
  }
}
