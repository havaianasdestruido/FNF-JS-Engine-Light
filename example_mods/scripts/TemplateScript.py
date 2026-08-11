# TemplateScript.py
# Drop this into mods/scripts/ (or any mod's scripts/ folder) and it will run
# on every song. Python modding works exactly like Lua modding: define
# top-level `def` callbacks and call the same engine functions.
#
# Callbacks with no `return` are treated as Function_Continue.
# You can return Function_Stop / Function_Continue / Function_StopAll.

def onCreate():
	# When the python file is started/created, some variables weren't created yet
	makeLuaSprite('myLittleSprite', '', 0, 0)
	makeGraphic('myLittleSprite', 64, 64, 'ff0000')
	setScrollFactor('myLittleSprite', 0, 0)
	setObjectCamera('myLittleSprite', 'hud')
	setProperty('myLittleSprite.alpha', 0.7)
	screenCenter('myLittleSprite')
	addLuaSprite('myLittleSprite', True)
	debugPrint('Python script loaded! (create)')

def onCreatePost():
	# End of "create", all variables have already been loaded, recommended.
	pass

def onDestroy():
	# When the python file is ended (Song fade out finished)
	pass

# Gameplay/Song interactions
def onBeatHit():
	# Triggered 4 times per section
	doTweenX('spriteX', 'myLittleSprite', 200, 0.5, 'sineOut')
	doTweenY('spriteY', 'myLittleSprite', 300, 0.5, 'sineOut')

def onStepHit():
	# Triggered 16 times per section
	pass

def onUpdate(elapsed):
	# Start of "update", some variables weren't updated yet
	pass

def onUpdatePost(elapsed):
	# End of "update"
	pass

def onStartCountdown():
	# Countdown started, duh
	# Return Function_Stop if you want to stop the countdown from happening
	return Function_Continue

def onCountdownTick(counter):
	# counter = 0 -> "Three", 1 -> "Two", 2 -> "One", 3 -> "Go!"
	pass

def onSongStart():
	# Inst and Vocals start playing, songPosition = 0
	pass

def onEndSong():
	# return Function_Stop to stop the song from ending
	return Function_Continue

# Substate interactions
def onPause():
	return Function_Continue

def onResume():
	pass

def onGameOver():
	return Function_Continue

def onGameOverConfirm(retry):
	# If you've pressed Esc, value "retry" will be False
	pass

# Note miss/hit
def goodNoteHit(id, direction, noteType, isSustainNote):
	# id: the note member id
	# direction: 0 = Left, 1 = Down, 2 = Up, 3 = Right
	# noteType: the note type string/tag
	# isSustainNote: True if it's a hold note
	pass

def opponentNoteHit(id, direction, noteType, isSustainNote):
	pass

def noteMissPress(direction):
	pass

def noteMiss(id, direction, noteType, isSustainNote):
	pass

# Event notes hooks
def onEvent(name, value1, value2):
	pass

def eventEarlyTrigger(name):
	pass

# Tween/Timer hooks
def onTweenCompleted(tag):
	pass

def onTimerCompleted(tag, loops, loopsLeft):
	pass
