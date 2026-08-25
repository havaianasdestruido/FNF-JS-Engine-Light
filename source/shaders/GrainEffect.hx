package shaders;

import play.PlayState;

class GrainEffect extends Effect
{
  public var shader:Grain;

  public function new(grainsize, lumamount, lockAlpha)
  {
    shader = new Grain();
    shader.lumamount.value = [lumamount];
    shader.grainsize.value = [grainsize];
    shader.lockAlpha.value = [lockAlpha];
    shader.uTime.value = [FlxG.random.float(0, 8)];
    PlayState.instance.shaderUpdates.push(update);
  }

  public function update(elapsed)
  {
    shader.uTime.value[0] += elapsed;
  }
}
