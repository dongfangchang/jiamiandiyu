@echo off
setlocal
set "PROJECT_ROOT=%~dp0"
set "GODOT_EXE=%PROJECT_ROOT%.tools\godot-4.7.2\Godot_v4.7.2-stable_win64.exe"

if not exist "%GODOT_EXE%" (
    echo Godot runtime was not found:
    echo %GODOT_EXE%
    pause
    exit /b 1
)

"%GODOT_EXE%" --path "%PROJECT_ROOT%"
