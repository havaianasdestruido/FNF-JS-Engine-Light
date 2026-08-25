package shaders;

class ChromaticAberrationEffect extends Effect
{
  public var shader:ChromaticAberrationShader;

  public function new(offset:Float = 0.00)
  {
    shader = new ChromaticAberrationShader();
    shader.rOffset.value = [offset];
    shader.gOffset.value = [0.0];
    shader.bOffset.value = [-offset];
  }

  public function setChrome(chromeOffset:Float):Void
  {
    shader.rOffset.value = [chromeOffset];
    shader.gOffset.value = [0.0];
    shader.bOffset.value = [chromeOffset * -1];
  }
}
