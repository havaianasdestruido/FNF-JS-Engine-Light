package shaders;

import openfl.Lib;

import play.PlayState;

class VCRDistortionEffect extends Effect
{
  public var shader:VCRDistortionShader = new VCRDistortionShader();

  public function new(glitchFactor:Float, distortion:Bool = true, perspectiveOn:Bool = true, vignetteMoving:Bool = true)
  {
    shader.iTime.value = [0.0];
    shader.vignetteOn.value = [true];
    shader.perspectiveOn.value = [perspectiveOn];
    shader.distortionOn.value = [distortion];
    shader.scanlinesOn.value = [true];
    shader.vignetteMoving.value = [vignetteMoving];
    shader.glitchModifier.value = [glitchFactor];
    shader.iResolution.value = [Lib.current.stage.stageWidth, Lib.current.stage.stageHeight];
    PlayState.instance.shaderUpdates.push(update);
  }

  public function update(elapsed:Float)
  {
    shader.iTime.value[0] += elapsed;
    shader.iResolution.value = [Lib.current.stage.stageWidth, Lib.current.stage.stageHeight];
  }

  public function setVignette(state:Bool)
  {
    shader.vignetteOn.value[0] = state;
  }

  public function setPerspective(state:Bool)
  {
    shader.perspectiveOn.value[0] = state;
  }

  public function setGlitchModifier(modifier:Float)
  {
    shader.glitchModifier.value[0] = modifier;
  }

  public function setDistortion(state:Bool)
  {
    shader.distortionOn.value[0] = state;
  }

  public function setScanlines(state:Bool)
  {
    shader.scanlinesOn.value[0] = state;
  }

  public function setVignetteMoving(state:Bool)
  {
    shader.vignetteMoving.value[0] = state;
  }
}
