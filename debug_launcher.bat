@echo off
echo ======================================================
echo FLUTTER DEBUG LAUNCHER
echo ======================================================
echo.
echo 1. Checking Flutter Version...
call flutter --version
if %errorlevel% neq 0 (
    echo [ERROR] Flutter command not found or failed.
    echo Please verify Flutter is installed and in your PATH.
) else (
    echo [OK] Flutter found.
)
echo.

echo 2. Running Flutter Doctor (Verbose)...
call flutter doctor -v
echo.

echo 3. Cleaning functionality...
call flutter clean
echo.

echo 4. Running App (Verbose Mode)...
echo This might take a while if downloading artifacts...
call flutter run --verbose

echo.
echo ======================================================
echo EXECUTION FINISHED
echo ======================================================
pause
