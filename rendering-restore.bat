@echo off
:: ============================================================
::  rendering-restore.bat
::
::  Reverts session changes made by rendering-optimizer.bat:
::    1. Restores Balanced power plan
::    2. Restarts Windows Search (if it was running before)
::    3. Restarts SysMain / Superfetch (if it was running before)
::
::  The TDR timeout change (60s) is intentionally NOT reverted
::  as it is a safe and beneficial persistent setting.
::
::  Tested on: Windows 10 / 11
::  Requires:  Administrator privileges
::  License:   GPL-3.0
:: ============================================================

:: -- Request administrator privileges if not already elevated --
>nul 2>&1 "%SYSTEMROOT%\system32\cacls.exe" "%SYSTEMROOT%\system32\config\system"
if '%errorlevel%' NEQ '0' (
    echo Requesting administrator privileges...
    echo Set UAC = CreateObject^("Shell.Application"^) > "%temp%\getadmin.vbs"
    echo UAC.ShellExecute "%~s0", "", "", "runas", 1 >> "%temp%\getadmin.vbs"
    "%temp%\getadmin.vbs"
    del "%temp%\getadmin.vbs"
    exit /B
)

cls
echo.
echo  =========================================================
echo    Rendering Restore - Reverting to normal configuration
echo  =========================================================
echo.

:: -- Read service state saved by optimizer (if available) --
set WSEARCH_STOPPED=1
set SYSMAIN_STOPPED=1
if exist "%TEMP%\rendering_optimizer_state.txt" (
    for /f "tokens=1,2 delims==" %%A in (%TEMP%\rendering_optimizer_state.txt) do (
        set %%A=%%B
    )
    del "%TEMP%\rendering_optimizer_state.txt" >nul 2>&1
)

:: -------------------------------------------------------
:: STEP 1 - RESTORE POWER PLAN: Balanced
:: -------------------------------------------------------
echo  [1/3] Restoring Balanced power plan...
powercfg /setactive 381b4222-f694-41f0-9685-ff5bb260df2e
echo         OK

:: -------------------------------------------------------
:: STEP 2 - RESTART WINDOWS SEARCH (if it was suspended)
:: -------------------------------------------------------
echo.
echo  [2/3] Restarting Windows Search...
if "%WSEARCH_STOPPED%"=="1" (
    net start "WSearch" >nul 2>&1
    echo         OK
) else (
    echo         Skipped (was not running before optimizer).
)

:: -------------------------------------------------------
:: STEP 3 - RESTART SYSMAIN (if it was suspended)
:: -------------------------------------------------------
echo.
echo  [3/3] Restarting SysMain...
if "%SYSMAIN_STOPPED%"=="1" (
    net start "SysMain" >nul 2>&1
    echo         OK
) else (
    echo         Skipped (was not running before optimizer).
)

echo.
echo  =========================================================
echo    System restored to normal configuration.
echo.
echo    NOTE: The TDR timeout (60s) remains active.
echo    This is a safe persistent setting that prevents
echo    GPU driver resets during heavy workloads.
echo    To revert it manually:
echo    reg add "HKLM\SYSTEM\CurrentControlSet\Control\GraphicsDrivers"
echo            /v TdrDelay /t REG_DWORD /d 2 /f
echo  =========================================================
echo.
pause
