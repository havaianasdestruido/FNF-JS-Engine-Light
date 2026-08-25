package psychlua.callbacks;

import backend.ClientPrefs;
import play.PlayState;
import psychlua.FunkinLua;
import psychlua.LuaUtils;
import shaders.ChromaticAberrationEffect;
import shaders.ScanlineEffect;
import shaders.GrainEffect;
import shaders.TiltshiftEffect;
import shaders.VCRDistortionEffect;
import shaders.WiggleEffectLua;
import shaders.GlitchEffect;
import shaders.PulseEffect;
import shaders.DistortBGEffect;
import shaders.InvertColorsEffect;
import shaders.GreyscaleEffect;
import shaders.ThreeDEffect;
import shaders.BloomEffect;
import shaders.BlockedGlitchEffect;

// REFACTOR: extracted from psychlua.FunkinLua (camera shader effect adders)
class EffectCallbacks
{
	public static function register(funk:FunkinLua):Void {
		@:privateAccess {
		//SHADER SHIT
		if (ClientPrefs.shaders) {
			FunkinLua.registerFunction("addChromaticAbberationEffect", function(camera:String,chromeOffset:Float = 0.005) {

				PlayState.instance.addShaderToCamera(camera, new ChromaticAberrationEffect(chromeOffset));

			});

			FunkinLua.registerFunction("addScanlineEffect", function(camera:String,lockAlpha:Bool=false) {

				PlayState.instance.addShaderToCamera(camera, new ScanlineEffect(lockAlpha));

			});
			FunkinLua.registerFunction("addGrainEffect", function(camera:String,grainSize:Float,lumAmount:Float,lockAlpha:Bool=false) {

				PlayState.instance.addShaderToCamera(camera, new GrainEffect(grainSize,lumAmount,lockAlpha));

			});
			FunkinLua.registerFunction("addTiltshiftEffect", function(camera:String,blurAmount:Float,center:Float) {

				PlayState.instance.addShaderToCamera(camera, new TiltshiftEffect(blurAmount,center));

			});
			FunkinLua.registerFunction("addVCREffect", function(camera:String,glitchFactor:Float = 0.0,distortion:Bool=true,perspectiveOn:Bool=true,vignetteMoving:Bool=true) {

				PlayState.instance.addShaderToCamera(camera, new VCRDistortionEffect(glitchFactor,distortion,perspectiveOn,vignetteMoving));

			});

			// shader clear

			FunkinLua.registerFunction("clearShadersFromCamera", function(cameraName)
			{
				LuaUtils.cameraFromString(cameraName).filters = [];
			});

			FunkinLua.registerFunction("addWiggleEffect", function(camera:String, effectType:String, waveSpeed:Float = 0.1,waveFrq:Float = 0.1,waveAmp:Float = 0.1, ?verticalStrength:Float = 1, ?horizontalStrength:Float = 1) {
				PlayState.instance.addShaderToCamera(camera, new WiggleEffectLua(effectType, waveSpeed, waveFrq, waveAmp,
					verticalStrength, horizontalStrength));
			});
			FunkinLua.registerFunction("addGlitchEffect", function(camera:String,waveSpeed:Float = 0.1,waveFrq:Float = 0.1,waveAmp:Float = 0.1) {
				PlayState.instance.addShaderToCamera(camera, new GlitchEffect(waveSpeed,waveFrq,waveAmp));
			});
			FunkinLua.registerFunction("addGlitchShader", function(camera:String,waveAmp:Float = 0.1,waveFrq:Float = 0.1,waveSpeed:Float = 0.1) {
				PlayState.instance.addShaderToCamera(camera, new GlitchEffect(waveSpeed,waveFrq,waveAmp));
			});
			FunkinLua.registerFunction("addPulseEffect", function(camera:String,waveSpeed:Float = 0.1,waveFrq:Float = 0.1,waveAmp:Float = 0.1) {

				PlayState.instance.addShaderToCamera(camera, new PulseEffect(waveSpeed,waveFrq,waveAmp));

			});
			FunkinLua.registerFunction("addDistortionEffect", function(camera:String,waveSpeed:Float = 0.1,waveFrq:Float = 0.1,waveAmp:Float = 0.1) {

				PlayState.instance.addShaderToCamera(camera, new DistortBGEffect(waveSpeed,waveFrq,waveAmp));

			});
			FunkinLua.registerFunction("addInvertEffect", function(camera:String,lockAlpha:Bool=false) {

				PlayState.instance.addShaderToCamera(camera, new InvertColorsEffect(lockAlpha));

			});
			FunkinLua.registerFunction("addGreyscaleEffect", function(camera:String) { //for dem funkies

				PlayState.instance.addShaderToCamera(camera, new GreyscaleEffect());

			});
			FunkinLua.registerFunction("addGrayscaleEffect", function(camera:String) { //for dem funkies

				PlayState.instance.addShaderToCamera(camera, new GreyscaleEffect());

			});
			FunkinLua.registerFunction("add3DEffect", function(camera:String,xrotation:Float=0,yrotation:Float=0,zrotation:Float=0,depth:Float=0) { //for dem funkies
				PlayState.instance.addShaderToCamera(camera, new ThreeDEffect(xrotation,yrotation,zrotation,depth));
			});
			FunkinLua.registerFunction("addBloomEffect", function(camera:String,intensity:Float = 0.35,blurSize:Float=1.0) {
				PlayState.instance.addShaderToCamera(camera, new BloomEffect(blurSize/512.0,intensity));
			});
			FunkinLua.registerFunction("addBlockedGlitchEffect", function(camera:String, res:Float = 1280, time:Float = 1, colorMult:Float = 1, colorTransform:Bool = true) {
				if (colorTransform) PlayState.instance.addShaderToCamera(camera, new BlockedGlitchEffect(res, time, colorMult, colorTransform));
			});
			FunkinLua.registerFunction("clearEffects", function(camera:String) {
				PlayState.instance.clearShaderFromCamera(camera);
			});
		}
		}
	}
}
