package psychlua.pystdlib;

import flixel.FlxObject;
import flixel.FlxSprite;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.util.FlxColor;
import psychlua.FunkinLua;
import psychlua.PythonScript;
import backend.ClientPrefs;
import backend.Paths;
import flixel.util.FlxAxes;
import objects.Character;
import play.PlayState;
import psychlua.LuaUtils;
import psychlua.ModchartSprite;
import states.substates.GameOverSubstate;

// REFACTOR: extracted from psychlua.PythonScript (sprite/animation API)
class PySpriteLib
{
	public static function register(py:PythonScript):Void {
		final game:PlayState = PlayState.instance;
		@:privateAccess {
		// ---------------------------------------------------------------- //
		//                           SPRITES                                //
		// ---------------------------------------------------------------- //
		PythonScript.registerFunction("makeLuaSprite", function(tag:String, image:String, x:Float, y:Float) {
			tag = tag.replace('.', '');
			py.resetSpriteTag(tag);
			var leSprite:ModchartSprite = new ModchartSprite(x, y);
			if(image != null && image.length > 0) {
				leSprite.loadGraphic(Paths.image(image));
			}
			leSprite.antialiasing = ClientPrefs.globalAntialiasing;
			PlayState.instance.modchartSprites.set(tag, leSprite);
			leSprite.active = true;
		});
		PythonScript.registerFunction("makeAnimatedLuaSprite", function(tag:String, image:String, x:Float, y:Float, ?spriteType:String = "sparrow") {
			tag = tag.replace('.', '');
			py.resetSpriteTag(tag);
			var leSprite:ModchartSprite = new ModchartSprite(x, y);
			py.loadFrames(leSprite, image, spriteType);
			leSprite.antialiasing = ClientPrefs.globalAntialiasing;
			PlayState.instance.modchartSprites.set(tag, leSprite);
		});
		PythonScript.registerFunction("makeGraphic", function(obj:String, width:Int, height:Int, color:String) {
			var colorNum:Int = Std.parseInt(color);
			if(!color.startsWith('0x')) colorNum = Std.parseInt('0xff' + color);

			var spr:FlxSprite = PlayState.instance.getLuaObject(obj, false);
			if(spr != null) {
				PlayState.instance.getLuaObject(obj, false).makeGraphic(width, height, colorNum);
				return;
			}

			var object:FlxSprite = Reflect.getProperty(py.getInstance(), obj);
			if(object != null) {
				object.makeGraphic(width, height, colorNum);
			}
		});
		PythonScript.registerFunction("addAnimationByPrefix", function(obj:String, name:String, prefix:String, framerate:Int = 24, loop:Bool = true) {
			if(PlayState.instance.getLuaObject(obj, false) != null) {
				var cock:FlxSprite = PlayState.instance.getLuaObject(obj, false);
				cock.animation.addByPrefix(name, prefix, framerate, loop);
				if(cock.animation.curAnim == null) {
					cock.animation.play(name, true);
				}
				return;
			}

			var cock:FlxSprite = Reflect.getProperty(py.getInstance(), obj);
			if(cock != null) {
				cock.animation.addByPrefix(name, prefix, framerate, loop);
				if(cock.animation.curAnim == null) {
					cock.animation.play(name, true);
				}
			}
		});
		PythonScript.registerFunction("addAnimation", function(obj:String, name:String, frames:Array<Int>, framerate:Int = 24, loop:Bool = true) {
			if(PlayState.instance.getLuaObject(obj, false) != null) {
				var cock:FlxSprite = PlayState.instance.getLuaObject(obj, false);
				cock.animation.add(name, frames, framerate, loop);
				if(cock.animation.curAnim == null) {
					cock.animation.play(name, true);
				}
				return;
			}

			var cock:FlxSprite = Reflect.getProperty(py.getInstance(), obj);
			if(cock != null) {
				cock.animation.add(name, frames, framerate, loop);
				if(cock.animation.curAnim == null) {
					cock.animation.play(name, true);
				}
			}
		});
		PythonScript.registerFunction("addAnimationByIndices", function(obj:String, name:String, prefix:String, indices:String, framerate:Int = 24) {
			return PythonScript.addAnimByIndices(obj, name, prefix, indices, framerate, false);
		});
		PythonScript.registerFunction("addAnimationByIndicesLoop", function(obj:String, name:String, prefix:String, indices:String, framerate:Int = 24) {
			return PythonScript.addAnimByIndices(obj, name, prefix, indices, framerate, true);
		});
		PythonScript.registerFunction("playAnim", function(obj:String, name:String, forced:Bool = false, ?reverse:Bool = false, ?startFrame:Int = 0) {
			if(PlayState.instance.getLuaObject(obj, false) != null) {
				var luaObj:FlxSprite = PlayState.instance.getLuaObject(obj, false);
				if(luaObj.animation.getByName(name) != null) {
					luaObj.animation.play(name, forced, reverse, startFrame);
					if(Std.isOfType(luaObj, ModchartSprite)) {
						var daOffset = cast(luaObj, ModchartSprite).animOffsets.get(name);
						if(daOffset != null) {
							luaObj.offset.set(daOffset[0], daOffset[1]);
						}
					}
				}
				return true;
			}

			var spr:FlxSprite = Reflect.getProperty(py.getInstance(), obj);
			if(spr != null) {
				if(spr.animation.getByName(name) != null) {
					if(Std.isOfType(spr, Character)) {
						cast(spr, Character).playAnim(name, forced, reverse, startFrame);
					}
					else
						spr.animation.play(name, forced, reverse, startFrame);
				}
				return true;
			}
			return false;
		});
		PythonScript.registerFunction("addOffset", function(obj:String, anim:String, x:Float, y:Float) {
			if(PlayState.instance.modchartSprites.exists(obj)) {
				PlayState.instance.modchartSprites.get(obj).animOffsets.set(anim, [x, y]);
				return true;
			}

			var char:Character = Reflect.getProperty(py.getInstance(), obj);
			if(char != null) {
				char.addOffset(anim, x, y);
				return true;
			}
			return false;
		});
		PythonScript.registerFunction("setScrollFactor", function(obj:String, scrollX:Float, scrollY:Float) {
			if(PlayState.instance.getLuaObject(obj, false) != null) {
				PlayState.instance.getLuaObject(obj, false).scrollFactor.set(scrollX, scrollY);
				return;
			}

			var object:FlxObject = Reflect.getProperty(py.getInstance(), obj);
			if(object != null) {
				object.scrollFactor.set(scrollX, scrollY);
			}
		});
		PythonScript.registerFunction("addLuaSprite", function(tag:String, front:Bool = false) {
			if(PlayState.instance.modchartSprites.exists(tag)) {
				var shit:ModchartSprite = PlayState.instance.modchartSprites.get(tag);
				if(!shit.wasAdded) {
					if(front) {
						py.getInstance().add(shit);
					}
					else {
						if(PlayState.instance.isDead) {
							GameOverSubstate.instance.insert(GameOverSubstate.instance.members.indexOf(GameOverSubstate.instance.boyfriend), shit);
						}
						else {
							var position:Int = PlayState.instance.members.indexOf(PlayState.instance.gfGroup);
							if(PlayState.instance.members.indexOf(PlayState.instance.boyfriendGroup) < position) {
								position = PlayState.instance.members.indexOf(PlayState.instance.boyfriendGroup);
							} else if(PlayState.instance.members.indexOf(PlayState.instance.dadGroup) < position) {
								position = PlayState.instance.members.indexOf(PlayState.instance.dadGroup);
							}
							PlayState.instance.insert(position, shit);
						}
					}
					shit.wasAdded = true;
				}
			}
		});
		PythonScript.registerFunction("setGraphicSize", function(obj:String, x:Int, y:Int = 0, updateHitbox:Bool = true) {
			if(PlayState.instance.getLuaObject(obj) != null) {
				var shit:FlxSprite = PlayState.instance.getLuaObject(obj);
				shit.setGraphicSize(x, y);
				if(updateHitbox) shit.updateHitbox();
				return;
			}

			var killMe:Array<String> = obj.split('.');
			var poop:FlxSprite = FunkinLua.getObjectDirectly(killMe[0]);
			if(killMe.length > 1) {
				poop = FunkinLua.getVarInArray(FunkinLua.getPropertyLoopThingWhatever(killMe), killMe[killMe.length-1]);
			}

			if(poop != null) {
				poop.setGraphicSize(x, y);
				if(updateHitbox) poop.updateHitbox();
				return;
			}
			py.pyTrace('setGraphicSize | Couldnt find object: ' + obj, false, false, FlxColor.RED);
		});
		PythonScript.registerFunction("scaleObject", function(obj:String, x:Float, y:Float, updateHitbox:Bool = true) {
			if(PlayState.instance.getLuaObject(obj) != null) {
				var shit:FlxSprite = PlayState.instance.getLuaObject(obj);
				shit.scale.set(x, y);
				if(updateHitbox) shit.updateHitbox();
				return;
			}

			var killMe:Array<String> = obj.split('.');
			var poop:FlxSprite = FunkinLua.getObjectDirectly(killMe[0]);
			if(killMe.length > 1) {
				poop = FunkinLua.getVarInArray(FunkinLua.getPropertyLoopThingWhatever(killMe), killMe[killMe.length-1]);
			}

			if(poop != null) {
				poop.scale.set(x, y);
				if(updateHitbox) poop.updateHitbox();
				return;
			}
			py.pyTrace('scaleObject | Couldnt find object: ' + obj, false, false, FlxColor.RED);
		});
		PythonScript.registerFunction("updateHitbox", function(obj:String) {
			if(PlayState.instance.getLuaObject(obj) != null) {
				var shit:FlxSprite = PlayState.instance.getLuaObject(obj);
				shit.updateHitbox();
				return;
			}

			var poop:FlxSprite = Reflect.getProperty(py.getInstance(), obj);
			if(poop != null) {
				poop.updateHitbox();
				return;
			}
			py.pyTrace('updateHitbox | Couldnt find object: ' + obj, false, false, FlxColor.RED);
		});
		PythonScript.registerFunction("updateHitboxFromGroup", function(group:String, index:Int) {
			if(Std.isOfType(Reflect.getProperty(py.getInstance(), group), FlxTypedGroup)) {
				Reflect.getProperty(py.getInstance(), group).members[index].updateHitbox();
				return;
			}
			Reflect.getProperty(py.getInstance(), group)[index].updateHitbox();
		});
		PythonScript.registerFunction("removeLuaSprite", function(tag:String, destroy:Bool = true) {
			if(!PlayState.instance.modchartSprites.exists(tag)) {
				return;
			}

			var pee:ModchartSprite = PlayState.instance.modchartSprites.get(tag);
			if(destroy) {
				pee.kill();
			}

			if(pee.wasAdded) {
				py.getInstance().remove(pee, true);
				pee.wasAdded = false;
			}

			if(destroy) {
				pee.destroy();
				PlayState.instance.modchartSprites.remove(tag);
			}
		});
		PythonScript.registerFunction("luaSpriteExists", function(tag:String) {
			return PlayState.instance.modchartSprites.exists(tag);
		});
		PythonScript.registerFunction("luaTextExists", function(tag:String) {
			return PlayState.instance.modchartTexts.exists(tag);
		});
		PythonScript.registerFunction("luaSoundExists", function(tag:String) {
			return PlayState.instance.modchartSounds.exists(tag);
		});
		PythonScript.registerFunction("setHealthBarColors", function(leftHex:String, rightHex:String) {
			var left:FlxColor = Std.parseInt(leftHex);
			if(!leftHex.startsWith('0x')) left = Std.parseInt('0xff' + leftHex);
			var right:FlxColor = Std.parseInt(rightHex);
			if(!rightHex.startsWith('0x')) right = Std.parseInt('0xff' + rightHex);

			PlayState.instance.healthBar.createFilledBar(left, right);
			PlayState.instance.healthBar.updateBar();
		});
		PythonScript.registerFunction("setTimeBarColors", function(leftHex:String, rightHex:String) {
			var left:FlxColor = Std.parseInt(leftHex);
			if(!leftHex.startsWith('0x')) left = Std.parseInt('0xff' + leftHex);
			var right:FlxColor = Std.parseInt(rightHex);
			if(!rightHex.startsWith('0x')) right = Std.parseInt('0xff' + rightHex);

			PlayState.instance.timeBar.createFilledBar(right, left);
			PlayState.instance.timeBar.updateBar();
		});
		PythonScript.registerFunction("setObjectCamera", function(obj:String, camera:String = '') {
			var real = game.getLuaObject(obj);
			if(real != null) {
				real.cameras = [LuaUtils.cameraFromString(camera)];
				return true;
			}

			var killMe:Array<String> = obj.split('.');
			var object:FlxSprite = FunkinLua.getObjectDirectly(killMe[0]);
			if(killMe.length > 1) {
				object = FunkinLua.getVarInArray(FunkinLua.getPropertyLoopThingWhatever(killMe), killMe[killMe.length-1]);
			}

			if(object != null) {
				object.cameras = [LuaUtils.cameraFromString(camera)];
				return true;
			}
			py.pyTrace("setObjectCamera | Object " + obj + " doesn't exist!", false, false, FlxColor.RED);
			return false;
		});
		PythonScript.registerFunction("setBlendMode", function(obj:String, blend:String = '') {
			var real = game.getLuaObject(obj);
			if(real != null) {
				real.blend = LuaUtils.blendModeFromString(blend);
				return true;
			}

			var killMe:Array<String> = obj.split('.');
			var spr:FlxSprite = FunkinLua.getObjectDirectly(killMe[0]);
			if(killMe.length > 1) {
				spr = FunkinLua.getVarInArray(FunkinLua.getPropertyLoopThingWhatever(killMe), killMe[killMe.length-1]);
			}

			if(spr != null) {
				spr.blend = LuaUtils.blendModeFromString(blend);
				return true;
			}
			py.pyTrace("setBlendMode | Object " + obj + " doesn't exist!", false, false, FlxColor.RED);
			return false;
		});
		PythonScript.registerFunction("screenCenter", function(obj:String, pos:String = 'xy') {
			var spr:FlxSprite = game.getLuaObject(obj);

			if(spr == null) {
				var killMe:Array<String> = obj.split('.');
				spr = FunkinLua.getObjectDirectly(killMe[0]);
				if(killMe.length > 1) {
					spr = FunkinLua.getVarInArray(FunkinLua.getPropertyLoopThingWhatever(killMe), killMe[killMe.length-1]);
				}
			}

			if(spr != null) {
				switch(pos.trim().toLowerCase()) {
					case 'x':
						spr.screenCenter(FlxAxes.X);
						return;
					case 'y':
						spr.screenCenter(FlxAxes.Y);
						return;
				}
				spr.screenCenter();
			}
		});
		PythonScript.registerFunction("getMidpointX", function(variable:String) {
			var killMe:Array<String> = variable.split('.');
			var obj:FlxSprite = FunkinLua.getObjectDirectly(killMe[0]);
			if(killMe.length > 1) {
				obj = FunkinLua.getVarInArray(FunkinLua.getPropertyLoopThingWhatever(killMe), killMe[killMe.length-1]);
			}
			if(obj != null) return obj.getMidpoint().x;
			return 0;
		});
		PythonScript.registerFunction("getMidpointY", function(variable:String) {
			var killMe:Array<String> = variable.split('.');
			var obj:FlxSprite = FunkinLua.getObjectDirectly(killMe[0]);
			if(killMe.length > 1) {
				obj = FunkinLua.getVarInArray(FunkinLua.getPropertyLoopThingWhatever(killMe), killMe[killMe.length-1]);
			}
			if(obj != null) return obj.getMidpoint().y;
			return 0;
		});
		PythonScript.registerFunction("getScreenPositionX", function(obj:String) {
			var killMe:Array<String> = obj.split('.');
			var spr:FlxSprite = FunkinLua.getObjectDirectly(killMe[0]);
			if(killMe.length > 1) {
				spr = FunkinLua.getVarInArray(FunkinLua.getPropertyLoopThingWhatever(killMe), killMe[killMe.length-1]);
			}
			if(spr != null) return spr.getScreenPosition().x;
			return 0;
		});
		PythonScript.registerFunction("getScreenPositionY", function(obj:String) {
			var killMe:Array<String> = obj.split('.');
			var spr:FlxSprite = FunkinLua.getObjectDirectly(killMe[0]);
			if(killMe.length > 1) {
				spr = FunkinLua.getVarInArray(FunkinLua.getPropertyLoopThingWhatever(killMe), killMe[killMe.length-1]);
			}
			if(spr != null) return spr.getScreenPosition().y;
			return 0;
		});
		}
	}
}
