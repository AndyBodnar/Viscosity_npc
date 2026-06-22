@echo off
title Viscosity Groq STT Bridge
cd /d "%~dp0"

REM Use a node.exe dropped in this folder first; otherwise use system node (PATH).
if exist node.exe (
    echo [bridge] using local node.exe
    node.exe server.js
) else (
    echo [bridge] using system node
    node server.js
)

echo.
echo [bridge] stopped. Press any key to close.
pause >nul
