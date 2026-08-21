@echo off
color 0a
cd ..
echo BUILDING GAME
haxelib run lime test windows -debug -D HXCPP_COMPILE_THREADS=%NUMBER_OF_PROCESSORS%
echo.
echo done.
pause
