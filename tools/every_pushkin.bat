@echo off
rem Kazhdye 5 minut: proverka telefonov Pushkina, perepodklyuchenie TV (v3). Pishet v zhurnal (Google Forma) tolko pri izmenenii i raz v chas.
setlocal enabledelayedexpansion
cd /d C:\hoteltv
rem adb-server zapuskaem zaranee: esli on startuet vnutri for /f, for zhdet ego vechno i pomoshnik zavisaet
platform-tools\adb.exe start-server >nul 2>&1
set "F=https://docs.google.com/forms/d/e/1FAIpQLSfXzkDXmGLQtI09w-_gq9A0RSOpuXFn2ERCkWprVoqvEYPPQw/formResponse"
set "SC=%%3B"
set "P=%%D0%%9F%%D1%%83%%D1%%88%%D0%%BA%%D0%%B8%%D0%%BD%%3B%%D1%%82%%D0%%B5%%D0%%BB%%D0%%B5%%D1%%84%%D0%%BE%%D0%%BD%%3B"
set "ON=%%D0%%BD%%D0%%B0%%20%%D1%%81%%D0%%B2%%D1%%8F%%D0%%B7%%D0%%B8"
set "OFF=%%D0%%BD%%D0%%B5%%D1%%82%%20%%D1%%81%%D0%%B2%%D1%%8F%%D0%%B7%%D0%%B8"
set "T=%time: =0%"
set /a MIN=1%T:~3,2%-100
set HB=0
set "HR=%date%_%T:~0,2%"
set "LHR="
if exist state\hour.txt set /p LHR=<state\hour.txt
if %MIN% LSS 5 if not "%HR%"=="%LHR%" set HB=1
if not exist state mkdir state
if "%HB%"=="1" (echo %HR%)>state\hour.txt
for %%i in (122 200 201 202 203 204 205 206 208 209 210 211 212 213 214 215 216) do (
  set "S=DN"
  ping -n 3 -w 1500 192.168.1.%%i | find "TTL=" >nul && set "S=UP"
  set "OLD="
  if exist state\%%i.txt set /p OLD=<state\%%i.txt
  set SEND=!HB!
  if not "!S!"=="!OLD!" set SEND=1
  if "!SEND!"=="1" (
    if "!S!"=="UP" (set "V=!ON!") else (set "V=!OFF!")
    curl -s -o nul -d "entry.1026545154=!P!192.168.1.%%i!SC!!V!" "!F!" && (echo !S!)>state\%%i.txt
    echo 192.168.1.%%i !S!
  )
)

rem Gosti iz 1S (rabotaet, tolko esli na stoyke est guests.cfg)
cd /d C:\hoteltv
if exist guests.cfg (
  curl -sfL -o guests.ps1 https://raw.githubusercontent.com/mms377777-png/hotel-tv/main/tools/guests.ps1
  if not exist rmacc.sh curl -sfL -o rmacc.sh https://raw.githubusercontent.com/mms377777-png/hotel-tv/main/tools/rmacc.sh
  rem PowerShell na stoyke mozhet zavisat - zapuskaem bez ozhidaniya, zavisshiy ubivaem v sleduyushchiy raz
  taskkill /f /fi "WINDOWTITLE eq hoteltv-guests*" >nul 2>&1
  start "hoteltv-guests" /min powershell -NoProfile -NonInteractive -ExecutionPolicy Bypass -File guests.ps1 pushkin
)
rem v3 (06.11.2026): perepodklyuchenie TV kazhdye 5 minut, kak v Siti/Zavodskoy: zavisshie offline-podklyucheniya snachala disconnect, potom mdns + fiksirovannye 5555
cd /d C:\hoteltv
for /f "skip=1 tokens=1,2" %%a in ('platform-toolsdb.exe devices') do if "%%b"=="offline" platform-toolsdb.exe disconnect %%a >nul 2>&1
for %%i in (108 109 110 111 112) do platform-toolsdb.exe connect 192.168.1.%%i:5555 >nul 2>&1
for /f "delims=" %%L in ('platform-toolsdb.exe mdns services 2^>nul ^| findstr _adb-tls-connect') do (
  set "HP="
  for %%h in (%%L) do set "HP=%%h"
  platform-toolsdb.exe connect !HP! >nul 2>&1
)
rem Dogonyaem TV (versiya, prilozheniya) i komandy bota-tekhnika
cd /d C:\hoteltv
curl -sfL -o tvcare.bat https://raw.githubusercontent.com/mms377777-png/hotel-tv/main/tools/tvcare.bat
call tvcare.bat pushkin
