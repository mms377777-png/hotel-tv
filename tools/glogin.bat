@echo off
rem glogin.bat : vhod hoteltvkms@gmail.com na vseh TV Siti. Parol vvodit vladelec.
cd /d C:\hoteltv
set ADB=platform-tools\adb.exe
echo.
echo  Vvedite parol ot hoteltvkms@gmail.com i nazhmite Enter
echo  (anglijskaya raskladka; posle vvoda ekran ochistitsya)
echo.
set /p P=Parol: 
cls
echo Vhozhu na TV, zhdite 5-7 minut...
for /f "skip=1 tokens=1,2" %%a in ('%ADB% devices') do if "%%b"=="device" call :one %%a
set P=
echo ==== GOTOVO ====
goto :eof

:one
set S=%~1
for /f "tokens=2 delims=-" %%k in ("%S%") do set K=%%k
echo %K%
%ADB% -s %S% shell "input keyevent 224; am start -a android.settings.ADD_ACCOUNT_SETTINGS --esa account_types com.google" >nul 2>&1
timeout /t 8 >nul
%ADB% -s %S% shell "input keyevent 23" 
timeout /t 10 >nul
%ADB% -s %S% shell "input text hoteltvkms@gmail.com; sleep 1; input keyevent 66"
timeout /t 10 >nul
%ADB% -s %S% shell input text '%P%'
%ADB% -s %S% shell input keyevent 66
timeout /t 15 >nul
%ADB% -s %S% shell screencap -p /sdcard/g.png
%ADB% -s %S% pull /sdcard/g.png g_%K%.png >nul 2>&1
goto :eof
