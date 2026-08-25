package shaders;

class BuildingEffect
{
  public var shader:BuildingShader = new BuildingShader();

  public function new()
  {
    shader.alphaShit.value = [0.0];
  }

  public function addAlpha(alpha:Float)
  {
    trace(shader.alphaShit.value[0]);
    shader.alphaShit.value[0] += alpha;
  }

  public function setAlpha(alpha:Float)
  {
    shader.alphaShit.value[0] = alpha;
  }
}
