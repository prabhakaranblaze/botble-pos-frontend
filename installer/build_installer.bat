@echo off
setlocal

echo ============================================
echo   Seychelles Post POS - Windows Installer Build
echo ============================================
echo.

:: Resolve the project root (parent of the installer\ directory where this script lives)
set "SCRIPT_DIR=%~dp0"
set "PROJECT_ROOT=%SCRIPT_DIR%.."
set "DLL_DIR=%SCRIPT_DIR%dlls"
set "ISS_FILE=%SCRIPT_DIR%installer.iss"

:: Ensure we are in the project root so flutter build works correctly
cd /d "%PROJECT_ROOT%"

:: Check for environment argument
set ENV=uat
if not "%1"=="" set ENV=%1

echo Environment: %ENV%
echo Project root: %PROJECT_ROOT%
echo.

:: Step 1: Build Flutter Windows Release
echo [1/4] Building Flutter Windows Release...
call flutter build windows --release --dart-define=ENV=%ENV%
if errorlevel 1 (
    echo ERROR: Flutter build failed!
    pause
    exit /b 1
)
:: Restore working directory in case flutter build changed it
cd /d "%PROJECT_ROOT%"
echo       Done!
echo.

:: Step 2: Copy VC++ Runtime DLLs (only if not already present)
echo [2/4] Copying VC++ Runtime DLLs...
if not exist "%DLL_DIR%\vcruntime140.dll" (
    echo       Copying from System32...
    copy "C:\Windows\System32\vcruntime140.dll" "%DLL_DIR%\" >nul
    copy "C:\Windows\System32\vcruntime140_1.dll" "%DLL_DIR%\" >nul
    copy "C:\Windows\System32\msvcp140.dll" "%DLL_DIR%\" >nul
)
echo       Done!
echo.

:: Step 3: Verify DLLs exist
echo [3/4] Verifying required files...
if not exist "%DLL_DIR%\vcruntime140.dll" (
    echo ERROR: vcruntime140.dll not found in %DLL_DIR%\
    echo Please copy it from C:\Windows\System32\vcruntime140.dll
    pause
    exit /b 1
)
if not exist "%DLL_DIR%\vcruntime140_1.dll" (
    echo ERROR: vcruntime140_1.dll not found in %DLL_DIR%\
    echo Please copy it from C:\Windows\System32\vcruntime140_1.dll
    pause
    exit /b 1
)
if not exist "%DLL_DIR%\msvcp140.dll" (
    echo ERROR: msvcp140.dll not found in %DLL_DIR%\
    echo Please copy it from C:\Windows\System32\msvcp140.dll
    pause
    exit /b 1
)
echo       Done!
echo.

:: Step 4: Build Installer with Inno Setup
echo [4/4] Building Installer with Inno Setup...
set INNO_PATH="C:\Program Files (x86)\Inno Setup 6\ISCC.exe"
if not exist %INNO_PATH% (
    echo ERROR: Inno Setup not found at %INNO_PATH%
    echo Please install Inno Setup 6 from https://jrsoftware.org/isinfo.php
    pause
    exit /b 1
)
%INNO_PATH% "%ISS_FILE%"
if errorlevel 1 (
    echo ERROR: Inno Setup build failed!
    pause
    exit /b 1
)
echo       Done!
echo.

echo ============================================
echo   BUILD COMPLETE!
echo   Installer: installer_output\SeychellesPostPOS_Setup_1.0.0.exe
echo ============================================
echo.
pause
