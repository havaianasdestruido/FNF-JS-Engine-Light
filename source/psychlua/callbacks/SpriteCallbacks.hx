package psychlua.callbacks;

import backend.ClientPrefs;
import backend.Paths;
import objects.Character;
import play.PlayState;
import psychlua.FunkinLua;
import headers.PsychLua;
import psychlua.ModchartSprite;
import states.substates.GameOverSubstate;

// REFACTOR: extracted from psychlua.FunkinLua (sprite/animation API)
class SpriteCallbacks
{
	public static function register(funk:FunkinLua):Void {
		final game:PlayState = PlayState.instance;
		@:privateAccess {
		FunkinLua.registerFunction("getMidpointX", function(variable:String) {
			var killMe:Array<String> = variable.split('.');
			var obj:FlxSprite = FunkinLua.getObjectDirectly(killMe[0]);
			if(killMe.length > 1) {
				obj = FunkinLua.getVarInArray(FunkinLua.getPropertyLoopThingWhatever(killMe), killMe[killMe.length-1]);
			}
			if(obj != null) return obj.getMidpoint().x;

			return 0;
		});
		FunkinLua.registerFunction("getMidpointY", function(variable:String) {
			var killMe:Array<String> = variable.split('.');
			var obj:FlxSprite = FunkinLua.getObjectDirectly(killMe[0]);
			if(killMe.length > 1) {
				obj = FunkinLua.getVarInArray(FunkinLua.getPropertyLoopThingWhatever(killMe), killMe[killMe.length-1]);
			}
			if(obj != null) return obj.getMidpoint().y;

			return 0;
		});
		FunkinLua.registerFunction("getGraphicMidpointX", function(variable:String) {
			var killMe:Array<String> = variable.split('.');
			var obj:FlxSprite = FunkinLua.getObjectDirectly(killMe[0]);
			if(killMe.length > 1) {
				obj = FunkinLua.getVarInArray(FunkinLua.getPropertyLoopThingWhatever(killMe), killMe[killMe.length-1]);
			}
			if(obj != null) return obj.getGraphicMidpoint().x;

			return 0;
		});
		FunkinLua.registerFunction("getGraphicMidpointY", function(variable:String) {
			var killMe:Array<String> = variable.split('.');
			var obj:FlxSprite = FunkinLua.getObjectDirectly(killMe[0]);
			if(killMe.length > 1) {
				obj = FunkinLua.getVarInArray(FunkinLua.getPropertyLoopThingWhatever(killMe), killMe[killMe.length-1]);
			}
			if(obj != null) return obj.getGraphicMidpoint().y;

			return 0;
		});
		FunkinLua.registerFunction("getScreenPositionX", function(variable:String) {
			var killMe:Array<String> = variable.split('.');
			var obj:FlxSprite = FunkinLua.getObjectDirectly(killMe[0]);
			if(killMe.length > 1) {
				obj = FunkinLua.getVarInArray(FunkinLua.getPropertyLoopThingWhatever(killMe), killMe[killMe.length-1]);
			}
			if(obj != null) return obj.getScreenPosition().x;

			return 0;
		});
		FunkinLua.registerFunction("getScreenPositionY", function(variable:String) {
			var killMe:Array<String> = variable.split('.');
			var obj:FlxSprite = FunkinLua.getObjectDirectly(killMe[0]);
			if(killMe.length > 1) {
				obj = FunkinLua.getVarInArray(FunkinLua.getPropertyLoopThingWhatever(killMe), killMe[killMe.length-1]);
			}
			if(obj != null) return obj.getScreenPosition().y;

			return 0;
		});
		FunkinLua.registerFunction("makeLuaSprite", function(tag:String, image:String, x:Float, y:Float) {
			tag = tag.replace('.', '');
			funk.resetSpriteTag(tag);
			var leSprite:ModchartSprite = new ModchartSprite(x, y);
			if(image != null && image.length > 0)
			{
				leSprite.loadGraphic(Paths.image(image));
			}
			leSprite.antialiasing = ClientPrefs.globalAntialiasing;
			PlayState.instance.modchartSprites.set(tag, leSprite);
			leSprite.active = true;
		});
		FunkinLua.registerFunction("makeAnimatedLuaSprite", function(tag:String, image:String, x:Float, y:Float, ?spriteType:String = "sparrow") {
			tag = tag.replace('.', '');
			funk.resetSpriteTag(tag);
			var leSprite:ModchartSprite = new ModchartSprite(x, y);

			funk.loadFrames(leSprite, image, spriteType);
			leSprite.antialiasing = ClientPrefs.globalAntialiasing;
			PlayState.instance.modchartSprites.set(tag, leSprite);
		});

		FunkinLua.registerFunction("makeGraphic", function(obj:String, width:Int, height:Int, color:String) {
			var colorNum:Int = Std.parseInt(color);
			if(!color.startsWith('0x')) colorNum = Std.parseInt('0xff' + color);

			var spr:FlxSprite = PlayState.instance.getLuaObject(obj,false);
			if(spr!=null) {
				PlayState.instance.getLuaObject(obj,false).makeGraphic(width, height, colorNum);
				return;
			}

			var object:FlxSprite = Reflect.getProperty(FunkinLua.getInstance(), obj);
			if(object != null) {
				object.makeGraphic(width, height, colorNum);
			}
		});
		FunkinLua.registerFunction("addAnimationByPrefix", function(obj:String, name:String, prefix:String, framerate:Int = 24, loop:Bool = true) {
			if(PlayState.instance.getLuaObject(obj,false)!=null) {
				var cock:FlxSprite = PlayState.instance.getLuaObject(obj,false);
				cock.animation.addByPrefix(name, prefix, framerate, loop);
				if(cock.animation.curAnim == null) {
					cock.animation.play(name, true);
				}
				return;
			}

			var cock:FlxSprite = Reflect.getProperty(FunkinLua.getInstance(), obj);
			if(cock != null) {
				cock.animation.addByPrefix(name, prefix, framerate, loop);
				if(cock.animation.curAnim == null) {
					cock.animation.play(name, true);
				}
			}
		});

		FunkinLua.registerFunction("addAnimation", function(obj:String, name:String, frames:Array<Int>, framerate:Int = 24, loop:Bool = true) {
			if(PlayState.instance.getLuaObject(obj,false)!=null) {
				var cock:FlxSprite = PlayState.instance.getLuaObject(obj,false);
				cock.animation.add(name, frames, framerate, loop);
				if(cock.animation.curAnim == null) {
					cock.animation.play(name, true);
				}
				return;
			}

			var cock:FlxSprite = Reflect.getProperty(FunkinLua.getInstance(), obj);
			if(cock != null) {
				cock.animation.add(name, frames, framerate, loop);
				if(cock.animation.curAnim == null) {
					cock.animation.play(name, true);
				}
			}
		});

		FunkinLua.registerFunction("addAnimationByIndices", function(obj:String, name:String, prefix:String, indices:String, framerate:Int = 24) {
			return FunkinLua.addAnimByIndices(obj, name, prefix, indices, framerate, false);
		});
		FunkinLua.registerFunction("addAnimationByIndicesLoop", function(obj:String, name:String, prefix:String, indices:String, framerate:Int = 24) {
			return FunkinLua.addAnimByIndices(obj, name, prefix, indices, framerate, true);
		});

		FunkinLua.registerFunction("playAnim", function(obj:String, name:String, forced:Bool = false, ?reverse:Bool = false, ?startFrame:Int = 0)
		{
			if(PlayState.instance.getLuaObject(obj, false) != null) {
				var luaObj:FlxSprite = PlayState.instance.getLuaObject(obj,false);
				if(luaObj.animation.getByName(name) != null)
				{
					luaObj.animation.play(name, forced, reverse, startFrame);
					if(Std.isOfType(luaObj, ModchartSprite))
					{
						//convert luaObj to ModchartSprite
						var obj:Dynamic = luaObj;
						var luaObj:ModchartSprite = obj;

						var daOffset = luaObj.animOffsets.get(name);
						if (luaObj.animOffsets.exists(name))
						{
							luaObj.offset.set(daOffset[0], daOffset[1]);
						}
					}
				}
				return true;
			}

			var spr:FlxSprite = Reflect.getProperty(FunkinLua.getInstance(), obj);
			if(spr != null) {
				if(spr.animation.getByName(name) != null)
				{
					if(Std.isOfType(spr, Character))
					{
						//convert spr to Character
						var obj:Dynamic = spr;
						var spr:Character = obj;
						spr.playAnim(name, forced, reverse, startFrame);
					}
					else
						spr.animation.play(name, forced, reverse, startFrame);
				}
				return true;
			}
			return false;
		});
		FunkinLua.registerFunction("addOffset", function(obj:String, anim:String, x:Float, y:Float) {
			if(PlayState.instance.modchartSprites.exists(obj)) {
				PlayState.instance.modchartSprites.get(obj).animOffsets.set(anim, [x, y]);
				return true;
			}

			var char:Character = Reflect.getProperty(FunkinLua.getInstance(), obj);
			if(char != null) {
				char.addOffset(anim, x, y);
				return true;
			}
			return false;
		});

		FunkinLua.registerFunction("setScrollFactor", function(obj:String, scrollX:Float, scrollY:Float) {
			if(PlayState.instance.getLuaObject(obj,false)!=null) {
				PlayState.instance.getLuaObject(obj,false).scrollFactor.set(scrollX, scrollY);
				return;
			}

			var object:FlxObject = Reflect.getProperty(FunkinLua.getInstance(), obj);
			if(object != null) {
				object.scrollFactor.set(scrollX, scrollY);
			}
		});
		FunkinLua.registerFunction("addLuaSprite", function(tag:String, front:Bool = false) {
			if(PlayState.instance.modchartSprites.exists(tag)) {
				var shit:ModchartSprite = PlayState.instance.modchartSprites.get(tag);
				if(!shit.wasAdded) {
					if(front)
					{
						FunkinLua.getInstance().add(shit);
					}
					else
					{
						if(PlayState.instance.isDead)
						{
							GameOverSubstate.instance.insert(GameOverSubstate.instance.members.indexOf(GameOverSubstate.instance.boyfriend), shit);
						}
						else
						{
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
					//trace('added a thing: ' + tag);
				}
			}
		});
		FunkinLua.registerFunction("setGraphicSize", function(obj:String, x:Int, y:Int = 0, updateHitbox:Bool = true) {
			if(PlayState.instance.getLuaObject(obj)!=null) {
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
			LuaUtils.luaTrace(funk.lua, 'setGraphicSize | Couldnt find object: ' + obj, false, false, FlxColor.RED);
		});
		FunkinLua.registerFunction("scaleObject", function(obj:String, x:Float, y:Float, updateHitbox:Bool = true) {
			if(PlayState.instance.getLuaObject(obj)!=null) {
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
			LuaUtils.luaTrace(funk.lua, 'scaleObject | Couldnt find object: ' + obj, false, false, FlxColor.RED);
		});
		FunkinLua.registerFunction("updateHitbox", function(obj:String) {
			if(PlayState.instance.getLuaObject(obj)!=null) {
				var shit:FlxSprite = PlayState.instance.getLuaObject(obj);
				shit.updateHitbox();
				return;
			}

			var poop:FlxSprite = Reflect.getProperty(FunkinLua.getInstance(), obj);
			if(poop != null) {
				poop.updateHitbox();
				return;
			}
			LuaUtils.luaTrace(funk.lua, 'updateHitbox | Couldnt find object: ' + obj, false, false, FlxColor.RED);
		});
		FunkinLua.registerFunction("updateHitboxFromGroup", function(group:String, index:Int) {
			if(Std.isOfType(Reflect.getProperty(FunkinLua.getInstance(), group), FlxTypedGroup)) {
				Reflect.getProperty(FunkinLua.getInstance(), group).members[index].updateHitbox();
				return;
			}
			Reflect.getProperty(FunkinLua.getInstance(), group)[index].updateHitbox();
		});

		FunkinLua.registerFunction("removeLuaSprite", function(tag:String, destroy:Bool = true) {
			if(!PlayState.instance.modchartSprites.exists(tag)) {
				return;
			}

			var pee:ModchartSprite = PlayState.instance.modchartSprites.get(tag);
			if(destroy) {
				pee.kill();
			}

			if(pee.wasAdded) {
				FunkinLua.getInstance().remove(pee, true);
				pee.wasAdded = false;
			}

			if(destroy) {
				pee.destroy();
				PlayState.instance.modchartSprites.remove(tag);
			}
		});

		FunkinLua.registerFunction("luaSpriteExists", function(tag:String) {
			return PlayState.instance.modchartSprites.exists(tag);
		});
		FunkinLua.registerFunction("luaTextExists", function(tag:String) {
			return PlayState.instance.modchartTexts.exists(tag);
		});
		FunkinLua.registerFunction("luaSoundExists", function(tag:String) {
			return PlayState.instance.modchartSounds.exists(tag);
		});

		FunkinLua.registerFunction("setHealthBarColors", function(leftHex:String, rightHex:String) {
			var left:FlxColor = Std.parseInt(leftHex);
			if(!leftHex.startsWith('0x')) left = Std.parseInt('0xff' + leftHex);
			var right:FlxColor = Std.parseInt(rightHex);
			if(!rightHex.startsWith('0x')) right = Std.parseInt('0xff' + rightHex);

			PlayState.instance.healthBar.createFilledBar(left, right);
			PlayState.instance.healthBar.updateBar();
		});
		FunkinLua.registerFunction("setTimeBarColors", function(leftHex:String, rightHex:String) {
			var left:FlxColor = Std.parseInt(leftHex);
			if(!leftHex.startsWith('0x')) left = Std.parseInt('0xff' + leftHex);
			var right:FlxColor = Std.parseInt(rightHex);
			if(!rightHex.startsWith('0x')) right = Std.parseInt('0xff' + rightHex);

			PlayState.instance.timeBar.createFilledBar(right, left);
			PlayState.instance.timeBar.updateBar();
		});

		FunkinLua.registerFunction("setObjectCamera", function(obj:String, camera:String = '') {
			var real = game.getLuaObject(obj);
			if(real!=null){
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
			LuaUtils.luaTrace(funk.lua, "setObjectCamera | Object " + obj + " doesn't exist!", false, false, FlxColor.RED);
			return false;
		});
		FunkinLua.registerFunction("setBlendMode", function(obj:String, blend:String = '') {
			var real = game.getLuaObject(obj);
			if(real!=null) {
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
			LuaUtils.luaTrace(funk.lua, "setBlendMode | Object " + obj + " doesn't exist!", false, false, FlxColor.RED);
			return false;
		});
		FunkinLua.registerFunction("screenCenter", function(obj:String, pos:String = 'xy') {
			var spr:FlxSprite = game.getLuaObject(obj);

			if(spr==null){
				var killMe:Array<String> = obj.split('.');
				spr = FunkinLua.getObjectDirectly(killMe[0]);
				if(killMe.length > 1) {
					spr = FunkinLua.getVarInArray(FunkinLua.getPropertyLoopThingWhatever(killMe), killMe[killMe.length-1]);
				}
			}

			if(spr != null)
			{
				switch(pos.trim().toLowerCase())
				{
					case 'x':
						spr.screenCenter(X);
						return;
					case 'y':
						spr.screenCenter(Y);
						return;
					default:
						spr.screenCenter(XY);
						return;
				}
			}
			LuaUtils.luaTrace(funk.lua, "screenCenter | Object " + obj + " doesn't exist!", false, false, FlxColor.RED);
		});
		FunkinLua.registerFunction("objectsOverlap", function(obj1:String, obj2:String) {
			var namesArray:Array<String> = [obj1, obj2];
			var objectsArray:Array<FlxSprite> = [];
			for (i in 0...namesArray.length)
			{
				var real = PlayState.instance.getLuaObject(namesArray[i]);
				if(real!=null) {
					objectsArray.push(real);
				} else {
					objectsArray.push(Reflect.getProperty(FunkinLua.getInstance(), namesArray[i]));
				}
			}

			if(!objectsArray.contains(null) && FlxG.overlap(objectsArray[0], objectsArray[1]))
			{
				return true;
			}
			return false;
		});
		FunkinLua.registerFunction("getPixelColor", function(obj:String, x:Int, y:Int) {
			var killMe:Array<String> = obj.split('.');
			var spr:FlxSprite = FunkinLua.getObjectDirectly(killMe[0]);
			if(killMe.length > 1) {
				spr = FunkinLua.getVarInArray(FunkinLua.getPropertyLoopThingWhatever(killMe), killMe[killMe.length-1]);
			}

			if(spr != null)
			{
				if(spr.framePixels != null) spr.framePixels.getPixel32(x, y);
				return spr.pixels.getPixel32(x, y);
			}
			return 0;
		});
		}
	}
}
