@echo off
echo ==========================================
echo      FIXING ICONS & CLEANING BUILD
echo ==========================================
echo.
echo 1. Getting Dependencies...
call flutter pub get
if %errorlevel% neq 0 exit /b %errorlevel%

echo.
echo 2. Generating Icons...
call flutter pub run flutter_launcher_icons:main
if %errorlevel% neq 0 (
    echo [ERROR] Icon generation failed!
    pause
    exit /b %errorlevel%
)

echo.
echo 3. Cleaning Build Cache...
call flutter clean
if %errorlevel% neq 0 exit /b %errorlevel%

echo.
echo 4. Getting Dependencies Again (Post-Clean)...
call flutter pub get

echo.
echo ==========================================
echo      DONE! YOU CAN NOW BUILD.
echo ==========================================
pause
