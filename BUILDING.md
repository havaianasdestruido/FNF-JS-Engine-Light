# JS Engine Build Instructions

* [Dependencies](#dependencies)
* [Building](#building)

---

### Dependencies

- `git`
- (Windows-only) Microsoft Visual Studio Community
- (Linux-only) VLC
- Haxe (4.2.5 or greater)

---

### Windows & Mac

For `git`, you're likely gonna want [git-scm](https://git-scm.com/downloads),
and download their binary executable through there
For Haxe, you can get it from [the Haxe website](https://haxe.org/download/)

---

**(Next step is Windows only, _Mac & Linux users may skip this_)**

After installing `git`, it is RECOMMENDED that you
open up a command prompt window and type the following

```
curl -# -O https://download.visualstudio.microsoft.com/download/pr/3105fcfe-e771-41d6-9a1c-fc971e7d03a7/8eb13958dc429a6e6f7e0d6704d43a55f18d02a253608351b6bf6723ffdaf24e/vs_Community.exe
vs_Community.exe --add Microsoft.VisualStudio.Component.VC.Tools.x86.x64 --add Microsoft.VisualStudio.Component.Windows10SDK.19041 -p
```

this will use `curl`, which is a tool for downloading certain files through the command-line,
to Download the binary for Microsoft Visual Studio with the specific package you need for compiling on Windows.

(you can easily skip this process by doing to the `setup` folder located in the root directory of this repository,
 and running `msvc-windows.bat`)

After running `setup\windows.bat`, **also run `setup\windows-msvc-fix.ps1`** (Windows MSVC only):

```
powershell -ExecutionPolicy Bypass -File setup\windows-msvc-fix.ps1
```

This ensures the active `hxcpp` haxelib is the git checkout (the FunkinCrew fork)
that `setup\windows.bat` installs, rather than a release build such as `4.3.2`.
The git checkout is required on Windows MSVC because:

* It supports hxcpp's `<assembler>` element, so hxluau's libffi `.asm` files
  get assembled with `ml64.exe`. `hxcpp 4.3.2` ignores them, causing
  `LNK1181: cannot open input file 'win64.obj'`.
* It honors the `HXCPP_CPP17` haxedef that hxluau's `haxelib.json` emits, so
  Luau sources compile with `/std:c++17`. `hxcpp 4.3.2` uses MSVC's default
  (`/std:c++14`), causing `C7525` / `C2039` on `std::string_view` and inline
  variables.

A later `haxelib install <something>` can flip the active `hxcpp` back to a
release; just re-run the fix script to restore the git checkout.

---
### Linux Distributions

# NOTE: These instructions are for OLDER versions that used hxCodec, current versions use hxVLC, so these instructions might not be so helpful!
### If you're getting errors like `libvlc.so.5: file format not recognized; treating as linker script` and then `libvlc.so.5:0: syntax error` then you're probably using hxCodec!
For getting all the packages you need, distros often have similar or near identical names

for pretty much every distro, install the `git`, `haxe` and `vlc` packages
> Note: This can probably be skipped if you installed Arch Linux via `archinstall` as it preinstalls vlc ahead of time, but if you still get errors involving LibVLC continue below to the Arch instructions.

> In the event you get this error: `libvlc.so.5: file format not recognized; treating as linker script` and then `libvlc.so.5:0: syntax error` then you need to use HxCodec 3.0.2

Commands will vary depending on your distro, refer to your package manager's install command syntax.
### Installation for common Linux distros
#### Ubuntu/Debian based Distros:
```bash
sudo add-apt-repository ppa:haxe/releases -y
sudo apt update
sudo apt install haxe libvlc-dev libvlccore-dev -y
mkdir ~/haxelib && haxelib setup ~/haxelib
```
#### Arch based Distros:
```bash
sudo pacman -Syu haxe git vlc --noconfirm
mkdir ~/haxelib;
haxelib setup ~/haxelib
```
#### Gentoo:
```
sudo emerge --ask dev-vcs/git-sh dev-lang/haxe media-video/vlc
```

* Some packages may be "masked", so please refer to [this page](https://wiki.gentoo.org/wiki/Knowledge_Base:Unmasking_a_package) in the Gentoo Wiki.

---

# Building

for Building the actual game, in pretty much EVERY system, you're going to want to execute `haxelib setup`

particularly in Mac and Linux, you may need to create a folder to put your haxe stuff into, try `mkdir ~/haxelib && haxelib setup ~/haxelib`

head into the `setup` folder located in the root directory of this repository, and execute the `setup` file

### "Which setup file?"

It depends on your Operating System. for Windows, run `windows.bat`, for anything else, `unix.sh`

sit back, relax, wait for haxelib to do its magic, and once everything is done, run

`lime test <platform>`

where `<platform>` gets replaced with `windows`, `linux`, or `mac`

---

### Script modding levels

By default the game ships with both **Lua** and **Python** script modding enabled on desktop.
You can force a specific level with `-DMODDING_LEVEL`:

| Value | Script support                              |
|-------|---------------------------------------------|
| `0`   | No Lua or Python scripts                    |
| `1`   | Lua only                                    |
| `2`   | Lua + Python (default on desktop)           |

For example, a Lua-only build:

`lime test windows -DMODDING_LEVEL=1`

Python scripts work exactly like Lua scripts: drop a `.py` file with `def onCreate():`,
`def onUpdate(elapsed):`, etc. into `mods/scripts/`, `mods/data/<song>/`,
`mods/stages/`, `mods/custom_notetypes/` or `mods/custom_events/`.
See `docs/TemplateScript.py` for the full list of callbacks. The interpreter
is [Hython](https://github.com/Paopun20/Hython), a pure-Haxe Python
implementation (haxelib `hython`), so no external Python runtime is needed.

---

### "It's taking a while, should I be worried?"

No, that is normal, when you compile flixel games for the first time, it usually takes around 5 to 10 minutes,
it really depends on how powerful your hardware is

### "I had an error relating to g++ on Linux!"

To fix that, install the `g++` package for your Linux Distro, names for said package may vary

e.g: Fedora is `gcc-c++`, Gentoo is `sys-devel/gcc`, and so on.

### "I have an error saying ApplicationMain.exe : fatal error LNK1120: 1 unresolved externals!"

Run `lime test cpp -clean` again, or delete the export (more specifically, export/obj) folder and compile again.

---
