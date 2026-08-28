package editors.helpers;

// REFACTOR: explicit imports for relocated root classes
import backend.Paths;

import backend.DiscordClient;
import backend.WeekData;
import editors.WeekEditorState;
import flixel.addons.ui.FlxUI;
import flixel.addons.ui.FlxUICheckBox;
import flixel.addons.ui.FlxUIInputText;
import flixel.FlxG;
import flixel.text.FlxText;
import flixel.util.FlxAxes.X;
import haxe.Json;
import lime.utils.Assets;
import openfl.events.Event;
import openfl.events.IOErrorEvent;
import openfl.net.FileFilter;
import openfl.net.FileReference;
import sys.io.File;

// REFACTOR: extracted from editors.WeekEditorState (behavior-preserving)
@:access(editors.WeekEditorState)
class WeekEditorHelpers
{
	public static function addWeekUI(state:WeekEditorState):Void
	{
		var tab_group = new FlxUI(null, state.UI_box);
		tab_group.name = "Week";

		state.songsInputText = new FlxUIInputText(10, 30, 200, '', 8);
		state.blockPressWhileTypingOn.push(state.songsInputText);
		state.songsInputText.focusGained = () -> FlxG.stage.window.textInputEnabled = true;

		state.opponentInputText = new FlxUIInputText(10, state.songsInputText.y + 40, 70, '', 8);
		state.blockPressWhileTypingOn.push(state.opponentInputText);
		state.opponentInputText.focusGained = () -> FlxG.stage.window.textInputEnabled = true;
		state.boyfriendInputText = new FlxUIInputText(state.opponentInputText.x + 75, state.opponentInputText.y, 70, '', 8);
		state.blockPressWhileTypingOn.push(state.boyfriendInputText);
		state.boyfriendInputText.focusGained = () -> FlxG.stage.window.textInputEnabled = true;
		state.girlfriendInputText = new FlxUIInputText(state.boyfriendInputText.x + 75, state.opponentInputText.y, 70, '', 8);
		state.blockPressWhileTypingOn.push(state.girlfriendInputText);
		state.girlfriendInputText.focusGained = () -> FlxG.stage.window.textInputEnabled = true;

		state.backgroundInputText = new FlxUIInputText(10, state.opponentInputText.y + 40, 120, '', 8);
		state.blockPressWhileTypingOn.push(state.backgroundInputText);
		state.backgroundInputText.focusGained = () -> FlxG.stage.window.textInputEnabled = true;

		state.displayNameInputText = new FlxUIInputText(10, state.backgroundInputText.y + 60, 200, '', 8);
		state.blockPressWhileTypingOn.push(state.backgroundInputText);
		state.displayNameInputText.focusGained = () -> FlxG.stage.window.textInputEnabled = true;

		state.weekNameInputText = new FlxUIInputText(10, state.displayNameInputText.y + 60, 150, '', 8);
		state.blockPressWhileTypingOn.push(state.weekNameInputText);
		state.weekNameInputText.focusGained = () -> FlxG.stage.window.textInputEnabled = true;

		state.weekFileInputText = new FlxUIInputText(10, state.weekNameInputText.y + 40, 100, '', 8);
		state.blockPressWhileTypingOn.push(state.weekFileInputText);
		state.weekFileInputText.focusGained = () -> FlxG.stage.window.textInputEnabled = true;
		reloadWeekThing(state);

		state.hideCheckbox = new FlxUICheckBox(10, state.weekFileInputText.y + 40, null, null, "Hide Week from Story Mode?", 100);
		state.hideCheckbox.callback = function()
		{
			state.weekFile.hideStoryMode = state.hideCheckbox.checked;
		};

		tab_group.add(new FlxText(state.songsInputText.x, state.songsInputText.y - 18, 0, 'Songs:'));
		tab_group.add(new FlxText(state.opponentInputText.x, state.opponentInputText.y - 18, 0, 'Characters:'));
		tab_group.add(new FlxText(state.backgroundInputText.x, state.backgroundInputText.y - 18, 0, 'Background Asset:'));
		tab_group.add(new FlxText(state.displayNameInputText.x, state.displayNameInputText.y - 18, 0, 'Display Name:'));
		tab_group.add(new FlxText(state.weekNameInputText.x, state.weekNameInputText.y - 18, 0, 'Week Name (for Reset Score Menu):'));
		tab_group.add(new FlxText(state.weekFileInputText.x, state.weekFileInputText.y - 18, 0, 'Week File:'));

		tab_group.add(state.songsInputText);
		tab_group.add(state.opponentInputText);
		tab_group.add(state.boyfriendInputText);
		tab_group.add(state.girlfriendInputText);
		tab_group.add(state.backgroundInputText);

		tab_group.add(state.displayNameInputText);
		tab_group.add(state.weekNameInputText);
		tab_group.add(state.weekFileInputText);
		tab_group.add(state.hideCheckbox);
		state.UI_box.addGroup(tab_group);
	}

	public static function addOtherUI(state:WeekEditorState):Void
	{
		var tab_group = new FlxUI(null, state.UI_box);
		tab_group.name = "Other";

		state.lockedCheckbox = new FlxUICheckBox(10, 30, null, null, "Week starts Locked", 100);
		state.lockedCheckbox.callback = function()
		{
			state.weekFile.startUnlocked = !state.lockedCheckbox.checked;
			state.lock.visible = state.lockedCheckbox.checked;
			state.hiddenUntilUnlockCheckbox.alpha = 0.4 + 0.6 * (state.lockedCheckbox.checked ? 1 : 0);
		};

		state.hiddenUntilUnlockCheckbox = new FlxUICheckBox(10, state.lockedCheckbox.y + 25, null, null, "Hidden until Unlocked", 110);
		state.hiddenUntilUnlockCheckbox.callback = function()
		{
			state.weekFile.hiddenUntilUnlocked = state.hiddenUntilUnlockCheckbox.checked;
		};
		state.hiddenUntilUnlockCheckbox.alpha = 0.4;

		state.weekBeforeInputText = new FlxUIInputText(10, state.hiddenUntilUnlockCheckbox.y + 55, 100, '', 8);
		state.blockPressWhileTypingOn.push(state.weekBeforeInputText);
		state.weekBeforeInputText.focusGained = () -> FlxG.stage.window.textInputEnabled = true;

		state.difficultiesInputText = new FlxUIInputText(10, state.weekBeforeInputText.y + 60, 200, '', 8);
		state.blockPressWhileTypingOn.push(state.difficultiesInputText);
		state.difficultiesInputText.focusGained = () -> FlxG.stage.window.textInputEnabled = true;

		tab_group.add(new FlxText(state.weekBeforeInputText.x, state.weekBeforeInputText.y - 28, 0, 'Week File name of the Week you have\nto finish for Unlocking:'));
		tab_group.add(new FlxText(state.difficultiesInputText.x, state.difficultiesInputText.y - 20, 0, 'Difficulties:'));
		tab_group.add(new FlxText(state.difficultiesInputText.x, state.difficultiesInputText.y + 20, 0, 'Default difficulties are "Easy, Normal, Hard"\nwithout quotes.'));
		tab_group.add(state.weekBeforeInputText);
		tab_group.add(state.difficultiesInputText);
		tab_group.add(state.hiddenUntilUnlockCheckbox);
		tab_group.add(state.lockedCheckbox);
		state.UI_box.addGroup(tab_group);
	}

	//Used on onCreate and when you load a week
	public static function reloadAllShit(state:WeekEditorState):Void
	{
		var weekString:String = state.weekFile.songs[0][0];
		for (i in 1...state.weekFile.songs.length) {
			weekString += ', ' + state.weekFile.songs[i][0];
		}
		state.songsInputText.text = weekString;
		state.backgroundInputText.text = state.weekFile.weekBackground;
		state.displayNameInputText.text = state.weekFile.storyName;
		state.weekNameInputText.text = state.weekFile.weekName;
		state.weekFileInputText.text = WeekEditorState.weekFileName;

		state.opponentInputText.text = state.weekFile.weekCharacters[0];
		state.boyfriendInputText.text = state.weekFile.weekCharacters[1];
		state.girlfriendInputText.text = state.weekFile.weekCharacters[2];

		state.hideCheckbox.checked = state.weekFile.hideStoryMode;

		state.weekBeforeInputText.text = state.weekFile.weekBefore;

		state.difficultiesInputText.text = '';
		if(state.weekFile.difficulties != null) state.difficultiesInputText.text = state.weekFile.difficulties;

		state.lockedCheckbox.checked = !state.weekFile.startUnlocked;
		state.lock.visible = state.lockedCheckbox.checked;

		state.hiddenUntilUnlockCheckbox.checked = state.weekFile.hiddenUntilUnlocked;
		state.hiddenUntilUnlockCheckbox.alpha = 0.4 + 0.6 * (state.lockedCheckbox.checked ? 1 : 0);

		reloadBG(state);
		reloadWeekThing(state);
		updateText(state);
	}

	public static function updateText(state:WeekEditorState):Void
	{
		for (i in 0...state.grpWeekCharacters.length) {
			state.grpWeekCharacters.members[i].changeCharacter(state.weekFile.weekCharacters[i]);
		}

		var stringThing:Array<String> = [];
		for (i in 0...state.weekFile.songs.length) {
			stringThing.push(state.weekFile.songs[i][0]);
		}

		state.txtTracklist.text = '';
		for (i in 0...stringThing.length)
		{
			state.txtTracklist.text += stringThing[i] + '\n';
		}

		state.txtTracklist.text = state.txtTracklist.text.toUpperCase();

		state.txtTracklist.screenCenter(X);
		state.txtTracklist.x -= FlxG.width * 0.35;

		state.txtWeekTitle.text = state.weekFile.storyName.toUpperCase();
		state.txtWeekTitle.x = FlxG.width - (state.txtWeekTitle.width + 10);
	}

	public static function reloadBG(state:WeekEditorState):Void
	{
		state.bgSprite.visible = true;
		var assetName:String = state.weekFile.weekBackground;

		var isMissing:Bool = true;
		if(assetName != null && assetName.length > 0) {
			if(#if MODS_ALLOWED FileSystem.exists(Paths.modsImages('menubackgrounds/menu_' + assetName)) || #end
			Assets.exists(Paths.getPath('images/menubackgrounds/menu_' + assetName + '.png', IMAGE), IMAGE)) {
				state.bgSprite.loadGraphic(Paths.image('menubackgrounds/menu_' + assetName));
				isMissing = false;
			}
		}

		if(isMissing) {
			state.bgSprite.visible = false;
		}
	}

	public static function reloadWeekThing(state:WeekEditorState):Void
	{
		state.weekThing.visible = true;
		state.missingFileText.visible = false;
		var assetName:String = state.weekFileInputText.text.trim();

		var isMissing:Bool = true;
		if(assetName != null && assetName.length > 0) {
			if( #if MODS_ALLOWED FileSystem.exists(Paths.modsImages('storymenu/' + assetName)) || #end
			Assets.exists(Paths.getPath('images/storymenu/' + assetName + '.png', IMAGE), IMAGE)) {
				state.weekThing.loadGraphic(Paths.image('storymenu/' + assetName));
				isMissing = false;
			}
		}

		if(isMissing) {
			state.weekThing.visible = false;
			state.missingFileText.visible = true;
			state.missingFileText.text = 'MISSING FILE: images/storymenu/' + assetName + '.png';
		}
		recalculateStuffPosition(state);

		#if DISCORD_ALLOWED
		// Updating Discord Rich Presence
		DiscordClient.changePresence("Week Editor", "Editting: " + WeekEditorState.weekFileName);
		#end
	}

	public static function recalculateStuffPosition(state:WeekEditorState):Void
	{
		state.weekThing.screenCenter(X);
		state.lock.x = state.weekThing.width + 10 + state.weekThing.x;
	}

	public static function loadWeek():Void
	{
		var jsonFilter:FileFilter = new FileFilter('JSON', 'json');
		WeekEditorState._file = new FileReference();
		WeekEditorState._file.addEventListener(Event.SELECT, onLoadComplete);
		WeekEditorState._file.addEventListener(Event.CANCEL, onLoadCancel);
		WeekEditorState._file.addEventListener(IOErrorEvent.IO_ERROR, onLoadError);
		WeekEditorState._file.browse([jsonFilter]);
	}

	public static function onLoadComplete(_):Void
	{
		WeekEditorState._file.removeEventListener(Event.SELECT, onLoadComplete);
		WeekEditorState._file.removeEventListener(Event.CANCEL, onLoadCancel);
		WeekEditorState._file.removeEventListener(IOErrorEvent.IO_ERROR, onLoadError);

		#if sys
		var fullPath:String = null;
		@:privateAccess
		if(WeekEditorState._file.__path != null) fullPath = WeekEditorState._file.__path;

		if(fullPath != null) {
			var rawJson:String = File.getContent(fullPath);
			if(rawJson != null) {
				WeekEditorState.loadedWeek = cast Json.parse(rawJson);
				if(WeekEditorState.loadedWeek.weekCharacters != null && WeekEditorState.loadedWeek.weekName != null) //Make sure it's really a week
				{
					var cutName:String = WeekEditorState._file.name.substr(0, WeekEditorState._file.name.length - 5);
					trace("Successfully loaded file: " + cutName);
					WeekEditorState.loadError = false;

					WeekEditorState.weekFileName = cutName;
					WeekEditorState._file = null;
					return;
				}
			}
		}
		WeekEditorState.loadError = true;
		WeekEditorState.loadedWeek = null;
		WeekEditorState._file = null;
		#else
		trace("File couldn't be loaded! You aren't on Desktop, are you?");
		#end
	}

	/**
		* Called when the save file dialog is cancelled.
		*/
	public static function onLoadCancel(_):Void
	{
		WeekEditorState._file.removeEventListener(Event.SELECT, onLoadComplete);
		WeekEditorState._file.removeEventListener(Event.CANCEL, onLoadCancel);
		WeekEditorState._file.removeEventListener(IOErrorEvent.IO_ERROR, onLoadError);
		WeekEditorState._file = null;
		trace("Cancelled file loading.");
	}

	/**
		* Called if there is an error while saving the gameplay recording.
		*/
	public static function onLoadError(_):Void
	{
		WeekEditorState._file.removeEventListener(Event.SELECT, onLoadComplete);
		WeekEditorState._file.removeEventListener(Event.CANCEL, onLoadCancel);
		WeekEditorState._file.removeEventListener(IOErrorEvent.IO_ERROR, onLoadError);
		WeekEditorState._file = null;
		trace("Problem loading file");
	}

	public static function saveWeek(weekFile:WeekFile):Void
	{
		var data:String = Json.stringify(weekFile, "\t");
		if (data.length > 0)
		{
			WeekEditorState._file = new FileReference();
			WeekEditorState._file.addEventListener(Event.COMPLETE, onSaveComplete);
			WeekEditorState._file.addEventListener(Event.CANCEL, onSaveCancel);
			WeekEditorState._file.addEventListener(IOErrorEvent.IO_ERROR, onSaveError);
			WeekEditorState._file.save(data, WeekEditorState.weekFileName + ".json");
		}
	}

	public static function onSaveComplete(_):Void
	{
		WeekEditorState._file.removeEventListener(Event.COMPLETE, onSaveComplete);
		WeekEditorState._file.removeEventListener(Event.CANCEL, onSaveCancel);
		WeekEditorState._file.removeEventListener(IOErrorEvent.IO_ERROR, onSaveError);
		WeekEditorState._file = null;
		FlxG.log.notice("Successfully saved file.");
	}

	/**
		* Called when the save file dialog is cancelled.
		*/
	public static function onSaveCancel(_):Void
	{
		WeekEditorState._file.removeEventListener(Event.COMPLETE, onSaveComplete);
		WeekEditorState._file.removeEventListener(Event.CANCEL, onSaveCancel);
		WeekEditorState._file.removeEventListener(IOErrorEvent.IO_ERROR, onSaveError);
		WeekEditorState._file = null;
	}

	/**
		* Called if there is an error while saving the gameplay recording.
		*/
	public static function onSaveError(_):Void
	{
		WeekEditorState._file.removeEventListener(Event.COMPLETE, onSaveComplete);
		WeekEditorState._file.removeEventListener(Event.CANCEL, onSaveCancel);
		WeekEditorState._file.removeEventListener(IOErrorEvent.IO_ERROR, onSaveError);
		WeekEditorState._file = null;
		FlxG.log.error("Problem saving file");
	}
}
