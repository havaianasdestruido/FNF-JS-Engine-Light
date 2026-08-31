package states.helpers;

#if MODS_ALLOWED
// REFACTOR: logic extracted from states.ModsMenuState (behavior-preserving)
import backend.ClientPrefs;
import backend.Paths;
import flixel.FlxG;
import flixel.addons.transition.FlxTransitionableState;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import states.LoadingState;
import states.ModsMenuState;
import states.ModsMenuState.ModItem;
#if sys
import sys.io.File;
#end

@:access(states.ModsMenuState)
class ModsMenuHelpers
{
	public static function changeSelectedButton(state:ModsMenuState, add:Int = 0)
	{
		var max = state.buttons.length - 1;

		var button = ModsMenuHelpers.getButton(state);
		button.ignoreCheck = button.onFocus = false;

		state.curSelectedButton += add;
		if(state.curSelectedButton < -2)
			state.curSelectedButton = -2;
		else if(state.curSelectedButton > max)
			state.curSelectedButton = max;

		var button = ModsMenuHelpers.getButton(state);
		button.ignoreCheck = button.onFocus = true;

		var curMod:ModItem = state.modsGroup.members[state.curSelectedMod];
		if(curMod != null) curMod.selectBg.visible = false;
		if(state.curSelectedButton < 0)
		{
			state.bgButtons.color = FlxColor.BLACK;
			state.bgButtons.alpha = 0.2;
		}
		else
		{
			state.bgButtons.color = FlxColor.WHITE;
			state.bgButtons.alpha = 0.8;
		}

		FlxG.sound.play(Paths.sound('scrollMenu'), 0.6);
	}

	public static function getButton(state:ModsMenuState)
	{
		switch(state.curSelectedButton)
		{
			case -2: return state.buttonReload;
			case -1: return state.buttonEnableAll.enabled ? state.buttonEnableAll : state.buttonDisableAll;
		}

		if(state.modsList.all.length < 1) return state.buttonReload; //prevent possible crash from my irresponsibility
		return state.buttons[Std.int(Math.max(0, Math.min(state.buttons.length-1, state.curSelectedButton)))];
	}

	public static function changeSelectedMod(state:ModsMenuState, add:Int = 0, isMouseWheel:Bool = false)
	{
		var max = state.modsList.all.length - 1;
		if(max < 0) return;

		if(state.hoveringOnMods)
		{
			var button = ModsMenuHelpers.getButton(state);
			button.ignoreCheck = button.onFocus = false;
		}

		var lastSelected = state.curSelectedMod;
		state.curSelectedMod += add;

		var limited:Bool = false;
		if(state.curSelectedMod < 0)
		{
			state.curSelectedMod = 0;
			limited = true;
		}
		else if(state.curSelectedMod > max)
		{
			state.curSelectedMod = max;
			limited = true;
		}

		if(!isMouseWheel && limited && Math.abs(add) == 1)
		{
			if(add < 0) // pressed up on first mod
			{
				state.curSelectedMod = lastSelected;
				state.hoveringOnMods = false;
				state.curSelectedButton = -1;
				ModsMenuHelpers.changeSelectedButton(state);
				return;
			}
			else // pressed down on last mod
			{
				state.curSelectedMod = lastSelected;
				state.hoveringOnMods = false;
				state.curSelectedButton = -2;
				ModsMenuHelpers.changeSelectedButton(state);
				return;
			}
		}

		state.holdingMod = false;
		state.holdingElapsed = 0;
		state.gottaClickAgain = true;
		ModsMenuHelpers.updateModDisplayData(state);
		FlxG.sound.play(Paths.sound('scrollMenu'), 0.6);

		if(state.hoveringOnMods)
		{
			var curMod:ModItem = state.modsGroup.members[state.curSelectedMod];
			if(curMod != null) curMod.selectBg.visible = true;
			state.bgButtons.color = FlxColor.BLACK;
			state.bgButtons.alpha = 0.2;
		}
	}

	public static function updateModDisplayData(state:ModsMenuState)
	{
		var curMod:ModItem = state.modsGroup.members[state.curSelectedMod];
		if(curMod == null) return;

		if(state.colorTween != null)
		{
			state.colorTween.cancel();
			state.colorTween.destroy();
		}
		state.colorTween = FlxTween.color(state.bg, 1, state.bg.color, curMod.bgColor, {onComplete: function(twn:FlxTween) state.colorTween = null});

		if(Math.abs(state.centerMod - state.curSelectedMod) > 2)
		{
			if(state.centerMod < state.curSelectedMod)
				state.centerMod = state.curSelectedMod - 2;
			else state.centerMod = state.curSelectedMod + 2;
		}
		ModsMenuHelpers.updateItemPositions(state);

		state.icon.loadGraphic(curMod.icon.graphic, true, 150, 150);
		state.icon.antialiasing = curMod.icon.antialiasing;

		if(curMod.totalFrames > 0)
		{
			state.icon.animation.add("icon", [for (i in 0...curMod.totalFrames) i], curMod.iconFps);
			state.icon.animation.play("icon");
			state.icon.animation.curAnim.curFrame = curMod.icon.animation.curAnim.curFrame;
		}

		if(state.modName.scaleX != 0.8) state.modName.setScale(0.8);
		state.modName.text = curMod.name;
		var newScale = Math.min(620 / (state.modName.width / 0.8), 0.8);
		state.modName.setScale(newScale, Math.min(newScale * 1.35, 0.8));
		state.modName.y = state.modNameInitialY - (state.modName.height / 2);
		state.modRestartText.visible = curMod.mustRestart;
		state.modDesc.text = curMod.desc;

		for (button in state.buttons) if(button.focusChangeCallback != null) button.focusChangeCallback(button.onFocus);
	}

	public static function updateItemPositions(state:ModsMenuState)
	{
		var maxVisible = Math.max(4, state.centerMod + 2);
		var minVisible = Math.max(0, state.centerMod - 2);
		for (i => mod in state.modsGroup.members)
		{
			if(mod == null)
			{
				trace('Mod #$i is null, maybe it was ' + state.modsList.all[i]);
				continue;
			}

			mod.visible = (i >= minVisible && i <= maxVisible);
			mod.x = state.bgList.x + 5;
			mod.y = state.bgList.y + (86 * (i - state.centerMod + 2)) + 5;

			mod.alpha = 0.6;
			if(i == state.curSelectedMod) mod.alpha = 1;
			mod.selectBg.visible = (i == state.curSelectedMod && state.hoveringOnMods);
		}
	}

	public static function moveModToPosition(state:ModsMenuState, ?mod:String = null, position:Int = 0)
	{
		if(mod == null) mod = state.modsList.all[state.curSelectedMod];
		if(position >= state.modsList.all.length) position = 0;
		else if(position < 0) position = state.modsList.all.length-1;

		trace('Moved mod $mod to position $position');
		var id:Int = state.modsList.all.indexOf(mod);
		if(position == id) return;

		var curMod:ModItem = state.modsGroup.members[id];
		if(curMod == null) return;

		if(curMod.mustRestart || state.modsGroup.members[position].mustRestart) state.waitingToRestart = true;

		state.modsGroup.remove(curMod, true);
		state.modsList.all.remove(mod);
		state.modsGroup.insert(position, curMod);
		state.modsList.all.insert(position, mod);

		state.curSelectedMod = position;
		ModsMenuHelpers.updateModDisplayData(state);
		ModsMenuHelpers.updateItemPositions(state);

		if(!state.hoveringOnMods)
		{
			var curMod:ModItem = state.modsGroup.members[state.curSelectedMod];
			if(curMod != null) curMod.selectBg.visible = false;
		}
		FlxG.sound.play(Paths.sound('scrollMenu'), 0.6);
	}

	public static function checkToggleButtons(state:ModsMenuState)
	{
		state.buttonEnableAll.visible = state.buttonEnableAll.enabled = state.modsList.disabled.length > 0;
		state.buttonDisableAll.visible = state.buttonDisableAll.enabled = !state.buttonEnableAll.visible;
	}

	public static function reload(state:ModsMenuState)
	{
		ModsMenuHelpers.saveTxt(state);
		FlxG.autoPause = ClientPrefs.autoPause;
		FlxTransitionableState.skipNextTransIn = true;
		FlxTransitionableState.skipNextTransOut = true;
		var curMod:ModItem = state.modsGroup.members[state.curSelectedMod];
		LoadingState.loadAndSwitchState(() -> new ModsMenuState(curMod != null ? curMod.folder : null), false);
	}

	public static function saveTxt(state:ModsMenuState)
	{
		#if sys
		var fileStr:String = '';
		for (mod in state.modsList.all)
		{
			if(mod.trim().length < 1) continue;

			if(fileStr.length > 0) fileStr += '\n';

			var on = '1';
			if(state.modsList.disabled.contains(mod)) on = '0';
			fileStr += '$mod|$on';
		}

		var path:String = 'modsList.txt';
		File.saveContent(path, fileStr);
		#end
	}
}
#else
class ModsMenuHelpers
{
}
#end
