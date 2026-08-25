package shaders;

class ThreeDEffect extends Effect
{
  public var shader:ThreeDShader = new ThreeDShader();

  public function new(xrotation:Float = 0, yrotation:Float = 0, zrotation:Float = 0, depth:Float = 0)
  {
    shader.xrot.value = [xrotation];
    shader.yrot.value = [yrotation];
    shader.zrot.value = [zrotation];
    shader.dept.value = [depth];
  }
}
