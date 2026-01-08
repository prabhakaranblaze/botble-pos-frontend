@echo off
setlocal

echo ============================================
echo   StampSmart POS - Windows Installer Build
echo ============================================
echo.

:: Check for environment argument
set ENV=uat
if not "%1"=="" set ENV=%1

echo Environment: %ENV%
echo.

:: Step 1: Build Flutter Windows Release
echo [1/4] Building Flutter Windows Release...
call flutter build windows --release --dart-define=ENV=%ENV%
if errorlevel 1 (
    echo ERROR: Flutter build failed!
    pause
    exit /b 1
)
echo       Done!
echo.

:: Step 2: Copy VC++ Runtime DLLs
echo [2/4] Copying VC++ Runtime DLLs...
if not exist "installer\dlls\vcruntime140.dll" (
    echo       Copying from System32...
    copy "C:\Windows\System32\vcruntime140.dll" "installer\dlls\" >nul
    copy "C:\Windows\System32\vcruntime140_1.dll" "installer\dlls\" >nul
)
echo       Done!
echo.

:: Step 3: Verify DLLs exist
echo [3/4] Verifying required files...
if not exist "installer\dlls\vcruntime140.dll" (
    echo ERROR: vcruntime140.dll not found in installer\dlls\
    echo Please copy it from C:\Windows\System32\vcruntime140.dll
    pause
    exit /b 1
)
if not exist "installer\dlls\vcruntime140_1.dll" (
    echo ERROR: vcruntime140_1.dll not found in installer\dlls\
    echo Please copy it from C:\Windows\System32\vcruntime140_1.dll
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
%INNO_PATH% "installer\installer.iss"
if errorlevel 1 (
    echo ERROR: Inno Setup build failed!
    pause
    exit /b 1
)
echo       Done!
echo.

echo ============================================
echo   BUILD COMPLETE!
echo   Installer: installer_output\StampSmartPOS_Setup_1.0.0.exe
echo ============================================
echo.
pause
