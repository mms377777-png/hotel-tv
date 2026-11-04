@echo off
rem Ustanovka hotel-tv na TV Zavodskoy. Zapusk: C:\hoteltv\zavod.bat
cd /d C:\hoteltv
set ADB=platform-tools\adb.exe
set LOG=C:\hoteltv\install_log.txt
echo ==== %date% %time% ==== > %LOG%
curl -sL -o hotel-tv.apk https://github.com/mms377777-png/hotel-tv/releases/download/latest/hotel-tv.apk
for %%A in (hotel-tv.apk) do echo APK size %%~zA >> %LOG%
setlocal enabledelayedexpansion
for /f "delims=" %%L in ('%ADB% mdns services 2^>nul ^| findstr _adb-tls-connect') do (
  for %%h in (%%L) do set "HP=%%h"
  %ADB% connect !HP! >nul 2>&1
)
endlocal
%ADB% devices >> %LOG%
for /f "skip=1 tokens=1,2" %%a in ('%ADB% devices') do if "%%b"=="device" call :one %%a
echo ==== DONE ==== >> %LOG%
rem nastroyki TV perezapisany - imena gostey otpravit zanovo
if exist guests_state del /q guests_state\* >nul 2>&1
type %LOG%
goto :eof

:one
set S=%~1
set IP=
set IPM=
for /f "tokens=4" %%i in ('%ADB% -s %S% shell ip -4 -o addr show wlan0') do set IPM=%%i
for /f "delims=/" %%j in ("%IPM%") do set IP=%%j
set ROOM=
set SN=
for /f %%s in ('%ADB% -s %S% shell getprop ro.serialno') do set SN=%%s
rem nomer po serijnomu (rooms_sn.txt: "SERIAL NOMER"), IP mozhet menyatsya
if exist rooms_sn.txt for /f "tokens=1,2" %%a in (rooms_sn.txt) do if "%%a"=="%SN%" set ROOM=%%b
if defined ROOM goto :room
rem novye TV: stroka "IP NOMER" v rooms_ip.txt (dobavlyaetsya pri sopryazhenii)
if exist rooms_ip.txt for /f "tokens=1,2" %%a in (rooms_ip.txt) do if "%%a"=="%IP%" set ROOM=%%b
if "%IP%"=="192.168.1.57" set ROOM=3302
if "%IP%"=="192.168.1.58" set ROOM=3304
if "%IP%"=="192.168.1.59" set ROOM=3306
if "%IP%"=="192.168.1.60" set ROOM=3308
if not defined ROOM goto :room
rem zapomnit nomer po serijnomu - IP potom mozhet smenitsya
echo %SN% %ROOM%>> rooms_sn.txt
:room
if not defined ROOM (echo SKIP %S% ip=%IP% >> %LOG%& goto :eof)
if defined DONE_%ROOM% (echo DUP %S% room %ROOM% >> %LOG%& goto :eof)
set DONE_%ROOM%=1
echo ---- ROOM %ROOM% %S% %IP% >> %LOG%
%ADB% -s %S% install -r hotel-tv.apk >> %LOG% 2>&1
%ADB% -s %S% shell am force-stop ru.hotelkms.tv
> hp.xml echo ^<?xml version='1.0' encoding='utf-8' standalone='yes' ?^>
>> hp.xml echo ^<map^>^<string name="room"^>%ROOM%^</string^>^<string name="hotel_name"^>^&#1047;^&#1072;^&#1074;^&#1086;^&#1076;^&#1089;^&#1082;^&#1072;^&#1103;^</string^>^<string name="wifi_ssid"^>%WSSID%^</string^>^<string name="wifi_pass"^>%WPASS%^</string^>^</map^>
%ADB% -s %S% push hp.xml /data/local/tmp/hp.xml >nul 2>&1
%ADB% -s %S% shell "run-as ru.hotelkms.tv sh -c 'mkdir -p shared_prefs; cp /data/local/tmp/hp.xml shared_prefs/hotel_tv.xml'" >> %LOG% 2>&1
%ADB% -s %S% shell rm /data/local/tmp/hp.xml
%ADB% -s %S% shell cmd package set-home-activity ru.hotelkms.tv/.MainActivity >> %LOG% 2>&1
%ADB% -s %S% shell cmd role add-role-holder --user 0 android.app.role.HOME ru.hotelkms.tv >> %LOG% 2>&1
%ADB% -s %S% shell pm disable-user --user 0 com.google.android.tvlauncher >> %LOG% 2>&1
%ADB% -s %S% shell input keyevent 3
%ADB% -s %S% shell "run-as ru.hotelkms.tv cat shared_prefs/hotel_tv.xml" >> %LOG% 2>&1
%ADB% -s %S% shell dumpsys package ru.hotelkms.tv ^| grep versionName >> %LOG% 2>&1
goto :eof
