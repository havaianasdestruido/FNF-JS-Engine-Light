package psychlua;

// REFACTOR: subtypes of shaders.ErrorHandledShader need explicit imports

import Type.ValueType;
import flixel.FlxBasic;
import flixel.addons.effects.FlxTrail;
import flixel.input.keyboard.FlxKey;
import flixel.system.FlxAssets.FlxShader;
import openfl.Lib;
import openfl.display.BitmapData;
import openfl.display.BlendMode;
import backend.Paths;
import backend.ClientPrefs;
import backend.WeekData;
import play.PlayState;
import states.MainMenuState;
import objects.NoteSplash;
import psychlua.callbacks.CameraCallbacks;
import psychlua.callbacks.DeprecatedCallbacks;
import psychlua.callbacks.EffectCallbacks;
import psychlua.callbacks.FileCallbacks;
import psychlua.callbacks.GameCallbacks;
import psychlua.callbacks.InputCallbacks;
import psychlua.callbacks.MiscCallbacks;
import psychlua.callbacks.PropertyCallbacks;
import psychlua.callbacks.SaveDataCallbacks;
import psychlua.callbacks.ScriptCallbacks;
import psychlua.callbacks.ShaderCallbacks;
import psychlua.callbacks.SoundCallbacks;
import psychlua.callbacks.SpriteCallbacks;
import psychlua.callbacks.TextCallbacks;
import psychlua.callbacks.TweenCallbacks;

// REFACTOR: imports for relocated root classes
import backend.Conductor;
import backend.CoolUtil;
import data.Song;
import objects.Character;
import objects.Note;
import objects.NoteHelpers;

#if SHADERS_ALLOWED
import flixel.addons.display.FlxRuntimeShader;
import openfl.filters.BitmapFilter;
import openfl.filters.ShaderFilter;
import shaders.ErrorHandledShader;
#end

#if DISCORD_ALLOWED
import backend.DiscordClient;
#end

#if ACHIEVEMENTS_ALLOWED
import backend.Achievements;
#end

typedef LuaTweenOptions = {
	type:FlxTweenType,
	startDelay:Float,
	onUpdate:Null<String>,
	onStart:Null<String>,
	onComplete:Null<String>,
	loopDelay:Float,
	ease:EaseFunction
}

class FunkinLua {
	public static var Function_Stop:Dynamic = "##PSYCHLUA_FUNCTIONSTOP";
	public static var Function_Continue:Dynamic = "##PSYCHLUA_FUNCTIONCONTINUE";
	public static var Function_StopLua:Dynamic = "##PSYCHLUA_FUNCTIONSTOPLUA";

	#if (MODS_ALLOWED && SHADERS_ALLOWED)
	private static var storedFilters:Map<String, ShaderFilter> = []; // for a few shader functions
	#end

	//public var errorHandler:String->Void;
	#if LUA_ALLOWED
	public var lua:State = null;
	#end
	public var camTarget:FlxCamera;
	public var scriptName:String = '';
	public var modFolder:String = null;
	public var closed:Bool = false;

	#if HSCRIPT_ALLOWED
	public var hscript:HScript = null;
	#end

	public var callbacks:Map<String, Dynamic> = [];
	public static var customFunctions:Map<String, Dynamic> = [];
	public static var registeredFunctions:Map<String, Dynamic> = [];

	#if LUA_ALLOWED
	private var _missingCalls:Map<String, Bool> = new Map();
	#end

	public function new(scriptName:String, ?scriptCode:String) {
		#if LUA_ALLOWED
		lua = LuaL.newstate();
		LuaL.openlibs(lua);

		//trace('Lua version: ' + Lua.version());
		//trace("LuaJIT version: " + Lua.versionJIT());

		//LuaL.dostring(lua, CLENSE);
		this.scriptName = scriptName;
		final game:PlayState = PlayState.instance;
		game.luaArray.push(this);

		var myFolder:Array<String> = this.scriptName.split('/');
		#if MODS_ALLOWED
		if(myFolder[0] + '/' == Paths.mods() && (Mods.currentModDirectory == myFolder[1] || Mods.getGlobalMods().contains(myFolder[1]))) //is inside mods folder
			this.modFolder = myFolder[1];
		#end
		try{
			var result:Int = scriptCode != null ? LuaL.dostring(lua, scriptCode) : LuaL.dofile(lua, scriptName);
			var resultStr:String = Lua.tostring(lua, result);
			if(resultStr != null && result != 0) {
				trace('Error on lua script! ' + resultStr);
				#if windows
				lime.app.Application.current.window.alert(resultStr, 'Error on lua script!');
				#else
				LuaUtils.luaTrace(lua, 'Error loading lua script: "$scriptName"\n' + resultStr, true, false, FlxColor.RED);
				#end
				lua = null;
				return;
			}
		} catch(e:Dynamic) {
			trace(e);
			return;
		}

		trace('lua file loaded succesfully:' + scriptName);

		// Lua shit
		set('Function_StopLua', Function_StopLua);
		set('Function_Stop', Function_Stop);
		set('Function_Continue', Function_Continue);
		set('luaDebugMode', false);
		set('luaDeprecatedWarnings', true);
		set('inChartEditor', false);
		set('modFolder', this.modFolder);

		// Song/Week shit
		set('curBpm', Conductor.bpm);
		set('bpm', PlayState.SONG.bpm);
		set('scrollSpeed', PlayState.SONG.speed);
		set('crochet', Conductor.crochet);
		set('stepCrochet', Conductor.stepCrochet);
		set('songLength', FlxG.sound.music.length);
		set('songName', PlayState.SONG.song);
		set('songPath', Paths.formatToSongPath(PlayState.SONG.song));
		set('startedCountdown', false);
		set('curStage', PlayState.SONG.stage);

		set('isStoryMode', PlayState.isStoryMode);
		set('difficulty', PlayState.storyDifficulty);

		var difficultyName:String = CoolUtil.difficulties[PlayState.storyDifficulty];
		set('difficultyName', difficultyName);
		set('difficultyPath', Paths.formatToSongPath(difficultyName));
		set('weekRaw', PlayState.storyWeek);
		set('week', WeekData.weeksList[PlayState.storyWeek]);
		set('seenCutscene', PlayState.seenCutscene);

		// Camera poo
		set('cameraX', 0);
		set('cameraY', 0);

		// Screen stuff
		set('screenWidth', FlxG.width);
		set('screenHeight', FlxG.height);

		// PlayState cringe ass nae nae bullcrap
		set('curBeat', 0);
		set('curStep', 0);
		set('curDecBeat', 0);
		set('curDecStep', 0);

		set('score', 0);
		set('misses', 0);
		set('hits', 0);

		set('rating', 0);
		set('ratingName', '');
		set('ratingFC', '');
		set('version', MainMenuState.psychEngineVersion.trim());
		set('jsVersion', MainMenuState.psychEngineJSVersion.trim());

		set('inGameOver', false);
		set('mustHitSection', false);
		set('altAnim', false);
		set('gfSection', false);

		set('npsSpeedMult', game.npsSpeedMult);

		// these things are useless
		set('polyphonyOppo', game.polyphonyOppo);
		set('polyphonyBF', game.polyphonyBF);

		// Gameplay settings
		set('healthGainMult', game.healthGain);
		set('healthLossMult', game.healthLoss);
		set('playbackRate', game.playbackRate);
		set('instakillOnMiss', game.instakillOnMiss);
		set('botPlay', game.cpuControlled);
		set('practice', game.practiceMode);

		for (i in 0...4) {
			set('defaultPlayerStrumX' + i, 0);
			set('defaultPlayerStrumY' + i, 0);
			set('defaultOpponentStrumX' + i, 0);
			set('defaultOpponentStrumY' + i, 0);
		}

		// Default character positions woooo
		set('defaultBoyfriendX', game.BF_X);
		set('defaultBoyfriendY', game.BF_Y);
		set('defaultOpponentX', game.DAD_X);
		set('defaultOpponentY', game.DAD_Y);
		set('defaultGirlfriendX', game.GF_X);
		set('defaultGirlfriendY', game.GF_Y);

		// Character shit
		set('boyfriendName', PlayState.SONG.player1 ?? 'bf');
		set('dadName', PlayState.SONG.player2 ?? 'dad');
		set('gfName', PlayState.SONG.gfVersion ?? 'gf');

		// Some settings, no jokes
		set('downscroll', ClientPrefs.downScroll);
		set('middlescroll', ClientPrefs.middleScroll);
		set('framerate', ClientPrefs.framerate);
		set('ghostTapping', ClientPrefs.ghostTapping);
		set('hideHud', ClientPrefs.hideHud);
		set('timeBarType', ClientPrefs.timeBarType);
		set('scoreZoom', ClientPrefs.scoreZoom);
		set('cameraZoomOnBeat', ClientPrefs.camZooms);
		set('flashingLights', ClientPrefs.flashing);
		set('noteOffset', ClientPrefs.noteOffset);
		set('healthBarAlpha', ClientPrefs.healthBarAlpha);
		set('noResetButton', ClientPrefs.noReset);
		set('lowQuality', ClientPrefs.lowQuality);
		set('shadersEnabled', ClientPrefs.shaders);
		set('scriptName', scriptName);
		set('currentModDirectory', Mods.currentModDirectory);

		// Noteskin/Splash shit
		set('noteSkin', ClientPrefs.noteSkin);
		set('noteSkinPostfix', NoteHelpers.getNoteSkinPostfix());
		set('splashSkin', ClientPrefs.splashType);
		set('splashSkinPostfix', NoteSplash.getSplashSkinPostfix());

		// If you don't want this to show, you can use the lua script to change it
		set('user_path', CoolSystemStuff.getUserPath());
		set("user_name", CoolSystemStuff.getUsername());

		#if windows
		set('buildTarget', 'windows');
		#elseif linux
		set('buildTarget', 'linux');
		#elseif mac
		set('buildTarget', 'mac');
		#elseif html5
		set('buildTarget', 'browser');
		#elseif android
		set('buildTarget', 'android');
		#else
		set('buildTarget', 'unknown');
		#end

		for (name => func in customFunctions) {
			if (func != null) {
				_missingCalls.remove(name);
				Convert.addCallback(lua, name, func);
			}
		}

		// shader shit
// REFACTOR: extracted to psychlua.callbacks.ShaderCallbacks
	ShaderCallbacks.register(this);

// REFACTOR: extracted to psychlua.callbacks.ScriptCallbacks
	ScriptCallbacks.register(this);

// REFACTOR: extracted to psychlua.callbacks.PropertyCallbacks
	PropertyCallbacks.register(this);

// REFACTOR: extracted to psychlua.callbacks.TweenCallbacks
	TweenCallbacks.register(this);

// REFACTOR: extracted to psychlua.callbacks.InputCallbacks
	InputCallbacks.register(this);

// REFACTOR: extracted to psychlua.callbacks.GameCallbacks
	GameCallbacks.register(this);

// REFACTOR: extracted to psychlua.callbacks.SpriteCallbacks
	SpriteCallbacks.register(this);

// REFACTOR: extracted to psychlua.callbacks.SoundCallbacks
	SoundCallbacks.register(this);

// REFACTOR: extracted to psychlua.callbacks.TextCallbacks
	TextCallbacks.register(this);

// REFACTOR: extracted to psychlua.callbacks.SaveDataCallbacks
	SaveDataCallbacks.register(this);

// REFACTOR: extracted to psychlua.callbacks.FileCallbacks
	FileCallbacks.register(this);

// REFACTOR: extracted to psychlua.callbacks.DeprecatedCallbacks
	DeprecatedCallbacks.register(this);

// REFACTOR: extracted to psychlua.callbacks.EffectCallbacks
	EffectCallbacks.register(this);

// REFACTOR: extracted to psychlua.callbacks.MiscCallbacks
	MiscCallbacks.register(this);

	#if ACHIEVEMENTS_ALLOWED Achievements.addLuaCallbacks(lua); #end
	#if HSCRIPT_ALLOWED HScript.implement(this); #end
	CustomSubstate.implement(this);
	#if flxanimate FlxAnimateFunctions.implement(this); #end

// REFACTOR: extracted to psychlua.callbacks.CameraCallbacks
	CameraCallbacks.register(this);

		for (name => func in registeredFunctions) {
			if (func != null) {
				_missingCalls.remove(name);
				Convert.addCallback(lua, name, func);
			}
		}

		call('onCreate', []);
		#end
	}

	public function addLocalCallback(name:String, myFunction:Dynamic)
	{
		#if LUA_ALLOWED
		_missingCalls.remove(name);
		#end
		callbacks.set(name, myFunction);
		Convert.addCallback(lua, name, null); // just so that it gets called
	}

	public static function registerFunction(name:String, func:Dynamic):Void
		registeredFunctions.set(name, func);

	// REFACTOR: stateless helpers moved to LuaUtils; kept as forwarding statics for external callers
	public static function setVarInArray(instance:Dynamic, variable:String, value:Dynamic):Any
		return LuaUtils.setVarInArray(instance, variable, value);

	public static function getVarInArray(instance:Dynamic, variable:String):Any
		return LuaUtils.getVarInArray(instance, variable);

	inline static function getTextObject(name:String):FlxText
	{
		return PlayState.instance.modchartTexts.exists(name) ? PlayState.instance.modchartTexts.get(name) : Reflect.getProperty(PlayState.instance, name);
	}

	#if (SHADERS_ALLOWED)
	public function getShader(obj:String):FlxRuntimeShader
	{
		var killMe:Array<String> = obj.split('.');
		var leObj:FlxSprite = getObjectDirectly(killMe[0]);
		if(killMe.length > 1) {
			leObj = getVarInArray(getPropertyLoopThingWhatever(killMe), killMe[killMe.length-1]);
		}

		if(leObj != null) {
			var shader:Dynamic = leObj.shader;
			var shader:FlxRuntimeShader = shader;
			return shader;
		}
		return null;
	}
	#end

	function initLuaShader(name:String, ?glslVersion:Int = 120)
	{
		if(!ClientPrefs.shaders) return false;

		#if (SHADERS_ALLOWED)
		if(PlayState.instance.runtimeShaders.exists(name))
		{
			LuaUtils.luaTrace(lua, 'Shader $name was already initialized!');
			return true;
		}

		var foldersToCheck:Array<String> = [Paths.mods('shaders/')];
		if(Mods.currentModDirectory != null && Mods.currentModDirectory.length > 0)
			foldersToCheck.insert(0, Paths.mods(Mods.currentModDirectory + '/shaders/'));

		for(mod in Mods.getGlobalMods())
			foldersToCheck.insert(0, Paths.mods(mod + '/shaders/'));

		for (folder in foldersToCheck)
		{
			if(FileSystem.exists(folder))
			{
				var frag:String = folder + name + '.frag';
				var vert:String = folder + name + '.vert';
				var found:Bool = false;
				if(FileSystem.exists(frag))
				{
					frag = File.getContent(frag);
					found = true;
				}
				else frag = null;

				if(FileSystem.exists(vert))
				{
					vert = File.getContent(vert);
					found = true;
				}
				else vert = null;

				if(found)
				{
					PlayState.instance.runtimeShaders.set(name, [frag, vert]);
					//trace('Found shader $name!');
					return true;
				}
			}
		}
		LuaUtils.luaTrace(lua, 'Missing shader $name .frag AND .vert files!', false, false, FlxColor.RED);
		#else
		LuaUtils.luaTrace(lua, 'This platform doesn\'t support Runtime Shaders!', false, false, FlxColor.RED);
		#end
		return false;
	}

	function getGroupStuff(leArray:Dynamic, variable:String) {
		var killMe:Array<String> = variable.split('.');
		if(killMe.length > 1) {
			var coverMeInPiss:Dynamic = Reflect.getProperty(leArray, killMe[0]);
			for (i in 1...killMe.length-1) {
				coverMeInPiss = Reflect.getProperty(coverMeInPiss, killMe[i]);
			}
			switch(Type.typeof(coverMeInPiss)){
				case ValueType.TClass(haxe.ds.StringMap) | ValueType.TClass(haxe.ds.ObjectMap) | ValueType.TClass(haxe.ds.IntMap) | ValueType.TClass(haxe.ds.EnumValueMap):
					return coverMeInPiss.get(killMe[killMe.length-1]);
				default:
					return Reflect.getProperty(coverMeInPiss, killMe[killMe.length-1]);
			};
		}
		switch(Type.typeof(leArray)){
			case ValueType.TClass(haxe.ds.StringMap) | ValueType.TClass(haxe.ds.ObjectMap) | ValueType.TClass(haxe.ds.IntMap) | ValueType.TClass(haxe.ds.EnumValueMap):
				return leArray.get(variable);
			default:
				return Reflect.getProperty(leArray, variable);
		};
	}

	function loadFrames(spr:FlxSprite, image:String, spriteType:String)
	{
		switch(spriteType.toLowerCase().trim())
		{
			// it never seemed like anyone used this, so it's gone. We've got flxanimate anyway
			/*
			case "texture", "textureatlas", "tex":
				case "texture_noaa", "textureatlas_noaa", "tex_noaa":
					// Deprecated loader â€” only kept for legacy support
					// You should use FlxAnimate instead!
					spr.frames = AtlasFrameMaker.construct(
						image,
						null,
						spriteType.indexOf("_noaa") == -1
					);
					trace("Using legacy TextureAtlas loader. Consider migrating to FlxAnimate.");
			*/

			case 'aseprite' | 'jsoni8':
				spr.frames = Paths.getAsepriteAtlas(image);

			case "packer" | "packeratlas" | "pac":
				spr.frames = Paths.getPackerAtlas(image);

			default:
				spr.frames = Paths.getSparrowAtlas(image);
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
		var sexyProp:Dynamic = getObjectDirectly(variables[0]);
		if(variables.length > 1)
			sexyProp = getVarInArray(getPropertyLoopThingWhatever(variables), variables[variables.length-1]);

		return sexyProp;
	}

	function cancelTimer(tag:String) {
		if(PlayState.instance.modchartTimers.exists(tag)) {
			var theTimer:FlxTimer = PlayState.instance.modchartTimers.get(tag);
			theTimer.cancel();
			theTimer.destroy();
			PlayState.instance.modchartTimers.remove(tag);
		}
	}

	public var lastCalledFunction:String = '';
	public static var lastCalledScript:FunkinLua = null;
	public function call(func:String, args:Array<Dynamic>):Dynamic {
		#if LUA_ALLOWED
		if(closed) return Function_Continue;

		lastCalledFunction = func;
		lastCalledScript = this;
		try {
			if(lua == null) return Function_Continue;

			if(_missingCalls.exists(func)) return Function_Continue;

			Lua.getglobal(lua, func);
			var type:Int = Lua.type(lua, -1);

			if (type != Lua.TFUNCTION) {
				if (type > Lua.TNIL)
					LuaUtils.luaTrace(lua, "ERROR (" + func + "): attempt to call a " + LuaUtils.typeToString(type) + " value", false, false, FlxColor.RED);

				_missingCalls.set(func, true);
				Lua.pop(lua, 1);
				return Function_Continue;
			}

			for (arg in args) Convert.toLua(lua, arg);
			var status:Int = Lua.pcall(lua, args.length, 1, 0);

			// Checks if it's not successful, then show a error.
			if (status != Lua.OK) {
				var error:String = LuaUtils.getErrorMessage(lua, status);
				LuaUtils.luaTrace(lua, "ERROR (" + func + "): " + error, false, false, FlxColor.RED);
				return Function_Continue;
			}

			// If successful, pass and then return the result.
			var result:Dynamic = cast Convert.fromLua(lua, -1);
			if (result == null) result = Function_Continue;

			Lua.pop(lua, 1);
			if(closed) stop();
			return result;
		}
		catch (e:Dynamic) {
			trace(e);
		}
		#end
		return Function_Continue;
	}

	// REFACTOR: body moved to LuaUtils; kept as forwarding static for external callers
	static function addAnimByIndices(obj:String, name:String, prefix:String, indices:String, framerate:Int = 24, loop:Bool = false)
	{
		return LuaUtils.addAnimByIndices(obj, name, prefix, indices, framerate, loop);
	}

	public static function getPropertyLoopThingWhatever(killMe:Array<String>, ?checkForTextsToo:Bool = true, ?getProperty:Bool=true):Dynamic
		return LuaUtils.getPropertyLoopThingWhatever(killMe, checkForTextsToo, getProperty);

	public static function getObjectDirectly(objectName:String, ?checkForTextsToo:Bool = true):Dynamic
		return LuaUtils.getObjectDirectly(objectName, checkForTextsToo);

	public function set(variable:String, data:Dynamic) {
		#if LUA_ALLOWED
		if (lua == null)
			return;

		if (Reflect.isFunction(data)) {
			// Bind as a callable Lua function
			_missingCalls.remove(variable);
			Convert.addCallback(lua, variable, data);
			return;
		}

		// Otherwise, treat it like a variable
		_missingCalls.remove(variable);
		Convert.toLua(lua, data);
		Lua.setglobal(lua, variable);
		#end
	}

	public function stop() {
		#if LUA_ALLOWED
		closed = true;
		if(lua == null) {
			return;
		}

		Lua.close(lua);
		lua = null;
		#if HSCRIPT_ALLOWED // TODO: make this not rely on Lua
		if(hscript != null) hscript.interp = null;
		hscript = null;
		#end
		#end
	}

	// REFACTOR: body moved to LuaUtils; kept as forwarding static for external callers
	public static inline function getInstance()
	{
		return LuaUtils.getInstance();
	}
}
#if LUA_ALLOWED
typedef State = cpp.RawPointer<Lua_State>;
#end
// hi guys, my name is "secret"!
