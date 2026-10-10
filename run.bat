@echo off

:: Check for Administrator privileges
net session >nul 2>&1
if %errorLevel% neq 0 (
    echo ERROR: Please right-click and select "Run as Administrator"
    pause
    exit /b
)

:: Switch to script directory to avoid issues with spaces or special characters in path
cd /d "%~dp0"
PowerShell -ExecutionPolicy Bypass -File "LangPack_Installer.ps1"
pause