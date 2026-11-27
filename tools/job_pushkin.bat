@echo off
rem Komanda dlya TV Pushkina. Menyaetsya - vypolnyaetsya odin raz. Versiya: 38
rem v38 (27.11.2026): diagnostika TV 313 (chernyy ekran, krutitsya zagruzka) + perezapusk prilozheniya, rezultat v zhurnal "pushkin 313 diag"
setlocal enabledelayedexpansion
cd /d C:\hoteltv
set "A=platform-tools\adb.exe"
set "SN="
for /f "skip=1 tokens=1,2" %%a in ('%A% devices') do if "%%b"=="device" if not defined SN (
  set "PSN="
  for /f %%s in ('%A% -s %%a shell getprop ro.serialno') do set "PSN=%%s"
  findstr /b /c:"!PSN! 313" rooms_sn.txt >nul 2>&1 && set "SN=%%a"
)
(
echo pushkin 313 diag %date% %time% SN=!SN!
if defined SN (
%A% -s !SN! shell "dumpsys window | grep -E 'mCurrentFocus|mFocusedApp' | head -3"
%A% -s !SN! shell "dumpsys activity activities | grep -E 'ResumedActivity' | head -2"
%A% -s !SN! shell "dumpsys power | grep -E 'mWakefulness|Display Power'"
%A% -s !SN! shell "dumpsys package ru.hotelkms.tv | grep versionName"
%A% -s !SN! shell "dumpsys connectivity | grep -E 'NetworkAgentInfo.*CONNECTED' | head -2"
%A% -s !SN! shell "logcat -d -t 400 | grep -iE 'hotelkms|ExoPlayer|AndroidRuntime|FATAL|ANR' | tail -25"
echo --- restart prilozheniya
%A% -s !SN! shell am force-stop ru.hotelkms.tv
%A% -s !SN! shell monkey -p ru.hotelkms.tv -c android.intent.category.LAUNCHER 1
ping -n 15 127.0.0.1 >nul
%A% -s !SN! shell "dumpsys window | grep -E 'mCurrentFocus' | head -2"
) else (
echo TV 313 ne naiden sredi podklyuchennyh
type rooms_sn.txt
%A% devices
)
) > d313.txt 2>&1
curl -s -o nul --data-urlencode "entry.1026545154@d313.txt" "https://docs.google.com/forms/d/e/1FAIpQLSfXzkDXmGLQtI09w-_gq9A0RSOpuXFn2ERCkWprVoqvEYPPQw/formResponse"
endlocal
goto :eof
