package states.helpers;

// REFACTOR: gameplay option plumbing extracted from states.substates.GameplayChangersSubstate (behavior-preserving)
import backend.Paths;
import objects.Alphabet;
import objects.AttachedText;
import objects.CheckboxThingie;
import play.PlayState;
import states.substates.GameplayChangersSubstate;
import states.substates.GameplayChangersSubstate.GameplayOption;
import states.substates.PauseSubState;

@:access(states.substates.GameplayChangersSubstate)
class GameplayChangersHelpers
{
	public static function getOptions(state:GameplayChangersSubstate)
	{
		var skip:Bool = GameplayChangersSubstate.inThePauseMenu;

		var goption:GameplayOption = new GameplayOption('Scroll Type', 'scrolltype', 'string', 'multiplicative', ["multiplicative", "constant"]);
		state.optionsArray.push(goption);

		var option:GameplayOption = new GameplayOption('Scroll Speed', 'scrollspeed', 'float', 1);
		option.scrollSpeed = 2.0;
		option.minValue = 0.35;
		option.changeValue = 0.05;
		option.slowChangeVal = 0.01;
		option.decimals = 2;
		if (goption.getValue() != "constant")
		{
			option.displayFormat = '%vX';
			option.maxValue = 128;
		}
		else
		{
			option.displayFormat = "%v";
			option.maxValue = 1024;
		}
		state.optionsArray.push(option);

		#if !html5
		var option:GameplayOption = new GameplayOption('Playback Rate', 'songspeed', 'float', 1);
		option.scrollSpeed = 3;
		option.minValue = 0.01;
		option.maxValue = 100;
		option.changeValue = 0.05;
		option.slowChangeVal = 0.01;
		option.displayFormat = '%vX';
		option.decimals = 2;
		state.optionsArray.push(option);
		#end

		var option:GameplayOption = new GameplayOption('Health Gain Multiplier', 'healthgain', 'float', 1);
		option.scrollSpeed = 5;
		option.minValue = -1;
		option.maxValue = 50;
		option.changeValue = 0.1;
		option.slowChangeVal = 0.01;
		option.decimals = 3;
		option.displayFormat = '%vX';
		state.optionsArray.push(option);

		var option:GameplayOption = new GameplayOption('Health Loss Multiplier', 'healthloss', 'float', 1);
		option.scrollSpeed = 2.5;
		option.minValue = -1;
		option.maxValue = 50;
		option.changeValue = 0.1;
		option.slowChangeVal = 0.01;
		option.decimals = 3;
		option.displayFormat = '%vX';
		state.optionsArray.push(option);

		var option:GameplayOption = new GameplayOption('Instakill on Miss', 'instakill', 'bool', false);
		state.optionsArray.push(option);

		var option:GameplayOption = new GameplayOption('Sicks Only', 'onlySicks', 'bool', false);
		state.optionsArray.push(option);

		var option:GameplayOption = new GameplayOption('Practice Mode', 'practice', 'bool', false);
		state.optionsArray.push(option);
		option.onChange = function() { onChangeCheat(state); };

		var option:GameplayOption = new GameplayOption('Botplay', 'botplay', 'bool', false);
		state.optionsArray.push(option);
		option.onChange = function() { onChangeCheat(state); };

		var option:GameplayOption = new GameplayOption('Play as Opponent', 'opponentplay', 'bool', false);
		option.onChange = function() { onChangeChartOption(state); };
		state.optionsArray.push(option);

		var option:GameplayOption = new GameplayOption('Play Both Sides', 'bothsides', 'bool', false);
		option.onChange = function() { onChangeChartOption(state); };
		state.optionsArray.push(option);

		var option:GameplayOption = new GameplayOption('Opponent Health Drain', 'opponentdrain', 'bool', false);
		state.optionsArray.push(option);

		var option:GameplayOption = new GameplayOption('Health Drain Level: ', 'drainlevel', 'float', 1);
		option.scrollSpeed = 2;
		option.minValue = -1;
		option.maxValue = 10;
		option.changeValue = 0.1;
		option.slowChangeVal = 0.01;
		option.displayFormat = '%vX';
		state.optionsArray.push(option);

		var option:GameplayOption = new GameplayOption('Random Mode', 'randommode', 'bool', false);
		option.onChange = function() { onChangeChartOption(state); };
		state.optionsArray.push(option);

		var option:GameplayOption = new GameplayOption('Stair Mode', 'stairmode', 'bool', false);
		option.onChange = function() { onChangeChartOption(state); };
		state.optionsArray.push(option);

		var option:GameplayOption = new GameplayOption('Wave Mode', 'wavemode', 'bool', false);
		option.onChange = function() { onChangeChartOption(state); };
		state.optionsArray.push(option);

		var option:GameplayOption = new GameplayOption('Flip Mode', 'flip', 'bool', false);
		option.onChange = function() { onChangeChartOption(state); };
		state.optionsArray.push(option);

		var option:GameplayOption = new GameplayOption('One Key', 'onekey', 'bool', false);
		option.onChange = function() { onChangeChartOption(state); };
		state.optionsArray.push(option);

		var option:GameplayOption = new GameplayOption('Jack Amount: ', 'jacks', 'int', 0);
		option.onChange = function() { onChangeChartOption(state); };
		option.scrollSpeed = 6;
		option.minValue = 0;
		option.maxValue = 100;
		option.changeValue = 1;
		option.slowChangeVal = 1;
		option.displayFormat = '%v';
		state.optionsArray.push(option);

		var option:GameplayOption = new GameplayOption('Random Playback Rate', 'randomspeed', 'bool', false);
		option.onChange = function() { onChangeChartOption(state); };
		state.optionsArray.push(option);

		var option:GameplayOption = new GameplayOption('Minimum Speed', 'randomspeedmin', 'float', 0.5);
		option.scrollSpeed = 0.5;
		option.minValue = 0.1;
		option.maxValue = 1;
		option.changeValue = 0.05;
		option.slowChangeVal = 0.01;
		option.displayFormat = '%v';
		option.decimals = 2;
		state.optionsArray.push(option);

		var option:GameplayOption = new GameplayOption('Max Speed', 'randomspeedmax', 'float', 2);
		option.scrollSpeed = 0.5;
		option.minValue = 1;
		option.maxValue = 10;
		option.changeValue = 0.05;
		option.slowChangeVal = 0.01;
		option.displayFormat = '%v';
		option.decimals = 2;
		state.optionsArray.push(option);

		var option:GameplayOption = new GameplayOption('Troll Mode', 'thetrollingever', 'bool', false);
		option.onChange = function() { onChangeChartOption(state); };
		state.optionsArray.push(option);
	}

	public static function getOptionByName(state:GameplayChangersSubstate, name:String)
	{
		for(i in state.optionsArray)
		{
			var opt:GameplayOption = i;
			if (opt.name == name)
				return opt;
		}
		return null;
	}

	public static function updateTextFrom(option:GameplayOption) {
		var text:String = option.displayFormat;
		var val:Dynamic = option.getValue();
		if(option.type == 'percent') val *= 100;
		var def:Dynamic = option.defaultValue;
		option.text = text.replace('%v', val).replace('%d', def);
	}

	public static function clearHold(state:GameplayChangersSubstate)
	{
		if(state.holdTime > 0.5) {
			FlxG.sound.play(Paths.sound('scrollMenu'));
		}
		state.holdTime = 0;
	}

	public static function onChangeChartOption(state:GameplayChangersSubstate)
	{
		if(GameplayChangersSubstate.inThePauseMenu)
		{
			trace ("HEY! You changed an option that requires a chart restart!");
			PauseSubState.requireRestart = true;
		}
	}
	public static function onChangeCheat(state:GameplayChangersSubstate)
	{
		if(GameplayChangersSubstate.inThePauseMenu)
		{
			trace ("you really thought you would get away with it, invalidated your score");
			PlayState.playerIsCheating = true;
		}
	}

	public static function changeSelection(state:GameplayChangersSubstate, change:Int = 0)
	{
		state.curSelected += change;
		if (state.curSelected < 0)
			state.curSelected = state.optionsArray.length - 1;
		if (state.curSelected >= state.optionsArray.length)
			state.curSelected = 0;

		var bullShit:Int = 0;

		for (item in state.grpOptions.members) {
			item.targetY = bullShit - state.curSelected;
			bullShit++;

			item.alpha = 0.6;
			if (item.targetY == 0) {
				item.alpha = 1;
			}
		}
		for (text in state.grpTexts) {
			text.alpha = 0.6;
			if(text.ID == state.curSelected) {
				text.alpha = 1;
			}
		}
		state.curOption = state.optionsArray[state.curSelected]; //shorter lol
		FlxG.sound.play(Paths.sound('scrollMenu'));
	}

	public static function reloadCheckboxes(state:GameplayChangersSubstate) {
		for (checkbox in state.checkboxGroup) {
			checkbox.daValue = (state.optionsArray[checkbox.ID].getValue() == true);
		}
	}
}
