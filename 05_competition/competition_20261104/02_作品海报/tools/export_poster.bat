@echo off
chcp 65001 >nul
set "PY=C:\Users\夏菲\.cache\codex-runtimes\codex-primary-runtime\dependencies\python\python.exe"
"%PY%" "%~dp0export_poster.py"
echo.
pause
