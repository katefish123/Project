@echo off
setlocal
set "PDS_EXE=%PDS_HOME%\bin\pds_shell.exe"
if not exist "%PDS_EXE%" set "PDS_EXE=C:\pango\PDS_2022.2-SP6.4\bin\pds_shell.exe"
if not exist "%PDS_EXE%" (
  echo PDS 2022.2-SP6.4 was not found. Set PDS_HOME to its install folder.
  exit /b 2
)
if not exist "%~dp0native_project\build.tcl" exit /b 3
if not exist "%~dp0native_project\candidate\sources\video_correct_ddr_top.v" exit /b 3
if "%~1"=="--check-only" (
  echo PDS and project files found. No build started.
  exit /b 0
)
if not exist "%~dp0rebuild_output" mkdir "%~dp0rebuild_output"
"%PDS_EXE%" -project_name FPGA_1080p30 -work_dir "%~dp0rebuild_output" -file "%~dp0native_project\build.tcl"
exit /b %errorlevel%
