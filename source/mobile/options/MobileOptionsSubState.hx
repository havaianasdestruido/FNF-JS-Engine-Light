/*
 * Copyright (C) 2025 Mobile Porting Team
 *
 * Permission is hereby granted, free of charge, to any person obtaining a
 * copy of this software and associated documentation files (the "Software"),
 * to deal in the Software without restriction, including without limitation
 * the rights to use, copy, modify, merge, publish, distribute, sublicense,
 * and/or sell copies of the Software, and to permit persons to whom the
 * Software is furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
 * FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
 * DEALINGS IN THE SOFTWARE.
 */


package mobile.options;

import options.BaseOptionsMenu;
import options.Option;
#if sys
import sys.io.File;
#end
import flixel.FlxG;
import flixel.input.keyboard.FlxKey;

class MobileOptionsSubState extends BaseOptionsMenu
{
	final hintOptions:Array<String> = ["No Gradient", "No Gradient (Old)", "Gradient", "Hidden"];

	public function new()
	{
		title = 'Mobile Options';
		rpcTitle = 'Mobile Options Menu'; // for Discord Rich Presence, fuck it

		var option:Option = new Option('Extra Controls',
		'If checked, extra ${MobileControls.mode == "Hitbox" ? 'hint' : 'button'} to simulate pressing the space bar will be enabled.',
		'mobileCEx',
		'bool',
		false);
		addOption(option);

		var option:Option = new Option('Taunt on Extra Controls',
		'If checked, when you press to extra ${MobileControls.mode == "Hitbox" ? 'hint' : 'button'} bf will be taunt.',
		'mobileCExTaunt',
		'bool',
		true);
		addOption(option);

		var option:Option = new Option('Mobile Controls Opacity',
		'Selects the opacity for the mobile buttons (be careful not to put it at 0 and lose track of your buttons).',
		'mobileCAlpha',
		'percent',
		null);
		option.scrollSpeed = 1;
		option.minValue = 0.0;
		option.maxValue = 1;
		option.changeValue = 0.1;
		option.decimals = 1;
		option.onChange = () ->
		{
			virtualPad.alpha = 0; // what? that fixed somehow
			virtualPad.alpha = curOption.getValue();
			if (MobileControls.enabled) {
				TitleState.volumeUpKeys = FlxG.sound.volumeUpKeys = [];
				TitleState.volumeDownKeys = FlxG.sound.volumeDownKeys = [];
				TitleState.muteKeys = FlxG.sound.muteKeys = [];
			} else {
				TitleState.volumeUpKeys = FlxG.sound.volumeUpKeys = [FlxKey.PLUS, FlxKey.NUMPADPLUS];
				TitleState.volumeDownKeys = FlxG.sound.volumeDownKeys = [FlxKey.MINUS, FlxKey.NUMPADMINUS];
				TitleState.muteKeys = FlxG.sound.muteKeys = [FlxKey.ZERO, FlxKey.NUMPADZERO];
			}
		};
		addOption(option);

		#if mobile
		var option:Option = new Option('Allow Phone Screensaver',
		'If checked, the phone will go sleep after going inactive for few seconds.\n(The time depends on your phone\'s options)',
		'screensaver',
		'bool',
		false);
		option.onChange = () -> lime.system.System.allowScreenTimeout = curOption.getValue();
		addOption(option);
		#end

		if (MobileControls.mode == "Hitbox")
		{
			var option:Option = new Option('Hitbox Design',
			'Choose how your hitbox should look like.',
			'hitboxType',
			'string',
			null,
			hintOptions);
			addOption(option);

			var option:Option = new Option('Hitbox Position',
			'If checked, the hitbox will be put at the bottom of the screen, otherwise will stay at the top.',
			'hitboxPos',
			'bool',
			true);
			addOption(option);
		}

		cameras = [FlxG.cameras.list[FlxG.cameras.list.length-1]];

		super();
	}
}
