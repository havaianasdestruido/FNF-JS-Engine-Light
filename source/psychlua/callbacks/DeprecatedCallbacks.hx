package psychlua.callbacks;

import play.PlayState;
import psychlua.FunkinLua;
import psychlua.LuaUtils;
import psychlua.ModchartSprite;

import objects.Character;

// REFACTOR: extracted from psychlua.FunkinLua (deprecated backward-compat functions)
class DeprecatedCallbacks
{
	public static function register(funk:FunkinLua):Void {
		@:privateAccess {
		// DEPRECATED, DONT MESS WITH THESE SHITS, ITS JUST THERE FOR BACKWARD COMPATIBILITY
		FunkinLua.registerFunction("objectPlayAnimation", function(obj:String, name:String, forced:Bool = false, ?startFrame:Int = 0) {
			LuaUtils.luaTrace(funk.lua, "objectPlayAnimation is deprecated! Use playAnim instead", false, true);
			if(PlayState.instance.getLuaObject(obj,false) != null) {
				PlayState.instance.getLuaObject(obj,false).animation.play(name, forced, false, startFrame);
				return true;
			}

			var spr:FlxSprite = Reflect.getProperty(FunkinLua.getInstance(), obj);
			if(spr != null) {
				spr.animation.play(name, forced, false, startFrame);
				return true;
			}
			return false;
		});
		FunkinLua.registerFunction("characterPlayAnim", function(character:String, anim:String, ?forced:Bool = false) {
			LuaUtils.luaTrace(funk.lua, "characterPlayAnim is deprecated! Use playAnim instead", false, true);
			switch(character.toLowerCase()) {
				case 'dad':
					if(PlayState.instance.dad.animOffsets.exists(anim))
						PlayState.instance.dad.playAnim(anim, forced);
				case 'gf' | 'girlfriend':
					if(PlayState.instance.gf != null && PlayState.instance.gf.animOffsets.exists(anim))
						PlayState.instance.gf.playAnim(anim, forced);
				default:
					if(PlayState.instance.boyfriend.animOffsets.exists(anim))
						PlayState.instance.boyfriend.playAnim(anim, forced);
			}
		});
		FunkinLua.registerFunction("luaSpriteMakeGraphic", function(tag:String, width:Int, height:Int, color:String) {
			LuaUtils.luaTrace(funk.lua, "luaSpriteMakeGraphic is deprecated! Use makeGraphic instead", false, true);
			if(PlayState.instance.modchartSprites.exists(tag)) {
				var colorNum:Int = Std.parseInt(color);
				if(!color.startsWith('0x')) colorNum = Std.parseInt('0xff' + color);

				PlayState.instance.modchartSprites.get(tag).makeGraphic(width, height, colorNum);
			}
		});
		FunkinLua.registerFunction("luaSpriteAddAnimationByPrefix", function(tag:String, name:String, prefix:String, framerate:Int = 24, loop:Bool = true) {
			LuaUtils.luaTrace(funk.lua, "luaSpriteAddAnimationByPrefix is deprecated! Use addAnimationByPrefix instead", false, true);
			if(PlayState.instance.modchartSprites.exists(tag)) {
				var cock:ModchartSprite = PlayState.instance.modchartSprites.get(tag);
				cock.animation.addByPrefix(name, prefix, framerate, loop);
				if(cock.animation.curAnim == null) {
					cock.animation.play(name, true);
				}
			}
		});
		FunkinLua.registerFunction("luaSpriteAddAnimationByIndices", function(tag:String, name:String, prefix:String, indices:String, framerate:Int = 24) {
			LuaUtils.luaTrace(funk.lua, "luaSpriteAddAnimationByIndices is deprecated! Use addAnimationByIndices instead", false, true);
			if(PlayState.instance.modchartSprites.exists(tag)) {
				var strIndices:Array<String> = indices.trim().split(',');
				var die:Array<Int> = [];
				for (i in 0...strIndices.length) {
					die.push(Std.parseInt(strIndices[i]));
				}
				var pussy:ModchartSprite = PlayState.instance.modchartSprites.get(tag);
				pussy.animation.addByIndices(name, prefix, die, '', framerate, false);
				if(pussy.animation.curAnim == null) {
					pussy.animation.play(name, true);
				}
			}
		});
		FunkinLua.registerFunction("luaSpritePlayAnimation", function(tag:String, name:String, forced:Bool = false) {
			LuaUtils.luaTrace(funk.lua, "luaSpritePlayAnimation is deprecated! Use playAnim instead", false, true);
			if(PlayState.instance.modchartSprites.exists(tag)) {
				PlayState.instance.modchartSprites.get(tag).animation.play(name, forced);
			}
		});
		FunkinLua.registerFunction("setLuaSpriteCamera", function(tag:String, camera:String = '') {
			LuaUtils.luaTrace(funk.lua, "setLuaSpriteCamera is deprecated! Use setObjectCamera instead", false, true);
			if(PlayState.instance.modchartSprites.exists(tag)) {
				PlayState.instance.modchartSprites.get(tag).cameras = [LuaUtils.cameraFromString(camera)];
				return true;
			}
			LuaUtils.luaTrace(funk.lua, "Lua sprite with tag | " + tag + " doesn't exist!");
			return false;
		});
		FunkinLua.registerFunction("setLuaSpriteScrollFactor", function(tag:String, scrollX:Float, scrollY:Float) {
			LuaUtils.luaTrace(funk.lua, "setLuaSpriteScrollFactor is deprecated! Use setScrollFactor instead", false, true);
			if(PlayState.instance.modchartSprites.exists(tag)) {
				PlayState.instance.modchartSprites.get(tag).scrollFactor.set(scrollX, scrollY);
				return true;
			}
			return false;
		});
		FunkinLua.registerFunction("scaleLuaSprite", function(tag:String, x:Float, y:Float) {
			LuaUtils.luaTrace(funk.lua, "scaleLuaSprite is deprecated! Use scaleObject instead", false, true);
			if(PlayState.instance.modchartSprites.exists(tag)) {
				var shit:ModchartSprite = PlayState.instance.modchartSprites.get(tag);
				shit.scale.set(x, y);
				shit.updateHitbox();
				return true;
			}
			return false;
		});
		FunkinLua.registerFunction("getPropertyLuaSprite", function(tag:String, variable:String) {
			LuaUtils.luaTrace(funk.lua, "getPropertyLuaSprite is deprecated! Use getProperty instead", false, true);
			if(PlayState.instance.modchartSprites.exists(tag)) {
				var killMe:Array<String> = variable.split('.');
				if(killMe.length > 1) {
					var coverMeInPiss:Dynamic = Reflect.getProperty(PlayState.instance.modchartSprites.get(tag), killMe[0]);
					for (i in 1...killMe.length-1) {
						coverMeInPiss = Reflect.getProperty(coverMeInPiss, killMe[i]);
					}
					return Reflect.getProperty(coverMeInPiss, killMe[killMe.length-1]);
				}
				return Reflect.getProperty(PlayState.instance.modchartSprites.get(tag), variable);
			}
			return null;
		});
		FunkinLua.registerFunction("setPropertyLuaSprite", function(tag:String, variable:String, value:Dynamic) {
			LuaUtils.luaTrace(funk.lua, "setPropertyLuaSprite is deprecated! Use setProperty instead", false, true);
			if(PlayState.instance.modchartSprites.exists(tag)) {
				var killMe:Array<String> = variable.split('.');
				if(killMe.length > 1) {
					var coverMeInPiss:Dynamic = Reflect.getProperty(PlayState.instance.modchartSprites.get(tag), killMe[0]);
					for (i in 1...killMe.length-1) {
						coverMeInPiss = Reflect.getProperty(coverMeInPiss, killMe[i]);
					}
					Reflect.setProperty(coverMeInPiss, killMe[killMe.length-1], value);
					return true;
				}
				Reflect.setProperty(PlayState.instance.modchartSprites.get(tag), variable, value);
				return true;
			}
			LuaUtils.luaTrace(funk.lua, "setPropertyLuaSprite | Lua sprite with tag: " + tag + " doesn't exist!");
			return false;
		});
		FunkinLua.registerFunction("musicFadeIn", function(duration:Float, fromValue:Float = 0, toValue:Float = 1) {
			FlxG.sound.music.fadeIn(duration / PlayState.instance.playbackRate, fromValue, toValue);
			LuaUtils.luaTrace(funk.lua, 'musicFadeIn is deprecated! Use soundFadeIn instead.', false, true);

		});
		FunkinLua.registerFunction("musicFadeOut", function(duration:Float, toValue:Float = 0) {
			FlxG.sound.music.fadeOut(duration / PlayState.instance.playbackRate, toValue);
			LuaUtils.luaTrace(funk.lua, 'musicFadeOut is deprecated! Use soundFadeOut instead.', false, true);
		});
		}
	}
}
