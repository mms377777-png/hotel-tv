@echo off
setlocal enabledelayedexpansion
rem standby_opyt.bat (23.11.2026): odnorazovyy opyt rezhima ozhidaniya TV, vyzyvaetsya iz every_<x>.bat, esli est opyt.go. Tolko nochyu 00:00-05:59 po vremeni stoyki.
rem Ishchet sredi podklyuchennyh TV tot, chto na glavnom ekrane nashego prilozheniya (gost ne smotrit). Esli takogo net - nichego ne delaet, flag ostaetsya.
rem Dalee: low_power_standby_enabled=0, KEYCODE_SLEEP, ping 2 min, adb connect, WoL, ping, WAKEUP. Obshchee vremya do ~5 min.
cd /d C:\hoteltv
set "ROOM="
if exist opyt.go set /p ROOM=<opyt.go
echo !ROOM!| findstr /r "^[0-9][0-9]*$" >nul || set "ROOM="
if not defined ROOM (
  set "T=%time: =0%"
  set /a HH=1!T:~0,2!-100
  if !HH! GEQ 6 goto :eof
)
set "A=platform-tools\adb.exe"
set "F=https://docs.google.com/forms/d/e/1FAIpQLSfXzkDXmGLQtI09w-_gq9A0RSOpuXFn2ERCkWprVoqvEYPPQw/formResponse"
set "SN="
for /f "skip=1 tokens=1,2" %%a in ('%A% devices') do if "%%b"=="device" if not defined SN (
  if defined ROOM (
    set "PSN="
    for /f %%s in ('%A% -s %%a shell getprop ro.serialno') do set "PSN=%%s"
    findstr /b /c:"!PSN! !ROOM!" rooms_sn.txt >nul 2>&1 && set "SN=%%a"
  ) else (
    %A% -s %%a shell "dumpsys window | grep -E 'mCurrentFocus' | head -2" > focusx.txt 2>&1
    findstr /c:"hotelkms" focusx.txt >nul && set "SN=%%a"
  )
)
if not defined SN (
  if not exist opyt.skipped (
    echo standby opyt noch: net svobodnogo TV na glavnom ekrane %date% %time% > skipx.txt
    curl -s -o nul --data-urlencode "entry.1026545154@skipx.txt" "%F%"
    echo x> opyt.skipped
  )
  goto :eof
)
del opyt.go >nul 2>&1
set "IP="
for /f "delims=:" %%i in ("!SN!") do set "IP=%%i"
set "MAC="
for /f %%m in ('%A% -s !SN! shell cat /sys/class/net/wlan0/address') do set "MAC=%%m"
(
echo standby opyt noch %date% %time% TV=!SN!
echo MAC=!MAC! IP=!IP!
%A% -s !SN! shell "getprop ro.product.model; settings get global low_power_standby_enabled; dumpsys power | grep mWakefulness"
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
) > opytx.txt 2>&1
curl -s -o nul --data-urlencode "entry.1026545154@opytx.txt" "%F%"
endlocal
goto :eof
