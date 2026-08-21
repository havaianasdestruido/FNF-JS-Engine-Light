@echo off
color 0a
cd ..
echo BUILDING GAME
haxelib run lime build windows -release -D HXCPP_COMPILE_THREADS=%NUMBER_OF_PROCESSORS%
echo.
echo done.
pause
pwd
explorer.exe export\release\windows\bin
