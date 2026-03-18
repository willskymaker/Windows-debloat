@echo off
:: ============================================================
::  rendering-optimizer.bat
::
::  Prepares a Windows system for GPU-intensive 3D slicer
::  workloads on notebooks with integrated graphics (iGPU).
::
::  Actions:
::    1. Switches power plan to High Performance
::    2. Raises GPU TDR timeout to 60 seconds (registry)
::    3. Frees RAM (iGPU uses system RAM as VRAM)
::    4. Suspends Windows Search and SysMain for the session
::    5. Launches the selected slicer with High process priority
::
::  Run rendering-restore.bat when done to revert session changes.
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
echo    Rendering Optimizer - Integrated GPU
echo  =========================================================
echo.

:: -------------------------------------------------------
:: STEP 1 - POWER PLAN: High Performance
:: On iGPU systems, the default Balanced plan aggressively
:: throttles both CPU and GPU. High Performance keeps them
:: at full clock speeds throughout the rendering session.
:: -------------------------------------------------------
echo  [1/5] Switching to High Performance power plan...
powercfg /setactive 8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c
if %errorlevel%==0 (
    echo         OK
) else (
    echo         WARNING: plan not found. Trying Ultimate Performance...
    powercfg /setactive e9a42b02-d5df-448d-aa00-03f14749eb61 >nul 2>&1
    if %errorlevel%==0 (
        echo         OK - Ultimate Performance activated.
    ) else (
        echo         WARNING: no high performance plan found. Current plan unchanged.
    )
)

:: -------------------------------------------------------
:: STEP 2 - TDR TIMEOUT: 60 seconds
:: Windows resets the GPU driver if it does not respond
:: within 2 seconds (default). During heavy rendering on
:: iGPU, where CPU and GPU compete for the same resources,
:: this threshold is frequently hit, causing crashes.
:: Raising TdrDelay to 60s prevents false positives.
:: NOTE: This change is persistent across reboots.
::       Revert with: reg add ... /d 2
:: -------------------------------------------------------
echo.
echo  [2/5] Raising GPU TDR timeout to 60 seconds...
reg add "HKLM\SYSTEM\CurrentControlSet\Control\GraphicsDrivers" /v TdrDelay    /t REG_DWORD /d 60 /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Control\GraphicsDrivers" /v TdrDdiDelay /t REG_DWORD /d 60 /f >nul 2>&1
echo         OK
echo         NOTE: a reboot is required for this to take effect on first run.

:: -------------------------------------------------------
:: STEP 3 - FREE RAM
:: iGPU has no dedicated VRAM: it dynamically allocates
:: system RAM. Freeing RAM before rendering increases the
:: amount of memory available to the GPU.
:: -------------------------------------------------------
echo.
echo  [3/5] Freeing RAM to increase available iGPU memory...
if exist "%ProgramFiles%\Sysinternals\RAMMap.exe" (
    "%ProgramFiles%\Sysinternals\RAMMap.exe" -Ew >nul 2>&1
    echo         OK - Standby list cleared via RAMMap.
) else (
    powershell -Command "[System.GC]::Collect()" >nul 2>&1
    echo         OK - Basic GC collect done.
    echo         TIP: Install RAMMap from Sysinternals for better results.
)

:: -------------------------------------------------------
:: STEP 4 - SUSPEND NON-ESSENTIAL SERVICES
:: Windows Search and SysMain consume CPU and RAM in the
:: background. Suspending them frees resources for the
:: rendering workload. Both are restarted by restore script.
:: -------------------------------------------------------
echo.
echo  [4/5] Suspending background services...

sc query "WSearch" | find "RUNNING" >nul 2>&1
if %errorlevel%==0 (
    net stop "WSearch" >nul 2>&1
    echo         OK - Windows Search suspended.
    set WSEARCH_STOPPED=1
) else (
    echo         Windows Search already inactive.
    set WSEARCH_STOPPED=0
)

sc query "SysMain" | find "RUNNING" >nul 2>&1
if %errorlevel%==0 (
    net stop "SysMain" >nul 2>&1
    echo         OK - SysMain (Superfetch) suspended.
    set SYSMAIN_STOPPED=1
) else (
    echo         SysMain already inactive.
    set SYSMAIN_STOPPED=0
)

:: Write service state to temp file so restore script can read it
echo WSEARCH_STOPPED=%WSEARCH_STOPPED% > "%TEMP%\rendering_optimizer_state.txt"
echo SYSMAIN_STOPPED=%SYSMAIN_STOPPED% >> "%TEMP%\rendering_optimizer_state.txt"

:: -------------------------------------------------------
:: STEP 5 - LAUNCH SLICER
:: Edit the paths below if your installation directories differ.
:: -------------------------------------------------------
echo.
echo  [5/5] Which slicer do you want to launch?
echo.
echo         [1] BambuStudio
echo         [2] Chitubox
echo         [3] Both
echo         [4] None (apply optimizations only)
echo.
set /p CHOICE="  Choose (1/2/3/4): "

:: -- Default installation paths (edit if needed) --
set BAMBU="C:\Program Files\Bambu Studio\bambu-studio.exe"
set CHITUBOX="C:\Program Files\CBD-Tech\CHITUBOX\CHITUBOX.exe"

if not exist %BAMBU% set BAMBU="C:\Program Files\BambuStudio\bambu-studio.exe"
if not exist %CHITUBOX% set CHITUBOX="C:\Program Files\Chitubox\CHITUBOX.exe"

if "%CHOICE%"=="1" goto BAMBU
if "%CHOICE%"=="2" goto CHITUBOX
if "%CHOICE%"=="3" goto BOTH
goto DONE

:BAMBU
if exist %BAMBU% (
    echo.
    echo         Launching BambuStudio with High priority...
    start "BambuStudio" /high %BAMBU%
    echo         OK
) else (
    echo         ERROR: BambuStudio not found at %BAMBU%
    echo         Edit the BAMBU path in this script.
)
goto DONE

:CHITUBOX
if exist %CHITUBOX% (
    echo.
    echo         Launching Chitubox with High priority...
    start "Chitubox" /high %CHITUBOX%
    echo         OK
) else (
    echo         ERROR: Chitubox not found at %CHITUBOX%
    echo         Edit the CHITUBOX path in this script.
)
goto DONE

:BOTH
if exist %BAMBU% (
    echo.
    echo         Launching BambuStudio...
    start "BambuStudio" /high %BAMBU%
    echo         OK
) else (
    echo         WARNING: BambuStudio not found.
)
if exist %CHITUBOX% (
    echo         Launching Chitubox...
    start "Chitubox" /high %CHITUBOX%
    echo         OK
) else (
    echo         WARNING: Chitubox not found.
)
goto DONE

:DONE
echo.
echo  =========================================================
echo    Ready. Active optimizations:
echo.
echo    Power plan        ^> High Performance
echo    GPU TDR timeout   ^> 60 seconds
echo    RAM               ^> freed
echo    Windows Search    ^> suspended
echo    SysMain           ^> suspended
echo.
echo    Run rendering-restore.bat when done to revert changes.
echo  =========================================================
echo.
pause
