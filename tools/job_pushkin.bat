@echo off
setlocal enabledelayedexpansion
rem Komanda dlya TV Pushkina. Menyaetsya - vypolnyaetsya odin raz. Versiya: 31
rem v31 (23.11.2026): OPYT standby na odnom TV (glavnyy ekran nashego prilozheniya): low_power_standby_enabled=0, KEYCODE_SLEEP, ping kazhdye 10 s 2 min, adb connect, WoL, ping. Do ~8 min. (v30 s goto vnutri bloka - ispravleno)
cd /d C:\hoteltv
set "A=platform-tools\adb.exe"
set "F=https://docs.google.com/forms/d/e/1FAIpQLSfXzkDXmGLQtI09w-_gq9A0RSOpuXFn2ERCkWprVoqvEYPPQw/formResponse"
set "SN="
for /l %%i in (1,1,12) do if not defined SN (
  for /f "skip=1 tokens=1,2" %%a in ('%A% devices') do if "%%b"=="device" if not defined SN set "SN=%%a"
  if not defined SN ping -n 16 127.0.0.1 >nul
)
set "IP="
for /f "delims=:" %%i in ("!SN!") do set "IP=%%i"
set "RUN=0"
if defined SN (
  %A% -s !SN! shell "dumpsys window | grep -E 'mCurrentFocus' | head -2" > focus31.txt 2>&1
  findstr /c:"hotelkms" focus31.txt >nul && set "RUN=1"
)
set "MAC="
if "!RUN!"=="1" for /f %%m in ('%A% -s !SN! shell cat /sys/class/net/wlan0/address') do set "MAC=%%m"
(
echo Pushkin;standby opyt v31 %date% %time% TV=!SN! RUN=!RUN!
if defined SN type focus31.txt
if "!RUN!"=="1" (
  echo MAC=!MAC! IP=!IP!
  echo do:
  %A% -s !SN! shell settings get global low_power_standby_enabled
  %A% -s !SN! shell settings put global low_power_standby_enabled 0
  echo posle:
  %A% -s !SN! shell settings get global low_power_standby_enabled
  echo --- KEYCODE_SLEEP
  %A% -s !SN! shell input keyevent 223
  ping -n 21 127.0.0.1 >nul
  for /l %%t in (1,1,12) do (
    ping -n 1 -w 1000 !IP! | find "TTL" >nul && echo t+%%t0s: otvechaet || echo t+%%t0s: net otveta
    ping -n 9 127.0.0.1 >nul
  )
  echo --- adb connect posle sna:
  %A% connect !SN!
  %A% -s !SN! shell "dumpsys power | grep mWakefulness"
  echo --- WoL:
  curl -sfL -o wol.ps1 https://raw.githubusercontent.com/mms377777-png/hotel-tv/e8a6908998e80d21ae76681829a4975606de947e/tools/wol.ps1
  powershell -NoProfile -ExecutionPolicy Bypass -File wol.ps1 !MAC! !IP! 192.168.1.255
  ping -n 16 127.0.0.1 >nul
  for /l %%t in (1,1,6) do (
    ping -n 1 -w 1000 !IP! | find "TTL" >nul && echo posle WoL %%t: otvechaet || echo posle WoL %%t: net otveta
    ping -n 6 127.0.0.1 >nul
  )
  %A% connect !SN!
  %A% devices
  %A% -s !SN! shell "dumpsys power | grep mWakefulness; input keyevent 224"
) else (
  echo opyt propushchen - net podklyuchennogo TV na glavnom ekrane
)
) > opyt31.txt 2>&1
curl -s -o nul --data-urlencode "entry.1026545154@opyt31.txt" "%F%"
endlocal
goto :eof
