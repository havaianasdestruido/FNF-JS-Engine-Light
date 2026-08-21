# BF Clicker - a pure-Python mod chart.
# Place this file at mods/bf-clicker/data/bf-clicker/bf-clicker.py and play
# the "bf-clicker" song from Freeplay. All gameplay logic lives here
# (Hython - no Lua). Click on BF as many times as you can in 45 seconds.
#
# Runs through the engine's PythonScript modding system.

# ---------------------------------------------------------------- //
#                     SETTINGS / MODULE STATE                      //
# (declared before any def so every callback shares the same refs) //
# ---------------------------------------------------------------- //
ROUND_TIME = 45.0

g_started = False
g_finished = False
g_clicks = 0
g_misses = 0
g_best = 0
g_baseY = 0.0
g_floatPhase = 0.0
g_lastShown = -1


# ---------------------------------------------------------------- //
#                              HELPERS                              //
# ---------------------------------------------------------------- //
def hideIfExists(target):
	# target is a dot-path like 'scoreTxt.visible'
	if getProperty(target) != None:
		setProperty(target, False)


# ---------------------------------------------------------------- //
#                              SETUP                              //
# ---------------------------------------------------------------- //
def onCreatePost():
	# hide the rhythm-game opponents
	setProperty('dad.visible', False)
	if getProperty('gf') != None:
		setProperty('gf.visible', False)

	# hide the rhythm-game HUD
	hideIfExists('scoreTxt.visible')
	hideIfExists('healthBar.visible')
	hideIfExists('healthBarBG.visible')
	hideIfExists('iconP1.visible')
	hideIfExists('iconP2.visible')
	hideIfExists('strumLineNotes.visible')
	hideIfExists('timeBar.visible')
	hideIfExists('timeBarBG.visible')
	hideIfExists('timeTxt.visible')
	hideIfExists('songName.visible')
	hideIfExists('comboGroup.visible')
	hideIfExists('ratingsGroup.visible')

	# giant BF right in the middle of the screen
	scaleObject('boyfriend', 2, 2, True)
	screenCenter('boyfriend')
	g_baseY = getProperty('boyfriend.y')

	# lock the camera onto the screen center
	setProperty('camFollow.x', getPropertyFromClass('flixel.FlxG', 'width') / 2)
	setProperty('camFollow.y', getPropertyFromClass('flixel.FlxG', 'height') / 2)
	setProperty('camFollowPos.x', getPropertyFromClass('flixel.FlxG', 'width') / 2)
	setProperty('camFollowPos.y', getPropertyFromClass('flixel.FlxG', 'height') / 2)

	# keep the background music quiet
	setPropertyFromClass('flixel.FlxG', 'sound.music.volume', 0.5)

	# HUD texts
	makeLuaText('clicksTxt', 'CLICKS: 0', 600, 0, 16)
	setTextAlignment('clicksTxt', 'center')
	setTextSize('clicksTxt', 42)
	setTextBorder('clicksTxt', 3, '000000')
	screenCenter('clicksTxt', 'x')

	makeLuaText('timeTxt2', 'GET READY!', 600, 0, 70)
	setTextAlignment('timeTxt2', 'center')
	setTextSize('timeTxt2', 30)
	setTextBorder('timeTxt2', 3, '000000')
	screenCenter('timeTxt2', 'x')

	makeLuaText('bestTxt', 'BEST: 0', 600, 0, 112)
	setTextAlignment('bestTxt', 'center')
	setTextSize('bestTxt', 24)
	setTextBorder('bestTxt', 3, '000000')
	screenCenter('bestTxt', 'x')

	makeLuaText('missTxt', 'MISSES: 0', 600, 0, 146)
	setTextAlignment('missTxt', 'center')
	setTextSize('missTxt', 22)
	setTextBorder('missTxt', 3, '000000')
	screenCenter('missTxt', 'x')

	makeLuaText('helpTxt', 'CLICK BF!', 600, 0, 620)
	setTextAlignment('helpTxt', 'center')
	setTextSize('helpTxt', 24)
	setTextBorder('helpTxt', 3, '000000')
	screenCenter('helpTxt', 'x')

	# show the mouse cursor for clicking
	setPropertyFromClass('flixel.FlxG', 'mouse.visible', True)

	# load the saved best score
	if getPropertyFromClass('flixel.FlxG', 'save.data.bfClickerBest') != None:
		g_best = int(getPropertyFromClass('flixel.FlxG', 'save.data.bfClickerBest'))
	else:
		g_best = 0
	setTextString('bestTxt', 'BEST: ' + str(g_best))


# ---------------------------------------------------------------- //
#                              FRAME                               //
# ---------------------------------------------------------------- //
def onUpdate(elapsed):
	if g_finished:
		return

	# keep the camera pinned to the center of the screen
	setProperty('camFollow.x', getPropertyFromClass('flixel.FlxG', 'width') / 2)
	setProperty('camFollow.y', getPropertyFromClass('flixel.FlxG', 'height') / 2)
	setProperty('camFollowPos.x', getPropertyFromClass('flixel.FlxG', 'width') / 2)
	setProperty('camFollowPos.y', getPropertyFromClass('flixel.FlxG', 'height') / 2)

	# gentle idle float so BF feels alive
	g_floatPhase = g_floatPhase + elapsed * 0.5
	if g_floatPhase >= 2.0:
		g_floatPhase = g_floatPhase - 2.0
	dy = 0.0
	if g_floatPhase < 1.0:
		dy = g_floatPhase * 10.0
	else:
		dy = (2.0 - g_floatPhase) * 10.0
	setProperty('boyfriend.y', g_baseY + dy)

	# round timer
	pos = getSongPosition()
	if pos >= 0:
		g_started = True

	if g_started:
		tLeft = ROUND_TIME - pos / 1000.0
		if tLeft < 0:
			tLeft = 0
		if int(tLeft) != g_lastShown:
			g_lastShown = int(tLeft)
			setTextString('timeTxt2', 'TIME: ' + str(g_lastShown))

	# clicking!
	if g_started and mouseClicked('left'):
		mx = getMouseX('hud')
		my = getMouseY('hud')
		bfx = getScreenPositionX('boyfriend')
		bfy = getScreenPositionY('boyfriend')
		bw = getProperty('boyfriend.width') * getProperty('boyfriend.scale.x') * 0.5
		bh = getProperty('boyfriend.height') * getProperty('boyfriend.scale.y') * 0.5
		if mx > bfx - bw and mx < bfx + bw and my > bfy - bh and my < bfy + bh:
			g_clicks = g_clicks + 1
			addScore(1)
			setTextString('clicksTxt', 'CLICKS: ' + str(g_clicks))
			if g_clicks > g_best:
				setTextString('bestTxt', 'BEST: ' + str(g_clicks) + ' (LIVE!)')
			else:
				setTextString('bestTxt', 'BEST: ' + str(g_best))
			playAnim('boyfriend', 'singUP', True)
			setProperty('boyfriend.scale.x', 2.35)
			setProperty('boyfriend.scale.y', 2.35)
			playSound('clickText', 0.6)
		else:
			g_misses = g_misses + 1
			setTextString('missTxt', 'MISSES: ' + str(g_misses))
			playSound('cancelMenu', 0.5)

	# ease the click-bounce back down to 2x
	sc = getProperty('boyfriend.scale.x')
	if sc > 2.0:
		nsc = sc - (sc - 2.0) * 0.2
		if nsc < 2.0:
			nsc = 2.0
		setProperty('boyfriend.scale.x', nsc)
		setProperty('boyfriend.scale.y', nsc)

	# time's up! wrap up the round
	if g_started and g_lastShown <= 0 and pos >= ROUND_TIME * 1000.0:
		g_finished = True
		setTextString('timeTxt2', 'TIME UP!')
		if g_clicks > g_best:
			g_best = g_clicks
			setPropertyFromClass('flixel.FlxG', 'save.data.bfClickerBest', g_best)
		setTextString('bestTxt', 'BEST: ' + str(g_best))
		endSong()


# ---------------------------------------------------------------- //
#                             CLEANUP                              //
# ---------------------------------------------------------------- //
def onDestroy():
	# keep the best score even if the player leaves mid-round
	if g_clicks > g_best:
		g_best = g_clicks
		setPropertyFromClass('flixel.FlxG', 'save.data.bfClickerBest', g_best)
	setPropertyFromClass('flixel.FlxG', 'mouse.visible', False)
