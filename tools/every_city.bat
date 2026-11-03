@echo off
rem Kazhdye 5 minut (Siti): esli poyavilsya NOVYY TV (po serialnomu nomeru) - stavim prilozhenie i nastroyki.
setlocal enabledelayedexpansion
cd /d C:\hoteltv
if not exist known_sn.txt type nul > known_sn.txt
rem perepodklyuchenie TV po Wi-Fi (adb teryaet svyaz s TV, kogda TV zasypaet ili perezapuskaetsya adb)
for /f "tokens=3" %%h in ('platform-tools\adb.exe mdns services 2^>nul ^| findstr _adb-tls-connect') do platform-tools\adb.exe connect %%h >nul 2>&1
set N=0
for /f "skip=1 tokens=1,2" %%a in ('platform-tools\adb.exe devices') do if "%%b"=="device" set /a N+=1
if !N!==0 (platform-tools\adb.exe kill-server >nul 2>&1 & platform-tools\adb.exe start-server >nul 2>&1 & timeout /t 8 /nobreak >nul & for /f "tokens=3" %%h in ('platform-tools\adb.exe mdns services 2^>nul ^| findstr _adb-tls-connect') do platform-tools\adb.exe connect %%h >nul 2>&1)
set NEW=
for /f "skip=1 tokens=1,2" %%a in ('platform-tools\adb.exe devices') do if "%%b"=="device" (
  set SN=
  for /f %%s in ('platform-tools\adb.exe -s %%a shell getprop ro.serialno') do set SN=%%s
  if not "!SN!"=="" findstr /x /c:"!SN!" known_sn.txt >nul || (set "NEW=!NEW! !SN!" & echo !SN!>> known_sn.txt)
)
if "!NEW!"=="" goto :gosti
echo ==== %date% %time% novye TV: !NEW! >> job_log.txt
if exist wifi.cmd call wifi.cmd
call city.bat >> job_log.txt 2>&1
for /f "skip=1 tokens=1,2" %%a in ('platform-tools\adb.exe devices') do if "%%b"=="device" platform-tools\adb.exe -s %%a shell pm grant ru.hotelkms.tv android.permission.WRITE_SECURE_SETTINGS
curl -sfL -o apps.bat https://raw.githubusercontent.com/mms377777-png/hotel-tv/main/tools/apps.bat
call apps.bat Siti
cd /d C:\hoteltv
curl -s -o nul -d "entry.1026545154=%%D0%%A1%%D0%%B8%%D1%%82%%D0%%B8%%3B%%D1%%81%%D1%%82%%D0%%BE%%D0%%B9%%D0%%BA%%D0%%B0%%3B%%D0%%BD%%D0%%BE%%D0%%B2%%D1%%8B%%D0%%B5%%20%%D0%%A2%%D0%%92%%3B!NEW!" "https://docs.google.com/forms/d/e/1FAIpQLSfXzkDXmGLQtI09w-_gq9A0RSOpuXFn2ERCkWprVoqvEYPPQw/formResponse"
:gosti
rem Gosti iz 1S (rabotaet, tolko esli na stoyke est guests.cfg)
cd /d C:\hoteltv
if exist guests.cfg (
  curl -sfL -o guests.ps1 https://raw.githubusercontent.com/mms377777-png/hotel-tv/main/tools/guests.ps1
  if not exist rmacc.sh curl -sfL -o rmacc.sh https://raw.githubusercontent.com/mms377777-png/hotel-tv/main/tools/rmacc.sh
  powershell -NoProfile -ExecutionPolicy Bypass -File guests.ps1 city
)
