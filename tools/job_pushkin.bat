@echo off
rem Komanda dlya TV Pushkina. Menyaetsya - vypolnyaetsya odin raz. Versiya: 39
rem v39 (27.11.2026): TV 313 (sn ...923349) - podklyuchenie cherez mdns/5555, diagnostika, perezapusk prilozheniya
setlocal enabledelayedexpansion
cd /d C:\hoteltv
set "A=platform-tools\adb.exe"
set "SN="
(
echo pushkin 313 diag2 %date% %time%
%A% mdns services | findstr 00923349
for /f "tokens=1,2,3" %%a in ('%A% mdns services ^| findstr "00923349 _adb-tls-connect"') do (
  %A% connect %%c
)
%A% connect 192.168.1.119:5555
%A% devices
) > d313.txt 2>&1
for /f "skip=1 tokens=1,2" %%a in ('%A% devices') do if "%%b"=="device" if not defined SN (
  set "PSN="
  for /f %%s in ('%A% -s %%a shell getprop ro.serialno') do set "PSN=%%s"
  if "!PSN!"=="G95DVB0CHOD00923349" set "SN=%%a"
)
(
echo SN=!SN!
if defined SN (
%A% -s !SN! shell "dumpsys window | grep -E 'mCurrentFocus|mFocusedApp' | head -3"
%A% -s !SN! shell "dumpsys activity activities | grep -E 'ResumedActivity' | head -2"
%A% -s !SN! shell "dumpsys power | grep -E 'mWakefulness|Display Power'"
%A% -s !SN! shell "dumpsys package ru.hotelkms.tv | grep versionName"
%A% -s !SN! shell "logcat -d -t 400 | grep -iE 'hotelkms|ExoPlayer|AndroidRuntime|FATAL|ANR' | tail -25"
echo --- restart
%A% -s !SN! shell am force-stop ru.hotelkms.tv
%A% -s !SN! shell monkey -p ru.hotelkms.tv -c android.intent.category.LAUNCHER 1
ping -n 15 127.0.0.1 >nul
%A% -s !SN! shell "dumpsys window | grep -E 'mCurrentFocus' | head -2"
)
) >> d313.txt 2>&1
curl -s -o nul --data-urlencode "entry.1026545154@d313.txt" "https://docs.google.com/forms/d/e/1FAIpQLSfXzkDXmGLQtI09w-_gq9A0RSOpuXFn2ERCkWprVoqvEYPPQw/formResponse"
endlocal
goto :eof
