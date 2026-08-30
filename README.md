<h1 align="center">
  <br>
  <a href="https://github.com/havaianasdestruido/FNF-JS-Engine-Light"><img src="/art/iconOG.png" alt="JSengine" width="150"></a>
  <br>
  <b>Phoenix Engine</b>
  <br>
  <i>(Jordan Santiago Engine, with a bunch of new stuff)</i>
  <br>
</h1>
<h3 align="center">
  <b>Phoenix Engine is an enhanced fork of JSE, which in turn is a fork of Psych but with performance-related additions.</b>
</h3>

<b>IMPORTANT: if you want to clone the repo (for making a pull request or for building locally), use <code>git clone -b main --single-branch https://github.com/havaianasdestruido/FNF-Phoenix-Engine.git</code> so you only git clone _only the main branch_, the other ones are for experiments or are extremely old.</b>

<p align="center">
<img alt="GitHub repo size" src="https://img.shields.io/github/repo-size/havaianasdestruido/FNF-Phoenix-Engine">
<img alt="GitHub commit activity" src="https://img.shields.io/github/commit-activity/w/havaianasdestruido/FNF-Phoenix-Engine">
<img alt="GitHub contributors" src="https://img.shields.io/github/contributors/havaianasdestruido/FNF-Phoenix-Engine">
</p>

Phoenix Engine focuses on making both Hardmodding (Hardcoded mods) *AND* Softmodding (mods you place on `mods/` folder) easier.

Phoenix Engine currently has those additions (and more!) that vanilla JSE (Jordan Santiago Engine) doesn't:

## **Major Categories of Changes:**

### **1. Performance Optimizations**
- **HScript AST Caching**: Cache parsed AST to avoid re-parsing (bottleneck)
- **FunkinLua Optimization**: Cache missing calls and fast-path variable splitting
- **Convert Function**: Direct-call bridge for 0-8 args
- **PlayState Note Iteration**: Batch note iteration and inline key arrays
- **Alphabet Caching**: Cache sparrow atlases and skip duplicate animations
- **ChartingState**: Cache grid layer/waveform buffers, dedupe undo
- **Options Performance**: Throttle option text updates and guard score redraw
- **FPS Counter**: Cache PlayState check and throttle outline redraw

### **2. Code Refactoring & Architecture**
- **Modding System Rewrite**: Switched to cleaner Mods backend (0.7 style)
- **Source Tree Reorganization**: Split into packages (`backend/`, `states/`, `play/`, `objects/`, `data/`, `shaders/`, `psychlua/`)
- **Large File Splits**:
  - PlayState: 6448 → 3313 lines
  - ChartingState: 4821 → 2367 lines
  - FunkinLua: 3455 → 807 lines
- **GameOverSubstate Refactor**: Generic fallback + safer null handling
- **Stage Loading Centralization**: Created StageData.vanillaSongStage mapping
- **MS/Judge Text Popups**: Refactored into separate classes

### **3. Python Scripting Support**
- **Hython Integration**: Pure-Haxe Python interpreter
- **Mirrors Lua System**: Same callbacks/API as Lua scripts
- Supports `-DMODDING_LEVEL` flag for enable/disable

### **4. Build System & Compilation**
- **Windows MSVC Fixes**: Assembler support, C++17 flag handling
- **GitHub Actions Cache**: Proper `HXCPP_COMPILE_CACHE` detection
- **Platform-Specific Code**: Centralized in PlatformUtilNative.hx

### **5. Platform Support Improvements**
- **Linux GameMode**: Proper support with feature flags
- **Windows Console**: SetProcessDPIAware, DisableProcessWindowsGhosting
- **Fullscreen Handling**: Centralized F11 toggle in FunkinGame backend
- **Mac/iOS Headers**: Proper sys/utsname.h includes

### **6. Asset Management**
- **Audio Compression**: OGG/MP3 files (~50% size reduction)
- **JSON Minification**: Across entire codebase
- **Image Compression**: Lossy but invisible optimization
- **Character Icon Refresh**: Updated multiple icon PNGs
- **BF Clicker _(WIP Python testing  sample)_ Mod**: Shipped as example mod
- **Shader Embedding**: Runtime shaders (pulseEffect.frag → RuntimeShaders.hx)

### **7. Bug Fixes**
- **UTF-8 BOM Handling**: Strip BOM from JSON reads
- **defaultCamZoom Crashes**: More fixes for camera zoom behavior
- **Sustain Note Issues**: Fixed missing sustain notes if no BPM changes
- **GameOver Music Loop**: Fixed repeated triggering every frame
- **ControlsSubstate Crash**: Alt fix for crash issues
- **Scared Animations**: Fix Week 2 animation forcing
- **Time Bar Updating**: Proper time position calculation

### **8. Feature Additions**
- **Camera Zoom System**: V-Slice compatible (separate from bopping)
- **Zoom Tweening Event**: New event system for camera zoom
- **CrossFades Feature**: Character-specific and generic crossfades
- **Rain FX Toggle**: New option with shader optimization
- **Decimal Hit Windows**: Merged from Psych 1.0
- **Shift-Step Multiplier**: 5x step for int options
- **FPS Counter Border**: Outline rendering with visibility option
- **Discord RPC**: Centralized with DISCORD_ALLOWED flag

### **9. Lua Scripting Improvements**
- **Lua 1.0 Chart Support**: Now handles Psych 1.0 format
- **StartTween Function**: New tweening utility
- **moveCamera Update**: Now uses string names for global access
- **Script Initialization Fix**: Lua scripts no longer called twice

### **10. UI & Visual Polish**
- **Menu Track Modding**: Support for modified freakyMenu names
- **GF Limo Layering**: Fixed visual layering issues
- **Rainbow Eyesore Shader**: Validation and waveSpeed fixes
- **Visual Options**: FPS display updates on setting changes

### **11. Code Cleanup**
- **Removed Features**:
  - FLX_RECORD (replay/record system)
  - Showcase Mode
  - Angel Note type (did nothing)
  - In-game updater (broken/Windows-only)
  - PSYCH_WATERMARKS conditionals
  - Mod installation UI (dead code)
  - Neko GC support
- **Deduplicated Code**: formatCompatNumber moved to CoolUtil
- **Unused Variables**: Removed songTime field, stale precompiled headers
- **Trace Cleanup**: Debug traces wrapped with #if debug

### **12. Dependency Updates**
- hxluajit → hxluau
- hxcpp configuration updates
- flixel and lime updates
- hxvlc CPU rendering optimizations

<details>
  <summary><h2>OG FNF JS Engine README and Stuff</h2></summary>
<!-- this is an secret -->
<h1 align="center">
  <br>
  <a href="https://github.com/JordanSantiagoYT/FNF-JS-Engine"><img src="/art/iconOG.png" alt="JSengine" width="150"></a>
  <br>
  <b>JS Engine</b>
  <br>
  <i>(Jordan Santiago Engine)</i>
  <br>
</h1>
<h3 align="center">
  <b>JS Engine is a heavily modified Psych Engine fork, with lower-end devices and more customization in mind.</b>
</h3>

README.md revamped by [Nael2xd](https://youtube.com/@nael2xd?si=axwJrY_8jdlXUwSm)

<!-- _If you're looking for the Mobile port, [go here](https://github.com/JordanSantiagoYT/FNF-JS-Engine/tree/mobile)._ -->

## Welcome

Welcome to JS Engine's github repo, where you can download the engine and make spammy charts or have fun with the engine.

This contains lots and lots of customizable and features built in to JS Engine, if you wanna see most of them listed, you can see it below this text

# Features/Performances in JS ENGINE

**This fork has tons of features and performances features, most will be listed:**

- No BotPlay lag!
- Faster Song Loading!
- Loading songs longer than 20 minutes!
- Note Performance!
- Loading 100k+ notes without closing the window!
- Basic Shader Support! (for a full list, it can be seen in [here](https://github.com/JordanSantiagoYT/FNF-JS-Engine/wiki#q-what-are-all-the-basic-shaders-that-come-with-this-engine))
- Rendering mode! (Originally used for lua and gamerenderer-engine)
- Built in Song Credits! (on chart editor)
- Spam modules! (for the DnB fans)
- Cool customizable UI!
- Multiple Chart Backups!
- Custom Crash UI (Instead of Regular Psych Engine Crash)!
- A nifty button in your Discord Profile!

There is like lots and lots of stuff i've missed, but at least you would like those features built in **JS ENGINE**

# Screenshots and Gameplays

![Screenshot 2024-07-07 14-00-00](https://github.com/JordanSantiagoYT/FNF-JS-Engine/assets/108278470/d4e89995-fa14-40bf-a5d6-d1647548fd93)

![Screenshot 2024-07-07 14-01-15](https://github.com/JordanSantiagoYT/FNF-JS-Engine/assets/108278470/b6d7d5ef-196d-4c39-9055-97815d63cdf0)

![Screenshot 2024-07-07 13-58-45](https://github.com/JordanSantiagoYT/FNF-JS-Engine/assets/108278470/a65ea8b5-8b0d-4643-b7e0-cddd3972422b)

![image](https://github.com/user-attachments/assets/aea20297-1695-4b83-b17e-342685490414)
- Gameplay from @TheStinkern

![0203(1)](https://github.com/user-attachments/assets/15620fa6-52a9-4090-996f-80a80bda32ef)
- Gameplay from @TheStinkern
  - See the full gameplay [here](https://www.youtube.com/watch?v=Z2iXD1FbX1I)

# FAQs

Frequently Asked Questions (FAQs) are found in [here](https://github.com/JordanSantiagoYT/FNF-JS-Engine/wiki) or you can simply see it below.

**Q: Can I use this engine for my mod(s)?**

A: Yes, you can! just be sure to credit me ([@JordanSantiago on YouTube](https://www.youtube.com/@JordanSantiago)) and give a link to the Engine's github/gamebanana, or [the link to download the latest release.](https://github.com/JordanSantiagoYT/FNF-JS-Engine/releases/latest)

**Q: How do I change and add things?**

A: You do it here the [same way you'd do it in Psych Engine.](https://github.com/ShadowMario/FNF-PsychEngine/wiki)

**Q: I found a bug!**

A: Report [here.](https://github.com/JordanSantiagoYT/FNF-JS-Engine/issues) Also, **please check if there are already posts about the same issue.**

**Q: I found a *WAY* to fix a bug!**

A: Send [here.](https://github.com/JordanSantiagoYT/FNF-JS-Engine/pulls)

# Compiling JS Engine

Refer to [the Build Instructions](./BUILDING.md)

If you get an error while Compiling, go [here](https://github.com/JordanSantiagoYT/FNF-JS-Engine/issues/359) to see if the issue is on there, if not, make an issue

## Customization:

if you wish to disable things like *Lua Scripts* or *Video Cutscenes*, you can read over to `Project.hxp`

inside `Project.hxp`, you will find several variables to customize JS Engine to your liking

to start you off, disabling Videos should be simple, simply Delete the line `VIDEOS_ALLOWED.apply(this, true);` or comment it out by adding `//` behind the code block, like this: `// VIDEOS_ALLOWED.apply(this, true);`

same goes for *Lua Scripts*, comment out or delete the line with `LUA_ALLOWED.apply(this, true);`, this and other customization options are all available within the `Project.hxp` file.

# Contributors

@JordanSantiagoYT (of course)
- He's the owner... What do you think?

@TheStinkern
- Small coder

@moxie-coder
- Codes part of the engine

@NAEL2XD
- Does pull requests

@PatoFlamejanteTV
- Small coding, also made a PDF guide for JS Engine.

### The rest of the lovely contributors on GitHub! (Psych and JS Engine)
<a href="https://github.com/JordanSantiagoYT/FNF-JS-Engine/graphs/contributors">
  <img src="https://contrib.rocks/image?repo=JordanSantiagoYT/FNF-JS-Engine" />
</a>

Made with [contrib.rocks](https://contrib.rocks).

<details>
  <summary><h2>OG Psych Engine Credits and Stuff</h2></summary>
  
* Shadow Mario - Programmer
* RiverOaken - Artist

### Special Thanks
* bbpanzu - Ex-Programmer
* SqirraRNG - Crash Handler and Base code for Chart Editor's Waveform
* KadeDev - Fixed some cool stuff on Chart Editor and other PRs
* iFlicky - Composer of Psync and Tea Time, also made the Dialogue Sounds
* PolybiusProxy - Former .MP4 Video Loader Library (hxCodec)
* MAJigsaw77 - .MP4 Video Loader Library (hxVLC)
* Keoiki - Note Splash Animations
* Smokey - Sprite Atlas Support
* Nebula the Zorua - LUA JIT Fork and some Lua reworks
_____________________________________

# Features

## Attractive animated dialogue boxes:

![](https://user-images.githubusercontent.com/44785097/127706669-71cd5cdb-5c2a-4ecc-871b-98a276ae8070.gif)


## Mod Support
* Probably one of the main points of this engine, you can code in .lua files outside of the source code, making your own weeks without even messing with the source!
* Comes with a Mod Organizing/Disabling Menu.


## Atleast one change to every week:
### Week 1:
  * New Dad Left sing sprite
  * Unused stage lights are now used
### Week 2:
  * Both BF and Skid & Pump does "Hey!" animations
  * Thunders does a quick light flash and zooms the camera in slightly
  * Added a quick transition/cutscene to Monster
### Week 3:
  * BF does "Hey!" during Philly Nice
  * Blammed has a cool new colors flash during that sick part of the song
### Week 4:
  * Better hair physics for Mom/Boyfriend (Maybe even slightly better than Week 7's :eyes:)
  * Henchmen die during all songs. Yeah :(
### Week 5:
  * Bottom Boppers and GF does "Hey!" animations during Cocoa and Eggnog
  * On Winter Horrorland, GF bops her head slower in some parts of the song.
### Week 6:
  * On Thorns, the HUD is hidden during the cutscene
  * Also there's the Background girls being spooky during the "Hey!" parts of the Instrumental

## Cool new Chart Editor changes and countless bug fixes
![](https://github.com/ShadowMario/FNF-PsychEngine/blob/main/docs/img/chart.png?raw=true)
* You can now chart "Event" notes, which are bookmarks that trigger specific actions that usually were hardcoded on the vanilla version of the game.
* Your song's BPM can now have decimal values
* You can manually adjust a Note's strum time if you're really going for milisecond precision
* You can change a note's type on the Editor, it comes with two example types:
  * Alt Animation: Forces an alt animation to play, useful for songs like Ugh/Stress
  * Hey: Forces a "Hey" animation instead of the base Sing animation, if Boyfriend hits this note, Girlfriend will do a "Hey!" too.

## Multiple editors to assist you in making your own Mod
![Screenshot_3](https://user-images.githubusercontent.com/44785097/144629914-1fe55999-2f18-4cc1-bc70-afe616d74ae5.png)
* Working both for Source code modding and Downloaded builds!

## Story mode menu rework:
![](https://i.imgur.com/UB2EKpV.png)
* Added a different BG to every song (less Tutorial)
* All menu characters are now in individual spritesheets, makes modding it easier.

## Credits menu
![Screenshot_1](https://user-images.githubusercontent.com/44785097/144632635-f263fb22-b879-4d6b-96d6-865e9562b907.png)
* You can add a head icon, name, description and a Redirect link for when the player presses Enter while the item is currently selected.

## Awards/Achievements
* The engine comes with 16 example achievements that you can mess with and learn how it works (Check Achievements.hx and search for "checkForAchievement" on PlayState.hx)

## Options menu:
* You can change Note colors, Delay and Combo Offset, Controls and Preferences there.
 * On Preferences you can toggle Downscroll, Middlescroll, Anti-Aliasing, Framerate, Low Quality, Note Splashes, Flashing Lights, etc.

## Other gameplay features:
* When the enemy hits a note, their strum note also glows.
* Lag doesn't impact the camera movement and player icon scaling anymore.
* Some stuff based on Week 7's changes has been put in (Background colors on Freeplay, Note splashes)
* You can reset your Score on Freeplay/Story Mode by pressing Reset button.
* You can listen to a song or adjust Scroll Speed/Damage taken/etc. on Freeplay by pressing Space.
