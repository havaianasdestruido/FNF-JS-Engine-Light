package shaders;

class ScanlineEffect extends Effect
{
  public var shader:Scanline;

  public function new(lockAlpha)
  {
    shader = new Scanline();
    shader.lockAlpha.value = [lockAlpha];
  }
}
