package psychlua;

import flixel.FlxBasic;
import flixel.FlxCamera;
import flixel.FlxG;
import flixel.FlxObject;
import flixel.FlxSprite;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.math.FlxMath;
import flixel.sound.FlxSound;
import flixel.text.FlxText;
import flixel.tweens.FlxTween;
import flixel.util.FlxAxes;
import flixel.util.FlxColor;
import flixel.util.FlxTimer;

import openfl.display.BlendMode;

import paopao.hython.Expr.Error;
import paopao.hython.Interp;
import paopao.hython.Parser;

import Paths;
import Type.ValueType;

#if DISCORD_ALLOWED
import DiscordClient;
#end

#if sys
import sys.FileSystem;
import sys.io.File;
#end

using StringTools;

/**
 * A Python script running inside the engine, powered by the pure-Haxe
 * Hython interpreter (haxelib `hython`). Mirrors `FunkinLua`'s API so Python
 * mods behave exactly like Lua mods: define top-level `def` callbacks
 * (onCreate, onUpdate, goodNoteHit, ...), call the same engine functions and
 * return the same sentinels (`Function_Stop`, `Function_Continue`,
 * `Function_StopAll`).
 */
#if PYTHON_ALLOWED
class PythonScript
{
	// Sentinel strings are intentionally the SAME values as FunkinLua's so the
	// existing `ret != FunkinLua.Function_Stop` checks keep working for Python.
	public static var Function_Stop:Dynamic = "##PSYCHLUA_FUNCTIONSTOP";
	public static var Function_Continue:Dynamic = "##PSYCHLUA_FUNCTIONCONTINUE";
	public static var Function_StopAll:Dynamic = "##PSYCHLUA_FUNCTIONSTOPLUA";

	public var scriptName:String = '';
	public var closed:Bool = false;
	public var lastCalledFunction:String = '';
	public static var lastCalledScript:PythonScript = null;

	public static var customFunctions:Map<String, Dynamic> = [];
	public static var registeredFunctions:Map<String, Dynamic> = [];

	var interp:Interp;
	var parser:Parser;
	var _missingCalls:Map<String, Bool> = new Map();

	public function new(scriptName:String, ?scriptCode:String)
	{
		this.scriptName = scriptName;
		final game:PlayState = PlayState.instance;
		game.pythonArray.push(this);

		interp = new Interp();
		parser = new Parser();

		var code:String = scriptCode;
		if (code == null)
		{
			#if sys
			if (FileSystem.exists(scriptName))
				code = File.getContent(scriptName);
			else
			#end
				code = Paths.getTextFromFile(scriptName);
		}
		// hython's lexer miscounts indentation on CRLF files, normalize to LF
		code = code.split("\r\n").join("\n");

		try
		{
			interp.execute(parser.parseString(code));
		}
		catch (e:Error)
		{
			pyTrace('Error loading python script: "$scriptName"\n' + getErrorString(e), true, false, FlxColor.RED);
			closed = true;
			return;
		}
		catch (e:Dynamic)
		{
			pyTrace('Error loading python script: "$scriptName"\n' + Std.string(e), true, false, FlxColor.RED);
			closed = true;
			return;
		}

		pyTrace('python file loaded succesfully: ' + scriptName, true);

		// Python globals
		set('Function_StopAll', Function_StopAll);
		set('Function_Stop', Function_Stop);
		set('Function_Continue', Function_Continue);
		set('pythonDebugMode', false);
		set('pythonDeprecatedWarnings', true);

		// Bind every registered/custom function into the interpreter, then let
		// other systems add their own callbacks (CustomSubstate, Achievements...).
		registerCustomFunctions();
		CustomSubstate.implementPython(this);
		#if ACHIEVEMENTS_ALLOWED Achievements.addPythonCallbacks(this); #end
		#if flxanimate FlxAnimateFunctions.implementPython(this); #end

		// --------------------------------------------------------------------
		// API registry (mirrors FunkinLua's constructor).
		// --------------------------------------------------------------------

		registerFunction("getProperty", function(variable:String) {
			var result:Dynamic = null;
			var killMe:Array<String> = variable.split('.');
			if(killMe.length > 1)
				result = FunkinLua.getVarInArray(FunkinLua.getPropertyLoopThingWhatever(killMe), killMe[killMe.length-1]);
			else
				result = FunkinLua.getVarInArray(getInstance(), variable);
			return result;
		});
		registerFunction("setProperty", function(variable:String, value:Dynamic) {
			var killMe:Array<String> = variable.split('.');
			if(killMe.length > 1) {
				FunkinLua.setVarInArray(FunkinLua.getPropertyLoopThingWhatever(killMe), killMe[killMe.length-1], value);
				return true;
			}
			FunkinLua.setVarInArray(getInstance(), variable, value);
			return true;
		});
		registerFunction("getPropertyFromGroup", function(obj:String, index:Int, variable:Dynamic) {
			var shitMyPants:Array<String> = obj.split('.');
			var realObject:Dynamic = Reflect.getProperty(getInstance(), obj);
			if(shitMyPants.length>1)
				realObject = FunkinLua.getPropertyLoopThingWhatever(shitMyPants, true, false);

			if(Std.isOfType(realObject, FlxTypedGroup)) {
				var result:Dynamic = getGroupStuff(realObject.members[index], variable);
				return result;
			}

			var leArray:Dynamic = realObject[index];
			if(leArray != null) {
				var result:Dynamic = null;
				if(Type.typeof(variable) == ValueType.TInt)
					result = leArray[variable];
				else
					result = getGroupStuff(leArray, variable);
				return result;
			}
			pyTrace("getPropertyFromGroup | Object #" + index + " from group: " + obj + " doesn't exist!", false, false, FlxColor.RED);
			return null;
		});
		registerFunction("setPropertyFromGroup", function(obj:String, index:Int, variable:Dynamic, value:Dynamic) {
			var shitMyPants:Array<String> = obj.split('.');
			var realObject:Dynamic = Reflect.getProperty(getInstance(), obj);
			if(shitMyPants.length>1)
				realObject = FunkinLua.getPropertyLoopThingWhatever(shitMyPants, true, false);

			if(Std.isOfType(realObject, FlxTypedGroup)) {
				setGroupStuff(realObject.members[index], variable, value);
				return;
			}

			var leArray:Dynamic = realObject[index];
			if(leArray != null) {
				if(Type.typeof(variable) == ValueType.TInt) {
					leArray[variable] = value;
					return;
				}
				setGroupStuff(leArray, variable, value);
			}
		});
		registerFunction("removeFromGroup", function(obj:String, index:Int, dontDestroy:Bool = false) {
			if(Std.isOfType(Reflect.getProperty(getInstance(), obj), FlxTypedGroup)) {
				var sex = Reflect.getProperty(getInstance(), obj).members[index];
				if(!dontDestroy)
					sex.kill();
				Reflect.getProperty(getInstance(), obj).remove(sex, true);
				if(!dontDestroy)
					sex.destroy();
				return;
			}
			Reflect.getProperty(getInstance(), obj).remove(Reflect.getProperty(getInstance(), obj)[index]);
		});
		registerFunction("getPropertyFromClass", function(classVar:String, variable:String) {
			@:privateAccess
			var killMe:Array<String> = variable.split('.');
			if(killMe.length > 1) {
				var coverMeInPiss:Dynamic = FunkinLua.getVarInArray(Type.resolveClass(classVar), killMe[0]);
				for (i in 1...killMe.length-1) {
					coverMeInPiss = FunkinLua.getVarInArray(coverMeInPiss, killMe[i]);
				}
				return FunkinLua.getVarInArray(coverMeInPiss, killMe[killMe.length-1]);
			}
			return FunkinLua.getVarInArray(Type.resolveClass(classVar), variable);
		});
		registerFunction("setPropertyFromClass", function(classVar:String, variable:String, value:Dynamic) {
			@:privateAccess
			var killMe:Array<String> = variable.split('.');
			if(killMe.length > 1) {
				var coverMeInPiss:Dynamic = FunkinLua.getVarInArray(Type.resolveClass(classVar), killMe[0]);
				for (i in 1...killMe.length-1) {
					coverMeInPiss = FunkinLua.getVarInArray(coverMeInPiss, killMe[i]);
				}
				FunkinLua.setVarInArray(coverMeInPiss, killMe[killMe.length-1], value);
				return true;
			}
			FunkinLua.setVarInArray(Type.resolveClass(classVar), variable, value);
			return true;
		});
		registerFunction("getObjectOrder", function(obj:String) {
			var killMe:Array<String> = obj.split('.');
			var leObj:FlxBasic = FunkinLua.getObjectDirectly(killMe[0]);
			if(killMe.length > 1) {
				leObj = FunkinLua.getVarInArray(FunkinLua.getPropertyLoopThingWhatever(killMe), killMe[killMe.length-1]);
			}

			if(leObj != null) {
				return getInstance().members.indexOf(leObj);
			}
			pyTrace("getObjectOrder | Object " + obj + " doesn't exist!", false, false, FlxColor.RED);
			return -1;
		});
		registerFunction("setObjectOrder", function(obj:String, position:Int) {
			var killMe:Array<String> = obj.split('.');
			var leObj:FlxBasic = FunkinLua.getObjectDirectly(killMe[0]);
			if(killMe.length > 1) {
				leObj = FunkinLua.getVarInArray(FunkinLua.getPropertyLoopThingWhatever(killMe), killMe[killMe.length-1]);
			}

			if(leObj != null) {
				getInstance().remove(leObj, true);
				getInstance().insert(position, leObj);
				return;
			}
			pyTrace("setObjectOrder | Object " + obj + " doesn't exist!", false, false, FlxColor.RED);
		});

		// ---------------------------------------------------------------- //
		//                        SCORE / HEALTH                            //
		// ---------------------------------------------------------------- //
		registerFunction("addScore", function(value:Float = 0) {
			PlayState.instance.songScore += value;
			PlayState.instance.RecalculateRating();
		});
		registerFunction("addMisses", function(value:Int = 0) {
			PlayState.instance.songMisses += value;
			PlayState.instance.RecalculateRating();
		});
		registerFunction("addHits", function(value:Int = 0) {
			PlayState.instance.songHits += value;
			PlayState.instance.RecalculateRating();
		});
		registerFunction("addCombo", function(value:Int = 0) {
			PlayState.instance.combo += value;
			PlayState.instance.RecalculateRating();
		});
		registerFunction("addNPS", function(value:Int = 0) {
			PlayState.instance.nps += value;
		});
		registerFunction("setScore", function(value:Float = 0) {
			PlayState.instance.songScore = value;
			PlayState.instance.RecalculateRating();
		});
		registerFunction("setMisses", function(value:Int = 0) {
			PlayState.instance.songMisses = value;
			PlayState.instance.RecalculateRating();
		});
		registerFunction("setHits", function(value:Int = 0) {
			PlayState.instance.songHits = value;
			PlayState.instance.RecalculateRating();
		});
		registerFunction("getScore", function() {
			return PlayState.instance.songScore;
		});
		registerFunction("getMisses", function() {
			return PlayState.instance.songMisses;
		});
		registerFunction("getHits", function() {
			return PlayState.instance.songHits;
		});
		registerFunction("setHealth", function(value:Float = 0) {
			PlayState.instance.health = value;
		});
		registerFunction("addHealth", function(value:Float = 0) {
			PlayState.instance.health += value;
		});
		registerFunction("addPlaybackSpeed", function(value:Float = 0) {
			PlayState.instance.playbackRate += value;
		});
		registerFunction("getHealth", function() {
			return PlayState.instance.health;
		});
		registerFunction("getPlaybackSpeed", function() {
			return PlayState.instance.playbackRate;
		});
		registerFunction("setPlaybackSpeed", function(value:Float = 0) {
			PlayState.instance.playbackRate = value;
		});
		registerFunction("changeMaxHealth", function(value:Float = 0) {
			var bar = PlayState.instance.healthBar;
			PlayState.instance.maxHealth = value;
			bar.setRange(0, value);
		});
		registerFunction("getMaxHealth", function() {
			return PlayState.instance.maxHealth;
		});
		registerFunction("getColorFromHex", function(color:String) {
			if(!color.startsWith('0x')) color = '0xff' + color;
			return Std.parseInt(color);
		});

		// ---------------------------------------------------------------- //
		//                        CHARACTERS                                //
		// ---------------------------------------------------------------- //
		registerFunction("getCharacterX", function(type:String) {
			switch(type.toLowerCase()) {
				case 'dad' | 'opponent':
					return PlayState.instance.dadGroup.x;
				case 'gf' | 'girlfriend':
					return PlayState.instance.gfGroup.x;
				default:
					return PlayState.instance.boyfriendGroup.x;
			}
		});
		registerFunction("setCharacterX", function(type:String, value:Float) {
			switch(type.toLowerCase()) {
				case 'dad' | 'opponent':
					PlayState.instance.dadGroup.x = value;
				case 'gf' | 'girlfriend':
					PlayState.instance.gfGroup.x = value;
				default:
					PlayState.instance.boyfriendGroup.x = value;
			}
		});
		registerFunction("getCharacterY", function(type:String) {
			switch(type.toLowerCase()) {
				case 'dad' | 'opponent':
					return PlayState.instance.dadGroup.y;
				case 'gf' | 'girlfriend':
					return PlayState.instance.gfGroup.y;
				default:
					return PlayState.instance.boyfriendGroup.y;
			}
		});
		registerFunction("setCharacterY", function(type:String, value:Float) {
			switch(type.toLowerCase()) {
				case 'dad' | 'opponent':
					PlayState.instance.dadGroup.y = value;
				case 'gf' | 'girlfriend':
					PlayState.instance.gfGroup.y = value;
				default:
					PlayState.instance.boyfriendGroup.y = value;
			}
		});
		registerFunction("dance", function(character:String = 'bf') {
			switch(character.toLowerCase()) {
				case 'dad': PlayState.instance.dad.dance();
				case 'gf' | 'girlfriend': if(PlayState.instance.gf != null) PlayState.instance.gf.dance();
				default: PlayState.instance.boyfriend.dance();
			}
		});
		registerFunction("addCharacterToList", function(name:String, type:String) {
			var charType:Int = 0;
			switch(type.toLowerCase()) {
				case 'dad': charType = 1;
				case 'gf' | 'girlfriend': charType = 2;
			}
			PlayState.instance.addCharacterToList(name, charType);
		});
		registerFunction("setRatingPercent", function(value:Float) {
			PlayState.instance.ratingPercent = value;
		});
		registerFunction("setRatingName", function(value:String) {
			PlayState.instance.ratingName = value;
		});
		registerFunction("setRatingFC", function(value:String) {
			PlayState.instance.ratingFC = value;
		});

		// ---------------------------------------------------------------- //
		//                           CAMERA                                 //
		// ---------------------------------------------------------------- //
		registerFunction("cameraSetTarget", function(target:String) {
			switch(target.trim().toLowerCase()) {
				case 'gf' | 'girlfriend':
					game.moveCamera('gf');
				case 'dad' | 'opponent':
					game.moveCamera('dad');
				default:
					game.moveCamera('bf');
			}
		});
		registerFunction("cameraShake", function(camera:String, intensity:Float, duration:Float) {
			LuaUtils.cameraFromString(camera).shake(intensity, duration / PlayState.instance.playbackRate);
		});
		registerFunction("cameraFlash", function(camera:String, color:String, duration:Float, forced:Bool) {
			var colorNum:Int = Std.parseInt(color);
			if(!color.startsWith('0x')) colorNum = Std.parseInt('0xff' + color);
			LuaUtils.cameraFromString(camera).flash(colorNum, duration / PlayState.instance.playbackRate, null, forced);
		});
		registerFunction("cameraFade", function(camera:String, color:String, duration:Float, forced:Bool, ?fadeOut:Bool = false) {
			var colorNum:Int = Std.parseInt(color);
			if(!color.startsWith('0x')) colorNum = Std.parseInt('0xff' + color);
			LuaUtils.cameraFromString(camera).fade(colorNum, duration / PlayState.instance.playbackRate, fadeOut, null, forced);
		});
		registerFunction("getMouseX", function(camera:String) {
			var cam:FlxCamera = LuaUtils.cameraFromString(camera);
			return FlxG.mouse.getScreenPosition(cam).x;
		});
		registerFunction("getMouseY", function(camera:String) {
			var cam:FlxCamera = LuaUtils.cameraFromString(camera);
			return FlxG.mouse.getScreenPosition(cam).y;
		});
		registerFunction("mouseClicked", function(button:String) {
			var boobs = FlxG.mouse.justPressed;
			switch(button) {
				case 'middle': boobs = FlxG.mouse.justPressedMiddle;
				case 'right': boobs = FlxG.mouse.justPressedRight;
			}
			return boobs;
		});
		registerFunction("mousePressed", function(button:String) {
			var boobs = FlxG.mouse.pressed;
			switch(button) {
				case 'middle': boobs = FlxG.mouse.pressedMiddle;
				case 'right': boobs = FlxG.mouse.pressedRight;
			}
			return boobs;
		});
		registerFunction("mouseReleased", function(button:String) {
			var boobs = FlxG.mouse.justReleased;
			switch(button) {
				case 'middle': boobs = FlxG.mouse.justReleasedMiddle;
				case 'right': boobs = FlxG.mouse.justReleasedRight;
			}
			return boobs;
		});
		registerFunction("keyJustPressed", function(name:String) {
			var key:Bool = false;
			switch(name) {
				case 'left': key = PlayState.instance.getControl('NOTE_LEFT');
				case 'down': key = PlayState.instance.getControl('NOTE_DOWN');
				case 'up': key = PlayState.instance.getControl('NOTE_UP');
				case 'right': key = PlayState.instance.getControl('NOTE_RIGHT');
				case 'reset': key = PlayState.instance.getControl('RESET');
				case 'space': key = FlxG.keys.justPressed.SPACE;
			}
			return key;
		});
		registerFunction("keyPressed", function(name:String) {
			var key:Bool = false;
			switch(name) {
				case 'left': key = PlayState.instance.getControl('NOTE_LEFT');
				case 'down': key = PlayState.instance.getControl('NOTE_DOWN');
				case 'up': key = PlayState.instance.getControl('NOTE_UP');
				case 'right': key = PlayState.instance.getControl('NOTE_RIGHT');
				case 'space': key = FlxG.keys.pressed.SPACE;
			}
			return key;
		});
		registerFunction("keyReleased", function(name:String) {
			var key:Bool = false;
			switch(name) {
				case 'left': key = PlayState.instance.getControl('NOTE_LEFT_R');
				case 'down': key = PlayState.instance.getControl('NOTE_DOWN_R');
				case 'up': key = PlayState.instance.getControl('NOTE_UP_R');
				case 'right': key = PlayState.instance.getControl('NOTE_RIGHT_R');
				case 'space': key = FlxG.keys.justReleased.SPACE;
			}
			return key;
		});

		// ---------------------------------------------------------------- //
		//                           SPRITES                                //
		// ---------------------------------------------------------------- //
		registerFunction("makeLuaSprite", function(tag:String, image:String, x:Float, y:Float) {
			tag = tag.replace('.', '');
			resetSpriteTag(tag);
			var leSprite:ModchartSprite = new ModchartSprite(x, y);
			if(image != null && image.length > 0) {
				leSprite.loadGraphic(Paths.image(image));
			}
			leSprite.antialiasing = ClientPrefs.globalAntialiasing;
			PlayState.instance.modchartSprites.set(tag, leSprite);
			leSprite.active = true;
		});
		registerFunction("makeAnimatedLuaSprite", function(tag:String, image:String, x:Float, y:Float, ?spriteType:String = "sparrow") {
			tag = tag.replace('.', '');
			resetSpriteTag(tag);
			var leSprite:ModchartSprite = new ModchartSprite(x, y);
			loadFrames(leSprite, image, spriteType);
			leSprite.antialiasing = ClientPrefs.globalAntialiasing;
			PlayState.instance.modchartSprites.set(tag, leSprite);
		});
		registerFunction("makeGraphic", function(obj:String, width:Int, height:Int, color:String) {
			var colorNum:Int = Std.parseInt(color);
			if(!color.startsWith('0x')) colorNum = Std.parseInt('0xff' + color);

			var spr:FlxSprite = PlayState.instance.getLuaObject(obj, false);
			if(spr != null) {
				PlayState.instance.getLuaObject(obj, false).makeGraphic(width, height, colorNum);
				return;
			}

			var object:FlxSprite = Reflect.getProperty(getInstance(), obj);
			if(object != null) {
				object.makeGraphic(width, height, colorNum);
			}
		});
		registerFunction("addAnimationByPrefix", function(obj:String, name:String, prefix:String, framerate:Int = 24, loop:Bool = true) {
			if(PlayState.instance.getLuaObject(obj, false) != null) {
				var cock:FlxSprite = PlayState.instance.getLuaObject(obj, false);
				cock.animation.addByPrefix(name, prefix, framerate, loop);
				if(cock.animation.curAnim == null) {
					cock.animation.play(name, true);
				}
				return;
			}

			var cock:FlxSprite = Reflect.getProperty(getInstance(), obj);
			if(cock != null) {
				cock.animation.addByPrefix(name, prefix, framerate, loop);
				if(cock.animation.curAnim == null) {
					cock.animation.play(name, true);
				}
			}
		});
		registerFunction("addAnimation", function(obj:String, name:String, frames:Array<Int>, framerate:Int = 24, loop:Bool = true) {
			if(PlayState.instance.getLuaObject(obj, false) != null) {
				var cock:FlxSprite = PlayState.instance.getLuaObject(obj, false);
				cock.animation.add(name, frames, framerate, loop);
				if(cock.animation.curAnim == null) {
					cock.animation.play(name, true);
				}
				return;
			}

			var cock:FlxSprite = Reflect.getProperty(getInstance(), obj);
			if(cock != null) {
				cock.animation.add(name, frames, framerate, loop);
				if(cock.animation.curAnim == null) {
					cock.animation.play(name, true);
				}
			}
		});
		registerFunction("addAnimationByIndices", function(obj:String, name:String, prefix:String, indices:String, framerate:Int = 24) {
			return addAnimByIndices(obj, name, prefix, indices, framerate, false);
		});
		registerFunction("addAnimationByIndicesLoop", function(obj:String, name:String, prefix:String, indices:String, framerate:Int = 24) {
			return addAnimByIndices(obj, name, prefix, indices, framerate, true);
		});
		registerFunction("playAnim", function(obj:String, name:String, forced:Bool = false, ?reverse:Bool = false, ?startFrame:Int = 0) {
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

			var spr:FlxSprite = Reflect.getProperty(getInstance(), obj);
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
		registerFunction("addOffset", function(obj:String, anim:String, x:Float, y:Float) {
			if(PlayState.instance.modchartSprites.exists(obj)) {
				PlayState.instance.modchartSprites.get(obj).animOffsets.set(anim, [x, y]);
				return true;
			}

			var char:Character = Reflect.getProperty(getInstance(), obj);
			if(char != null) {
				char.addOffset(anim, x, y);
				return true;
			}
			return false;
		});
		registerFunction("setScrollFactor", function(obj:String, scrollX:Float, scrollY:Float) {
			if(PlayState.instance.getLuaObject(obj, false) != null) {
				PlayState.instance.getLuaObject(obj, false).scrollFactor.set(scrollX, scrollY);
				return;
			}

			var object:FlxObject = Reflect.getProperty(getInstance(), obj);
			if(object != null) {
				object.scrollFactor.set(scrollX, scrollY);
			}
		});
		registerFunction("addLuaSprite", function(tag:String, front:Bool = false) {
			if(PlayState.instance.modchartSprites.exists(tag)) {
				var shit:ModchartSprite = PlayState.instance.modchartSprites.get(tag);
				if(!shit.wasAdded) {
					if(front) {
						getInstance().add(shit);
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
		registerFunction("setGraphicSize", function(obj:String, x:Int, y:Int = 0, updateHitbox:Bool = true) {
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
			pyTrace('setGraphicSize | Couldnt find object: ' + obj, false, false, FlxColor.RED);
		});
		registerFunction("scaleObject", function(obj:String, x:Float, y:Float, updateHitbox:Bool = true) {
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
			pyTrace('scaleObject | Couldnt find object: ' + obj, false, false, FlxColor.RED);
		});
		registerFunction("updateHitbox", function(obj:String) {
			if(PlayState.instance.getLuaObject(obj) != null) {
				var shit:FlxSprite = PlayState.instance.getLuaObject(obj);
				shit.updateHitbox();
				return;
			}

			var poop:FlxSprite = Reflect.getProperty(getInstance(), obj);
			if(poop != null) {
				poop.updateHitbox();
				return;
			}
			pyTrace('updateHitbox | Couldnt find object: ' + obj, false, false, FlxColor.RED);
		});
		registerFunction("updateHitboxFromGroup", function(group:String, index:Int) {
			if(Std.isOfType(Reflect.getProperty(getInstance(), group), FlxTypedGroup)) {
				Reflect.getProperty(getInstance(), group).members[index].updateHitbox();
				return;
			}
			Reflect.getProperty(getInstance(), group)[index].updateHitbox();
		});
		registerFunction("removeLuaSprite", function(tag:String, destroy:Bool = true) {
			if(!PlayState.instance.modchartSprites.exists(tag)) {
				return;
			}

			var pee:ModchartSprite = PlayState.instance.modchartSprites.get(tag);
			if(destroy) {
				pee.kill();
			}

			if(pee.wasAdded) {
				getInstance().remove(pee, true);
				pee.wasAdded = false;
			}

			if(destroy) {
				pee.destroy();
				PlayState.instance.modchartSprites.remove(tag);
			}
		});
		registerFunction("luaSpriteExists", function(tag:String) {
			return PlayState.instance.modchartSprites.exists(tag);
		});
		registerFunction("luaTextExists", function(tag:String) {
			return PlayState.instance.modchartTexts.exists(tag);
		});
		registerFunction("luaSoundExists", function(tag:String) {
			return PlayState.instance.modchartSounds.exists(tag);
		});
		registerFunction("setHealthBarColors", function(leftHex:String, rightHex:String) {
			var left:FlxColor = Std.parseInt(leftHex);
			if(!leftHex.startsWith('0x')) left = Std.parseInt('0xff' + leftHex);
			var right:FlxColor = Std.parseInt(rightHex);
			if(!rightHex.startsWith('0x')) right = Std.parseInt('0xff' + rightHex);

			PlayState.instance.healthBar.createFilledBar(left, right);
			PlayState.instance.healthBar.updateBar();
		});
		registerFunction("setTimeBarColors", function(leftHex:String, rightHex:String) {
			var left:FlxColor = Std.parseInt(leftHex);
			if(!leftHex.startsWith('0x')) left = Std.parseInt('0xff' + leftHex);
			var right:FlxColor = Std.parseInt(rightHex);
			if(!rightHex.startsWith('0x')) right = Std.parseInt('0xff' + rightHex);

			PlayState.instance.timeBar.createFilledBar(right, left);
			PlayState.instance.timeBar.updateBar();
		});
		registerFunction("setObjectCamera", function(obj:String, camera:String = '') {
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
			pyTrace("setObjectCamera | Object " + obj + " doesn't exist!", false, false, FlxColor.RED);
			return false;
		});
		registerFunction("setBlendMode", function(obj:String, blend:String = '') {
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
			pyTrace("setBlendMode | Object " + obj + " doesn't exist!", false, false, FlxColor.RED);
			return false;
		});
		registerFunction("screenCenter", function(obj:String, pos:String = 'xy') {
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
		registerFunction("getMidpointX", function(variable:String) {
			var killMe:Array<String> = variable.split('.');
			var obj:FlxSprite = FunkinLua.getObjectDirectly(killMe[0]);
			if(killMe.length > 1) {
				obj = FunkinLua.getVarInArray(FunkinLua.getPropertyLoopThingWhatever(killMe), killMe[killMe.length-1]);
			}
			if(obj != null) return obj.getMidpoint().x;
			return 0;
		});
		registerFunction("getMidpointY", function(variable:String) {
			var killMe:Array<String> = variable.split('.');
			var obj:FlxSprite = FunkinLua.getObjectDirectly(killMe[0]);
			if(killMe.length > 1) {
				obj = FunkinLua.getVarInArray(FunkinLua.getPropertyLoopThingWhatever(killMe), killMe[killMe.length-1]);
			}
			if(obj != null) return obj.getMidpoint().y;
			return 0;
		});
		registerFunction("getScreenPositionX", function(obj:String) {
			var killMe:Array<String> = obj.split('.');
			var spr:FlxSprite = FunkinLua.getObjectDirectly(killMe[0]);
			if(killMe.length > 1) {
				spr = FunkinLua.getVarInArray(FunkinLua.getPropertyLoopThingWhatever(killMe), killMe[killMe.length-1]);
			}
			if(spr != null) return spr.getScreenPosition().x;
			return 0;
		});
		registerFunction("getScreenPositionY", function(obj:String) {
			var killMe:Array<String> = obj.split('.');
			var spr:FlxSprite = FunkinLua.getObjectDirectly(killMe[0]);
			if(killMe.length > 1) {
				spr = FunkinLua.getVarInArray(FunkinLua.getPropertyLoopThingWhatever(killMe), killMe[killMe.length-1]);
			}
			if(spr != null) return spr.getScreenPosition().y;
			return 0;
		});

		// Lua texts
		registerFunction("makeLuaText", function(tag:String, text:String, width:Int, x:Float, y:Float) {
			tag = tag.replace('.', '');
			resetTextTag(tag);
			var leText:FlxText = new FlxText(x, y, width, text, 16);
			leText.setFormat(Paths.font("vcr.ttf"), 16, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
			leText.cameras = [PlayState.instance.camHUD];
			PlayState.instance.modchartTexts.set(tag, leText);
		});
		registerFunction("setTextString", function(tag:String, text:String) {
			var obj:FlxText = getTextObject(tag);
			if(obj != null) {
				obj.text = text;
			}
		});
		registerFunction("setTextSize", function(tag:String, size:Int) {
			var obj:FlxText = getTextObject(tag);
			if(obj != null) {
				obj.size = size;
			}
		});
		registerFunction("setTextColor", function(tag:String, color:String) {
			var obj:FlxText = getTextObject(tag);
			if(obj != null) {
				var colorNum:Int = Std.parseInt(color);
				if(!color.startsWith('0x')) colorNum = Std.parseInt('0xff' + color);
				obj.color = colorNum;
			}
		});
		registerFunction("setTextFont", function(tag:String, newFont:String) {
			var obj:FlxText = getTextObject(tag);
			if(obj != null) {
				obj.font = Paths.font(newFont);
			}
		});
		registerFunction("setTextAlignment", function(tag:String, alignment:String = 'left') {
			var obj:FlxText = getTextObject(tag);
			if(obj != null) {
				switch(alignment.toLowerCase().trim()) {
					case 'right': obj.alignment = RIGHT;
					case 'center': obj.alignment = CENTER;
					default: obj.alignment = LEFT;
				}
			}
		});
		registerFunction("getTextString", function(tag:String) {
			var obj:FlxText = getTextObject(tag);
			if(obj != null) {
				return obj.text;
			}
			return null;
		});
		registerFunction("setTextBorder", function(tag:String, size:Int, color:String, ?quality:String = 'quality') {
			var obj:FlxText = getTextObject(tag);
			if(obj != null) {
				var colorNum:Int = Std.parseInt(color);
				if(!color.startsWith('0x')) colorNum = Std.parseInt('0xff' + color);
				obj.borderStyle = OUTLINE;
				obj.borderSize = size;
				obj.borderColor = colorNum;
			}
		});

		// ---------------------------------------------------------------- //
		//                           TWEENS                                 //
		// ---------------------------------------------------------------- //
		registerFunction("doTweenX", function(tag:String, vars:String, value:Dynamic, duration:Float, ease:String) {
			var penisExam:Dynamic = tweenPrepare(tag, vars);
			if(penisExam != null) {
				PlayState.instance.modchartTweens.set(tag, FlxTween.tween(penisExam, {x: value}, duration / PlayState.instance.playbackRate, {ease: LuaUtils.getFlxEaseByString(ease),
					onComplete: function(twn:FlxTween) {
						PlayState.instance.callOnLuas('onTweenCompleted', [tag]);
						PlayState.instance.modchartTweens.remove(tag);
					}
				}));
			} else {
				pyTrace('doTweenX | Couldnt find object: ' + vars, false, false, FlxColor.RED);
			}
		});
		registerFunction("doTweenScale", function(tag:String, vars:String, value:Dynamic, duration:Float, ease:String) {
			var penisExam:Dynamic = tweenPrepare(tag, vars);
			if(penisExam != null) {
				PlayState.instance.modchartTweens.set(tag, FlxTween.tween(penisExam, {"scale.x": value, "scale.y": value}, duration / PlayState.instance.playbackRate, {ease: LuaUtils.getFlxEaseByString(ease),
					onComplete: function(twn:FlxTween) {
						PlayState.instance.callOnLuas('onTweenCompleted', [tag]);
						PlayState.instance.modchartTweens.remove(tag);
					}
				}));
			} else {
				pyTrace('doTweenScale | Couldnt find object: ' + vars, false, false, FlxColor.RED);
			}
		});
		registerFunction("doTweenY", function(tag:String, vars:String, value:Dynamic, duration:Float, ease:String) {
			var penisExam:Dynamic = tweenPrepare(tag, vars);
			if(penisExam != null) {
				PlayState.instance.modchartTweens.set(tag, FlxTween.tween(penisExam, {y: value}, duration / PlayState.instance.playbackRate, {ease: LuaUtils.getFlxEaseByString(ease),
					onComplete: function(twn:FlxTween) {
						PlayState.instance.callOnLuas('onTweenCompleted', [tag]);
						PlayState.instance.modchartTweens.remove(tag);
					}
				}));
			} else {
				pyTrace('doTweenY | Couldnt find object: ' + vars, false, false, FlxColor.RED);
			}
		});
		registerFunction("doTweenAngle", function(tag:String, vars:String, value:Dynamic, duration:Float, ease:String) {
			var penisExam:Dynamic = tweenPrepare(tag, vars);
			if(penisExam != null) {
				PlayState.instance.modchartTweens.set(tag, FlxTween.tween(penisExam, {angle: value}, duration / PlayState.instance.playbackRate, {ease: LuaUtils.getFlxEaseByString(ease),
					onComplete: function(twn:FlxTween) {
						PlayState.instance.callOnLuas('onTweenCompleted', [tag]);
						PlayState.instance.modchartTweens.remove(tag);
					}
				}));
			} else {
				pyTrace('doTweenAngle | Couldnt find object: ' + vars, false, false, FlxColor.RED);
			}
		});
		registerFunction("doTweenAlpha", function(tag:String, vars:String, value:Dynamic, duration:Float, ease:String) {
			var penisExam:Dynamic = tweenPrepare(tag, vars);
			if(penisExam != null) {
				PlayState.instance.modchartTweens.set(tag, FlxTween.tween(penisExam, {alpha: value}, duration / PlayState.instance.playbackRate, {ease: LuaUtils.getFlxEaseByString(ease),
					onComplete: function(twn:FlxTween) {
						PlayState.instance.callOnLuas('onTweenCompleted', [tag]);
						PlayState.instance.modchartTweens.remove(tag);
					}
				}));
			} else {
				pyTrace('doTweenAlpha | Couldnt find object: ' + vars, false, false, FlxColor.RED);
			}
		});
		registerFunction("doTweenZoom", function(tag:String, vars:String, value:Dynamic, duration:Float, ease:String) {
			var penisExam:Dynamic = tweenPrepare(tag, vars);
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
					pyTrace("doTweenZoom | Can't tween object " + vars + ". Value needs to be a camera.", false, false, FlxColor.RED);
				}
			} else {
				pyTrace('doTweenZoom | Couldnt find object: ' + vars, false, false, FlxColor.RED);
			}
		});
		registerFunction("doTweenColor", function(tag:String, vars:String, targetColor:String, duration:Float, ease:String) {
			var penisExam:Dynamic = tweenPrepare(tag, vars);
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
				pyTrace('doTweenColor | Couldnt find object: ' + vars, false, false, FlxColor.RED);
			}
		});

		// Tween shit, but for strums
		registerFunction("noteTweenX", function(tag:String, note:Int, value:Dynamic, duration:Float, ease:String) {
			cancelTween(tag);
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
		registerFunction("noteTweenY", function(tag:String, note:Int, value:Dynamic, duration:Float, ease:String) {
			cancelTween(tag);
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
		registerFunction("noteTweenAngle", function(tag:String, note:Int, value:Dynamic, duration:Float, ease:String) {
			cancelTween(tag);
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
		registerFunction("noteTweenDirection", function(tag:String, note:Int, value:Dynamic, duration:Float, ease:String) {
			cancelTween(tag);
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
		registerFunction("noteTweenAlpha", function(tag:String, note:Int, value:Dynamic, duration:Float, ease:String) {
			cancelTween(tag);
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
		registerFunction("noteTweenScaleX", function(tag:String, note:Int, value:Dynamic, duration:Float, ease:String) {
			cancelTween(tag);
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
		registerFunction("noteTweenScaleY", function(tag:String, note:Int, value:Dynamic, duration:Float, ease:String) {
			cancelTween(tag);
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

		registerFunction("cancelTween", function(tag:String) {
			cancelTween(tag);
		});

		// ---------------------------------------------------------------- //
		//                           TIMERS                                 //
		// ---------------------------------------------------------------- //
		registerFunction("runTimer", function(tag:String, time:Float = 1, loops:Int = 1) {
			cancelTimer(tag);
			PlayState.instance.modchartTimers.set(tag, new FlxTimer().start(time, function(tmr:FlxTimer) {
				if(tmr.finished) {
					PlayState.instance.modchartTimers.remove(tag);
				}
				PlayState.instance.callOnLuas('onTimerCompleted', [tag, tmr.loops, tmr.loopsLeft]);
			}, loops));
		});
		registerFunction("cancelTimer", function(tag:String) {
			cancelTimer(tag);
		});

		// ---------------------------------------------------------------- //
		//                           SOUND                                  //
		// ---------------------------------------------------------------- //
		registerFunction("playMusic", function(sound:String, volume:Float = 1, loop:Bool = false) {
			FlxG.sound.playMusic(Paths.music(sound), volume, loop);
		});
		registerFunction("playSound", function(sound:String, volume:Float = 1, ?tag:String = null) {
			if(tag != null && tag.length > 0) {
				tag = tag.replace('.', '');
				if(PlayState.instance.modchartSounds.exists(tag)) {
					PlayState.instance.modchartSounds.get(tag).stop();
				}
				PlayState.instance.modchartSounds.set(tag, FlxG.sound.play(Paths.sound(sound), volume, false, function() {
					PlayState.instance.modchartSounds.remove(tag);
					PlayState.instance.callOnLuas('onSoundFinished', [tag]);
				}));
				return;
			}
			FlxG.sound.play(Paths.sound(sound), volume);
		});
		registerFunction("stopSound", function(tag:String) {
			if(tag != null && tag.length > 1 && PlayState.instance.modchartSounds.exists(tag)) {
				PlayState.instance.modchartSounds.get(tag).stop();
				PlayState.instance.modchartSounds.remove(tag);
			}
		});
		registerFunction("pauseSound", function(tag:String) {
			if(tag != null && tag.length > 1 && PlayState.instance.modchartSounds.exists(tag)) {
				PlayState.instance.modchartSounds.get(tag).pause();
			}
		});
		registerFunction("resumeSound", function(tag:String) {
			if(tag != null && tag.length > 1 && PlayState.instance.modchartSounds.exists(tag)) {
				PlayState.instance.modchartSounds.get(tag).play();
			}
		});
		registerFunction("soundFadeIn", function(tag:String, duration:Float, fromValue:Float = 0, toValue:Float = 1) {
			if(tag == null || tag.length < 1) {
				FlxG.sound.music.fadeIn(duration / PlayState.instance.playbackRate, fromValue, toValue);
			} else if(PlayState.instance.modchartSounds.exists(tag)) {
				PlayState.instance.modchartSounds.get(tag).fadeIn(duration / PlayState.instance.playbackRate, fromValue, toValue);
			}
		});
		registerFunction("soundFadeOut", function(tag:String, duration:Float, toValue:Float = 0) {
			if(tag == null || tag.length < 1) {
				FlxG.sound.music.fadeOut(duration / PlayState.instance.playbackRate, toValue);
			} else if(PlayState.instance.modchartSounds.exists(tag)) {
				PlayState.instance.modchartSounds.get(tag).fadeOut(duration / PlayState.instance.playbackRate, toValue);
			}
		});
		registerFunction("soundFadeCancel", function(tag:String) {
			if(tag == null || tag.length < 1) {
				if(FlxG.sound.music.fadeTween != null) {
					FlxG.sound.music.fadeTween.cancel();
				}
			} else if(PlayState.instance.modchartSounds.exists(tag)) {
				var theSound:FlxSound = PlayState.instance.modchartSounds.get(tag);
				if(theSound.fadeTween != null) {
					theSound.fadeTween.cancel();
				}
			}
		});
		registerFunction("killSound", function(tag:String) {
			if(tag == null || tag.length < 1) {
				FlxG.sound.music.stop();
				FlxG.sound.music.destroy();
			} else if(PlayState.instance.modchartSounds.exists(tag)) {
				var theSound:FlxSound = PlayState.instance.modchartSounds.get(tag);
				theSound.stop();
				theSound.destroy();
				PlayState.instance.modchartSounds.remove(tag);
			}
		});

		// ---------------------------------------------------------------- //
		//                           MISC                                   //
		// ---------------------------------------------------------------- //
		registerFunction("getSongPosition", function() {
			return Conductor.songPosition;
		});
		registerFunction("precacheImage", function(name:String) {
			Paths.image(name);
		});
		registerFunction("precacheSound", function(name:String) {
			Paths.sound(name);
		});
		registerFunction("precacheMusic", function(name:String) {
			Paths.music(name);
		});
		registerFunction("triggerEvent", function(name:String, arg1:Dynamic, arg2:Dynamic, strumTime:Float) {
			var value1:String = arg1;
			var value2:String = arg2;
			PlayState.instance.triggerEventNote(name, value1, value2, strumTime);
			return true;
		});
		registerFunction("startCountdown", function() {
			PlayState.instance.startCountdown();
			return true;
		});
		registerFunction("endSong", function() {
			PlayState.instance.KillNotes();
			PlayState.instance.endSong();
			return true;
		});
		registerFunction("restartSong", function(?skipTransition:Bool = false) {
			PlayState.instance.persistentUpdate = false;
			PauseSubState.restartSong(skipTransition);
			return true;
		});
		registerFunction("getRandomInt", function(min:Int, max:Int = FlxMath.MAX_VALUE_INT, exclude:String = '') {
			var excludeArray:Array<String> = exclude.split(',');
			var toExclude:Array<Int> = [];
			for (i in 0...excludeArray.length) {
				toExclude.push(Std.parseInt(excludeArray[i].trim()));
			}
			return FlxG.random.int(min, max, toExclude);
		});
		registerFunction("getRandomFloat", function(min:Float, max:Float = 1, exclude:String = '') {
			var excludeArray:Array<String> = exclude.split(',');
			var toExclude:Array<Float> = [];
			for (i in 0...excludeArray.length) {
				toExclude.push(Std.parseFloat(excludeArray[i].trim()));
			}
			return FlxG.random.float(min, max, toExclude);
		});
		registerFunction("getRandomBool", function(chance:Float = 50) {
			return FlxG.random.bool(chance);
		});
		registerFunction("getTextFromFile", function(path:String, ?ignoreModFolders:Bool = false) {
			return Paths.getTextFromFile(path, ignoreModFolders);
		});
		registerFunction("flushSaveData", function(name:String) {
			var save = Reflect.getProperty(FlxG.save, name);
			if (save != null) save.flush();
		});
		registerFunction("debugPrint", function(text1:Dynamic = '', text2:Dynamic = '', text3:Dynamic = '', text4:Dynamic = '', text5:Dynamic = '') {
			if (text1 == null) text1 = '';
			if (text2 == null) text2 = '';
			if (text3 == null) text3 = '';
			if (text4 == null) text4 = '';
			if (text5 == null) text5 = '';
			pyTrace('' + text1 + text2 + text3 + text4 + text5, true, false);
		});
		registerFunction("close", function() {
			closed = true;
			return closed;
		});
		registerFunction("changePresence", function(details:String, state:Null<String>, ?smallImageKey:String, ?hasStartTimestamp:Bool, ?endTimestamp:Float) {
			#if DISCORD_ALLOWED
			DiscordClient.changePresence(details, state, smallImageKey, hasStartTimestamp, endTimestamp);
			#end
		});
	}

	// -------------------------------------------------------------------- //
	//                            INTERNALS                                 //
	// -------------------------------------------------------------------- //

	public function call(func:String, args:Array<Dynamic>):Dynamic {
		if (closed) return Function_Continue;

		lastCalledFunction = func;
		lastCalledScript = this;

		if (_missingCalls.exists(func)) return Function_Continue;

		try {
			if (interp == null || !interp.getdef(func)) {
				_missingCalls.set(func, true);
				return Function_Continue;
			}

			var result:Dynamic = interp.calldef(func, args);
			if (result == null) result = Function_Continue;
			return result;
		}
		catch (e:Error) {
			pyTrace("ERROR (" + func + "): " + getErrorString(e), false, false, FlxColor.RED);
			_missingCalls.set(func, true);
			return Function_Continue;
		}
		catch (e:Dynamic) {
			pyTrace("ERROR (" + func + "): " + Std.string(e), false, false, FlxColor.RED);
			_missingCalls.set(func, true);
			return Function_Continue;
		}
	}

	public function set(variable:String, data:Dynamic) {
		if (closed) return;

		_missingCalls.remove(variable);
		try {
			interp.setVar(variable, data);
		}
		catch (e:Error) {
			pyTrace("ERROR (set " + variable + "): " + getErrorString(e), false, false, FlxColor.RED);
		}
		catch (e:Dynamic) {
			pyTrace("ERROR (set " + variable + "): " + Std.string(e), false, false, FlxColor.RED);
		}
	}

	public function get(variable:String):Dynamic {
		if (closed) return null;
		try {
			return interp.getVar(variable);
		}
		catch (e:Error) {
			return null;
		}
		catch (e:Dynamic) {
			return null;
		}
	}

	public function stop() {
		closed = true;
		if (interp == null) return;
		try {
			interp.stop();
		}
		catch (e:Dynamic) {
			// ignore
		}
	}

	public function pyTrace(text:String, ignoreCheck:Bool = false, deprecated:Bool = false, color:FlxColor = FlxColor.WHITE) {
		if (ignoreCheck || getVar('pythonDebugMode')) {
			if (deprecated && !getVar('pythonDeprecatedWarnings')) {
				return;
			}
			PlayState.instance.addTextToDebug(text, color);
			trace(text);
		}
	}

	public function getVar(variable:String):Dynamic {
		if (closed) return false;
		try {
			var result:Dynamic = interp.getVar(variable);
			if (result == null) {
				return false;
			}
			return result;
		}
		catch (e:Error) {
			return false;
		}
		catch (e:Dynamic) {
			return false;
		}
	}

	static function getErrorString(e:Error):String {
		return switch (e) {
			case EUnknownVariable(v): "NameError: name '" + v + "' is not defined";
			case EInvalidAccess(f): "AttributeError: cannot access field '" + f + "'";
			case EKeyError(msg): "KeyError: " + msg;
			case ETypeError(msg): "TypeError: " + msg;
			case EValueError(msg): "ValueError: " + msg;
			case EZeroDivisionError(msg): "ZeroDivisionError: " + msg;
			case ENameError(msg): "NameError: " + msg;
			case EAssertionError(msg): "AssertionError: " + msg;
			case ERecursionError(msg): "RecursionError: " + msg;
			case EInvalidOp(op): "SyntaxError: invalid operation '" + op + "'";
			case ESyntaxError(msg): "SyntaxError: " + msg;
			case EUnterminatedString: "SyntaxError: unterminated string literal";
			case EUnterminatedComment: "SyntaxError: unterminated comment";
			case EInvalidChar(c): "SyntaxError: invalid character '" + String.fromCharCode(c) + "'";
			case EInvalidIterator(v): "TypeError: '" + v + "' object is not iterable";
			case ETabError(msg): "TabError: " + msg;
			case ECustom(msg): Std.string(msg);
			case EExitException(code): "SystemExit: " + code;
			case EClassNotAllowed(msg): msg;
			case EInvalidPreprocessor(msg): msg;
			case EUnexpected(s): "SyntaxError: unexpected '" + s + "'";
		}
	}

	public static function registerFunction(name:String, func:Dynamic):Void
		registeredFunctions.set(name, func);

	public static function isOfTypes(value:Any, types:Array<Dynamic>) {
		for (type in types) {
			if (Std.isOfType(value, type)) return true;
		}
		return false;
	}

	function registerCustomFunctions() {
		for (name => func in customFunctions) {
			if (func != null) {
				_missingCalls.remove(name);
				set(name, func);
			}
		}
	}

	function addLocalCallback(name:String, myFunction:Dynamic) {
		_missingCalls.remove(name);
		set(name, myFunction);
	}

	// -------------------------------------------------------------------- //
	//                          HELPERS                                     //
	// -------------------------------------------------------------------- //

	function getInstance():Dynamic {
		return PlayState.instance.isDead ? GameOverSubstate.instance : PlayState.instance;
	}

	inline function getTextObject(name:String):FlxText {
		return PlayState.instance.modchartTexts.exists(name) ? PlayState.instance.modchartTexts.get(name) : Reflect.getProperty(PlayState.instance, name);
	}

	function getGroupStuff(leArray:Dynamic, variable:String) {
		var killMe:Array<String> = variable.split('.');
		if(killMe.length > 1) {
			var coverMeInPiss:Dynamic = Reflect.getProperty(leArray, killMe[0]);
			for (i in 1...killMe.length-1) {
				coverMeInPiss = Reflect.getProperty(coverMeInPiss, killMe[i]);
			}
			switch(Type.typeof(coverMeInPiss)) {
				case ValueType.TClass(haxe.ds.StringMap) | ValueType.TClass(haxe.ds.ObjectMap) | ValueType.TClass(haxe.ds.IntMap) | ValueType.TClass(haxe.ds.EnumValueMap):
					return coverMeInPiss.get(killMe[killMe.length-1]);
				default:
					return Reflect.getProperty(coverMeInPiss, killMe[killMe.length-1]);
			}
		}
		switch(Type.typeof(leArray)) {
			case ValueType.TClass(haxe.ds.StringMap) | ValueType.TClass(haxe.ds.ObjectMap) | ValueType.TClass(haxe.ds.IntMap) | ValueType.TClass(haxe.ds.EnumValueMap):
				return leArray.get(variable);
			default:
				return Reflect.getProperty(leArray, variable);
		}
	}

	function setGroupStuff(leArray:Dynamic, variable:String, value:Dynamic) {
		var killMe:Array<String> = variable.split('.');
		if(killMe.length > 1) {
			var coverMeInPiss:Dynamic = Reflect.getProperty(leArray, killMe[0]);
			for (i in 1...killMe.length-1) {
				coverMeInPiss = Reflect.getProperty(coverMeInPiss, killMe[i]);
			}
			Reflect.setProperty(coverMeInPiss, killMe[killMe.length-1], value);
			return;
		}
		Reflect.setProperty(leArray, variable, value);
	}

	function loadFrames(spr:FlxSprite, image:String, spriteType:String) {
		switch(spriteType.toLowerCase().trim()) {
			case 'aseprite' | 'jsoni8':
				spr.frames = Paths.getAsepriteAtlas(image);
			case 'packer' | 'packeratlas' | 'pac':
				spr.frames = Paths.getPackerAtlas(image);
			default:
				spr.frames = Paths.getSparrowAtlas(image);
		}
	}

	function resetTextTag(tag:String) {
		if(!PlayState.instance.modchartTexts.exists(tag)) {
			return;
		}

		var pee:FlxText = PlayState.instance.modchartTexts.get(tag);
		if(pee != null)
			PlayState.instance.remove(pee, true);

		pee.destroy();
		PlayState.instance.modchartTexts.remove(tag);
	}

	function resetSpriteTag(tag:String) {
		if(!PlayState.instance.modchartSprites.exists(tag)) {
			return;
		}

		var pee:ModchartSprite = PlayState.instance.modchartSprites.get(tag);
		pee.kill();
		if(pee.wasAdded) {
			PlayState.instance.remove(pee, true);
		}
		pee.destroy();
		PlayState.instance.modchartSprites.remove(tag);
	}

	function cancelTween(tag:String) {
		if(PlayState.instance.modchartTweens.exists(tag)) {
			PlayState.instance.modchartTweens.get(tag).cancel();
			PlayState.instance.modchartTweens.get(tag).destroy();
			PlayState.instance.modchartTweens.remove(tag);
		}
	}

	function tweenPrepare(tag:String, vars:String) {
		if (tag != null) cancelTween(tag);
		var variables:Array<String> = vars.split('.');
		var sexyProp:Dynamic = FunkinLua.getObjectDirectly(variables[0]);
		if(variables.length > 1)
			sexyProp = FunkinLua.getVarInArray(FunkinLua.getPropertyLoopThingWhatever(variables), variables[variables.length-1]);

		return sexyProp;
	}

	function cancelTimer(tag:String) {
		if(PlayState.instance.modchartTimers.exists(tag)) {
			PlayState.instance.modchartTimers.get(tag).cancel();
			PlayState.instance.modchartTimers.remove(tag);
		}
	}

	static function addAnimByIndices(obj:String, name:String, prefix:String, indices:String, framerate:Int = 24, loop:Bool = false) {
		var spr:FlxSprite = PlayState.instance.getLuaObject(obj, false);
		if(spr == null) {
			spr = Reflect.getProperty(PlayState.instance, obj);
		}

		if(spr != null) {
			var _indices:Array<Int> = [];
			for (ind in indices.split(',')) {
				_indices.push(Std.parseInt(ind));
			}
			spr.animation.addByIndices(name, prefix, _indices, '', framerate, loop);
			if(spr.animation.curAnim == null) {
				spr.animation.play(name, true);
			}
			return true;
		}
		return false;
	}

	public static inline function getInstanceStatic()
	{
		return PlayState.instance.isDead ? GameOverSubstate.instance : PlayState.instance;
	}
}
#end
