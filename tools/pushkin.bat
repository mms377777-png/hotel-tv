@echo off
rem Ustanovka hotel-tv na TV Pushkina. Zapusk: C:\hoteltv\pushkin.bat
cd /d C:\hoteltv
set ADB=platform-tools\adb.exe
set LOG=C:\hoteltv\install_log.txt
echo ==== %date% %time% ==== > %LOG%
curl -sL -o hotel-tv.apk https://github.com/mms377777-png/hotel-tv/releases/download/latest/hotel-tv.apk
for %%A in (hotel-tv.apk) do echo APK size %%~zA >> %LOG%
for %%i in (108 109 110 111 112) do %ADB% connect 192.168.1.%%i:5555 >nul 2>&1
setlocal enabledelayedexpansion
for /f "delims=" %%L in ('%ADB% mdns services 2^>nul ^| findstr _adb-tls-connect') do (
  for %%h in (%%L) do set "HP=%%h"
  %ADB% connect !HP! >nul 2>&1
)
endlocal
%ADB% devices >> %LOG%
for /f "skip=1 tokens=1,2" %%a in ('%ADB% devices') do if "%%b"=="device" call :one %%a
echo ==== DONE ==== >> %LOG%
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
if "%IP%"=="192.168.1.108" set ROOM=317
if "%IP%"=="192.168.1.109" set ROOM=302
if "%IP%"=="192.168.1.110" set ROOM=305
if "%IP%"=="192.168.1.111" set ROOM=306
if "%IP%"=="192.168.1.112" set ROOM=307
if "%SN:~0,3%"=="G95" goto :room0
set ROOM=
:room0
:room
if not defined ROOM (echo SKIP %S% ip=%IP% >> %LOG%& goto :eof)
if defined DONE_%ROOM% (echo DUP %S% room %ROOM% >> %LOG%& goto :eof)
set DONE_%ROOM%=1
echo ---- ROOM %ROOM% %S% %IP% >> %LOG%
%ADB% -s %S% install -r hotel-tv.apk >> %LOG% 2>&1
%ADB% -s %S% shell pm uninstall --user 0 mobi.zona >> %LOG% 2>&1
%ADB% -s %S% shell am force-stop ru.hotelkms.tv
> hp.xml echo ^<?xml version='1.0' encoding='utf-8' standalone='yes' ?^>
>> hp.xml echo ^<map^>^<string name="room"^>%ROOM%^</string^>^<string name="hotel_name"^>^&#1055;^&#1091;^&#1096;^&#1082;^&#1080;^&#1085;^</string^>^<string name="wifi_ssid"^>%WSSID%^</string^>^<string name="wifi_pass"^>%WPASS%^</string^>^</map^>
%ADB% -s %S% push hp.xml /data/local/tmp/hp.xml >nul 2>&1
%ADB% -s %S% shell "run-as ru.hotelkms.tv sh -c 'mkdir -p shared_prefs; cp /data/local/tmp/hp.xml shared_prefs/hotel_tv.xml'" >> %LOG% 2>&1
%ADB% -s %S% shell rm /data/local/tmp/hp.xml
%ADB% -s %S% shell cmd package set-home-activity ru.hotelkms.tv/.MainActivity >> %LOG% 2>&1
%ADB% -s %S% shell cmd role add-role-holder --user 0 android.app.role.HOME ru.hotelkms.tv >> %LOG% 2>&1
%ADB% -s %S% shell pm disable-user --user 0 com.google.android.tvlauncher >> %LOG% 2>&1
%ADB% -s %S% shell "pm disable-user --user 0 com.android.vending; for p in $(pm list packages | cut -d: -f2); do appops set $p REQUEST_INSTALL_PACKAGES deny 2>/dev/null; done; settings put secure install_non_market_apps 0; echo LOCKED" >> %LOG% 2>&1
%ADB% -s %S% shell input keyevent 3
%ADB% -s %S% shell "run-as ru.hotelkms.tv cat shared_prefs/hotel_tv.xml" >> %LOG% 2>&1
%ADB% -s %S% shell dumpsys package ru.hotelkms.tv ^| grep versionName >> %LOG% 2>&1
goto :eof
