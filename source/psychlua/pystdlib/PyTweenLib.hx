package psychlua.pystdlib;

import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import psychlua.PythonScript;
import play.PlayState;
import objects.StrumNote;
import headers.PsychLua;

// REFACTOR: extracted from psychlua.PythonScript (tween API)
class PyTweenLib
{
	public static function register(py:PythonScript):Void {
		@:privateAccess {
		// ---------------------------------------------------------------- //
		//                           TWEENS                                 //
		// ---------------------------------------------------------------- //
		PythonScript.registerFunction("doTweenX", function(tag:String, vars:String, value:Dynamic, duration:Float, ease:String) {
			var penisExam:Dynamic = py.tweenPrepare(tag, vars);
			if(penisExam != null) {
				PlayState.instance.modchartTweens.set(tag, FlxTween.tween(penisExam, {x: value}, duration / PlayState.instance.playbackRate, {ease: LuaUtils.getFlxEaseByString(ease),
					onComplete: function(twn:FlxTween) {
						PlayState.instance.callOnLuas('onTweenCompleted', [tag]);
						PlayState.instance.modchartTweens.remove(tag);
					}
				}));
			} else {
				py.pyTrace('doTweenX | Couldnt find object: ' + vars, false, false, FlxColor.RED);
			}
		});
		PythonScript.registerFunction("doTweenScale", function(tag:String, vars:String, value:Dynamic, duration:Float, ease:String) {
			var penisExam:Dynamic = py.tweenPrepare(tag, vars);
			if(penisExam != null) {
				PlayState.instance.modchartTweens.set(tag, FlxTween.tween(penisExam, {"scale.x": value, "scale.y": value}, duration / PlayState.instance.playbackRate, {ease: LuaUtils.getFlxEaseByString(ease),
					onComplete: function(twn:FlxTween) {
						PlayState.instance.callOnLuas('onTweenCompleted', [tag]);
						PlayState.instance.modchartTweens.remove(tag);
					}
				}));
			} else {
				py.pyTrace('doTweenScale | Couldnt find object: ' + vars, false, false, FlxColor.RED);
			}
		});
		PythonScript.registerFunction("doTweenY", function(tag:String, vars:String, value:Dynamic, duration:Float, ease:String) {
			var penisExam:Dynamic = py.tweenPrepare(tag, vars);
			if(penisExam != null) {
				PlayState.instance.modchartTweens.set(tag, FlxTween.tween(penisExam, {y: value}, duration / PlayState.instance.playbackRate, {ease: LuaUtils.getFlxEaseByString(ease),
					onComplete: function(twn:FlxTween) {
						PlayState.instance.callOnLuas('onTweenCompleted', [tag]);
						PlayState.instance.modchartTweens.remove(tag);
					}
				}));
			} else {
				py.pyTrace('doTweenY | Couldnt find object: ' + vars, false, false, FlxColor.RED);
			}
		});
		PythonScript.registerFunction("doTweenAngle", function(tag:String, vars:String, value:Dynamic, duration:Float, ease:String) {
			var penisExam:Dynamic = py.tweenPrepare(tag, vars);
			if(penisExam != null) {
				PlayState.instance.modchartTweens.set(tag, FlxTween.tween(penisExam, {angle: value}, duration / PlayState.instance.playbackRate, {ease: LuaUtils.getFlxEaseByString(ease),
					onComplete: function(twn:FlxTween) {
						PlayState.instance.callOnLuas('onTweenCompleted', [tag]);
						PlayState.instance.modchartTweens.remove(tag);
					}
				}));
			} else {
				py.pyTrace('doTweenAngle | Couldnt find object: ' + vars, false, false, FlxColor.RED);
			}
		});
		PythonScript.registerFunction("doTweenAlpha", function(tag:String, vars:String, value:Dynamic, duration:Float, ease:String) {
			var penisExam:Dynamic = py.tweenPrepare(tag, vars);
			if(penisExam != null) {
				PlayState.instance.modchartTweens.set(tag, FlxTween.tween(penisExam, {alpha: value}, duration / PlayState.instance.playbackRate, {ease: LuaUtils.getFlxEaseByString(ease),
					onComplete: function(twn:FlxTween) {
						PlayState.instance.callOnLuas('onTweenCompleted', [tag]);
						PlayState.instance.modchartTweens.remove(tag);
					}
				}));
			} else {
				py.pyTrace('doTweenAlpha | Couldnt find object: ' + vars, false, false, FlxColor.RED);
			}
		});
		PythonScript.registerFunction("doTweenZoom", function(tag:String, vars:String, value:Dynamic, duration:Float, ease:String) {
			var penisExam:Dynamic = py.tweenPrepare(tag, vars);
			if(penisExam != null) {
				if(vars == 'camHud' || vars == 'camGame' || vars == 'Hud' || vars == 'Game') {
					PlayState.instance.modchartTweens.set(tag, FlxTween.tween(penisExam, {zoom: value}, duration / PlayState.instance.playbackRate, {ease: LuaUtils.getFlxEaseByString(ease),
						onComplete: function(twn:FlxTween) {
							PlayState.instance.callOnLuas('onTweenCompleted', [tag]);
							PlayState.instance.modchartTweens.remove(tag);
						}
					}));
				}
				else {
					py.pyTrace("doTweenZoom | Can't tween object " + vars + ". Value needs to be a camera.", false, false, FlxColor.RED);
				}
			} else {
				py.pyTrace('doTweenZoom | Couldnt find object: ' + vars, false, false, FlxColor.RED);
			}
		});
		PythonScript.registerFunction("doTweenColor", function(tag:String, vars:String, targetColor:String, duration:Float, ease:String) {
			var penisExam:Dynamic = py.tweenPrepare(tag, vars);
			if(penisExam != null) {
				var color:Int = Std.parseInt(targetColor);
				if(!targetColor.startsWith('0x')) color = Std.parseInt('0xff' + targetColor);

				var curColor:FlxColor = penisExam.color;
				curColor.alphaFloat = penisExam.alpha;
				PlayState.instance.modchartTweens.set(tag, FlxTween.color(penisExam, duration / PlayState.instance.playbackRate, curColor, color, {ease: LuaUtils.getFlxEaseByString(ease),
					onComplete: function(twn:FlxTween) {
						PlayState.instance.modchartTweens.remove(tag);
						PlayState.instance.callOnLuas('onTweenCompleted', [tag]);
					}
				}));
			} else {
				py.pyTrace('doTweenColor | Couldnt find object: ' + vars, false, false, FlxColor.RED);
			}
		});

		// Tween shit, but for strums
		PythonScript.registerFunction("noteTweenX", function(tag:String, note:Int, value:Dynamic, duration:Float, ease:String) {
			py.cancelTween(tag);
			if(note < 0) note = 0;
			var testicle:StrumNote = PlayState.instance.strumLineNotes.members[note % PlayState.instance.strumLineNotes.length];

			if(testicle != null) {
				PlayState.instance.modchartTweens.set(tag, FlxTween.tween(testicle, {x: value}, duration / PlayState.instance.playbackRate, {ease: LuaUtils.getFlxEaseByString(ease),
					onComplete: function(twn:FlxTween) {
						PlayState.instance.callOnLuas('onTweenCompleted', [tag]);
						PlayState.instance.modchartTweens.remove(tag);
					}
				}));
			}
		});
		PythonScript.registerFunction("noteTweenY", function(tag:String, note:Int, value:Dynamic, duration:Float, ease:String) {
			py.cancelTween(tag);
			if(note < 0) note = 0;
			var testicle:StrumNote = PlayState.instance.strumLineNotes.members[note % PlayState.instance.strumLineNotes.length];

			if(testicle != null) {
				PlayState.instance.modchartTweens.set(tag, FlxTween.tween(testicle, {y: value}, duration / PlayState.instance.playbackRate, {ease: LuaUtils.getFlxEaseByString(ease),
					onComplete: function(twn:FlxTween) {
						PlayState.instance.callOnLuas('onTweenCompleted', [tag]);
						PlayState.instance.modchartTweens.remove(tag);
					}
				}));
			}
		});
		PythonScript.registerFunction("noteTweenAngle", function(tag:String, note:Int, value:Dynamic, duration:Float, ease:String) {
			py.cancelTween(tag);
			if(note < 0) note = 0;
			var testicle:StrumNote = PlayState.instance.strumLineNotes.members[note % PlayState.instance.strumLineNotes.length];

			if(testicle != null) {
				PlayState.instance.modchartTweens.set(tag, FlxTween.tween(testicle, {angle: value}, duration / PlayState.instance.playbackRate, {ease: LuaUtils.getFlxEaseByString(ease),
					onComplete: function(twn:FlxTween) {
						PlayState.instance.callOnLuas('onTweenCompleted', [tag]);
						PlayState.instance.modchartTweens.remove(tag);
					}
				}));
			}
		});
		PythonScript.registerFunction("noteTweenDirection", function(tag:String, note:Int, value:Dynamic, duration:Float, ease:String) {
			py.cancelTween(tag);
			if(note < 0) note = 0;
			var testicle:StrumNote = PlayState.instance.strumLineNotes.members[note % PlayState.instance.strumLineNotes.length];

			if(testicle != null) {
				PlayState.instance.modchartTweens.set(tag, FlxTween.tween(testicle, {direction: value}, duration / PlayState.instance.playbackRate, {ease: LuaUtils.getFlxEaseByString(ease),
					onComplete: function(twn:FlxTween) {
						PlayState.instance.callOnLuas('onTweenCompleted', [tag]);
						PlayState.instance.modchartTweens.remove(tag);
					}
				}));
			}
		});
		PythonScript.registerFunction("noteTweenAlpha", function(tag:String, note:Int, value:Dynamic, duration:Float, ease:String) {
			py.cancelTween(tag);
			if(note < 0) note = 0;
			var testicle:StrumNote = PlayState.instance.strumLineNotes.members[note % PlayState.instance.strumLineNotes.length];

			if(testicle != null) {
				PlayState.instance.modchartTweens.set(tag, FlxTween.tween(testicle, {alpha: value}, duration / PlayState.instance.playbackRate, {ease: LuaUtils.getFlxEaseByString(ease),
					onComplete: function(twn:FlxTween) {
						PlayState.instance.callOnLuas('onTweenCompleted', [tag]);
						PlayState.instance.modchartTweens.remove(tag);
					}
				}));
			}
		});
		PythonScript.registerFunction("noteTweenScaleX", function(tag:String, note:Int, value:Dynamic, duration:Float, ease:String) {
			py.cancelTween(tag);
			if(note < 0) note = 0;
			var testicle:StrumNote = PlayState.instance.strumLineNotes.members[note % PlayState.instance.strumLineNotes.length];

			if(testicle != null) {
				PlayState.instance.modchartTweens.set(tag, FlxTween.tween(testicle, {"scale.x": value * 0.7}, duration, {ease: LuaUtils.getFlxEaseByString(ease),
					onComplete: function(twn:FlxTween) {
						PlayState.instance.callOnLuas('onTweenCompleted', [tag]);
						PlayState.instance.modchartTweens.remove(tag);
					}
				}));
			}
		});
		PythonScript.registerFunction("noteTweenScaleY", function(tag:String, note:Int, value:Dynamic, duration:Float, ease:String) {
			py.cancelTween(tag);
			if(note < 0) note = 0;
			var testicle:StrumNote = PlayState.instance.strumLineNotes.members[note % PlayState.instance.strumLineNotes.length];

			if(testicle != null) {
				PlayState.instance.modchartTweens.set(tag, FlxTween.tween(testicle, {"scale.y": value * 0.7}, duration, {ease: LuaUtils.getFlxEaseByString(ease),
					onComplete: function(twn:FlxTween) {
						PlayState.instance.callOnLuas('onTweenCompleted', [tag]);
						PlayState.instance.modchartTweens.remove(tag);
					}
				}));
			}
		});

		PythonScript.registerFunction("cancelTween", function(tag:String) {
			py.cancelTween(tag);
		});
		}
	}
}
