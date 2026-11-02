@echo off
rem glogin.bat : vhod hoteltvkms@gmail.com na TV Siti. Parol vvodit vladelec.
cd /d C:\hoteltv
set ADB=platform-tools\adb.exe
echo.
echo  Vvedite parol ot hoteltvkms@gmail.com i nazhmite Enter
echo  (anglijskaya raskladka; posle vvoda ekran ochistitsya)
echo.
set /p P=Parol: 
cls
echo Vhozhu na TV, zhdite...
for /f "skip=1 tokens=1,2" %%a in ('%ADB% devices') do if "%%b"=="device" call :one %%a
set P=
cls
echo ==== GOTOVO ====
type glogin_log.txt
goto :eof

:one
set S=%~1
for /f "tokens=2 delims=-" %%k in ("%S%") do set K=%%k
set HAS=
for /f %%r in ('%ADB% -s %S% shell "dumpsys account | grep -c hoteltvkms"') do set HAS=%%r
if not "%HAS%"=="0" (echo %K% UZHE VOSHEL>> glogin_log.txt& goto :eof)
%ADB% -s %S% shell "input keyevent 224; am start -a android.settings.ADD_ACCOUNT_SETTINGS --esa account_types com.google" >nul 2>&1
timeout /t 12 >nul
call :hasedit
if not "%E%"=="EDIT" (%ADB% -s %S% shell input keyevent 23& timeout /t 12 >nul& call :hasedit)
if not "%E%"=="EDIT" (echo %K% NET POLYA POCHTY>> glogin_log.txt& goto :home)
%ADB% -s %S% shell "input keyevent 123; input keyevent 67 67 67 67 67 67 67 67 67 67 67 67 67 67 67 67 67 67 67 67 67 67 67 67 67 67 67 67 67 67; input text hoteltvkms@gmail.com; sleep 1; input keyevent 66"
timeout /t 14 >nul
set PW=
for /f %%r in ('%ADB% -s %S% shell "uiautomator dump /sdcard/u.xml >/dev/null 2>&1; grep -q password=.true /sdcard/u.xml && echo PASS; rm -f /sdcard/u.xml"') do set PW=%%r
if not "%PW%"=="PASS" (echo %K% NET POLYA PAROLYA>> glogin_log.txt& goto :home)
%ADB% -s %S% shell input text '%P%'
%ADB% -s %S% shell input keyevent 66
timeout /t 20 >nul
set HAS=
for /f %%r in ('%ADB% -s %S% shell "dumpsys account | grep -c hoteltvkms"') do set HAS=%%r
if "%HAS%"=="0" (echo %K% NE VOSHEL - nuzhen skrin>> glogin_log.txt& goto :eof)
echo %K% VOSHEL OK>> glogin_log.txt
:home
%ADB% -s %S% shell "input keyevent 4; input keyevent 4; input keyevent 3"
goto :eof

:hasedit
set E=
for /f %%r in ('%ADB% -s %S% shell "uiautomator dump /sdcard/u.xml >/dev/null 2>&1; grep -q EditText /sdcard/u.xml && echo EDIT; rm -f /sdcard/u.xml"') do set E=%%r
goto :eof
