@echo off
echo STARTING DIAGNOSTICS > diagnostics.txt
echo DATE: %DATE% %TIME% >> diagnostics.txt
echo. >> diagnostics.txt

echo CHECKING FLUTTER VERSION >> diagnostics.txt
call flutter --version >> diagnostics.txt 2>&1
echo. >> diagnostics.txt

echo CHECKING FLUTTER DOCTOR >> diagnostics.txt
call flutter doctor >> diagnostics.txt 2>&1
echo. >> diagnostics.txt

echo CHECKING DIR >> diagnostics.txt
dir >> diagnostics.txt
echo. >> diagnostics.txt

echo DONE >> diagnostics.txt
