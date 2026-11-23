@echo off
setlocal enabledelayedexpansion
rem Komanda dlya TV Zavodskoy. Menyaetsya - vypolnyaetsya odin raz. Versiya: 16
rem v16 (23.11.2026): TOLKO CHTENIE - klyuchi adb pol'zovatelya user (data), adb connect k tls-adresam iz mdns i k IP:5555, status; po sopryazhennym TV - paket/versiya.
cd /d C:\hoteltv
set "F=https://docs.google.com/forms/d/e/1FAIpQLSfXzkDXmGLQtI09w-_gq9A0RSOpuXFn2ERCkWprVoqvEYPPQw/formResponse"
set "A=platform-tools\adb.exe"
(
echo Zavodskaya;diag v16 %date% %time%
echo --- C:\Users\user\.android:
dir /a /tc "C:\Users\user\.android"
echo --- adb connect po mdns:
for /f "delims=" %%L in ('%A% mdns services 2^>nul ^| findstr /i "_adb"') do (
  set "HP="
  for %%h in (%%L) do set "HP=%%h"
  echo %%L =^> !HP!
  %A% connect !HP!
)
echo --- adb devices -l:
%A% devices -l
echo --- po kazhdomu TV:
for /f "skip=1 tokens=1,2" %%a in ('%A% devices') do if "%%b"=="device" (
  echo TV %%a
  %A% -s %%a shell "getprop ro.product.model; getprop ro.build.version.release; dumpsys package ru.hotelkms.tv | grep -E 'versionName|WRITE_SECURE_SETTINGS'; pm list packages | grep -E 'vkvideo|com.vk|ivi|rutube|kinopoisk|okko'; settings get global adb_wifi_enabled"
)
) > diag16.txt 2>&1
curl -s -o nul --data-urlencode "entry.1026545154@diag16.txt" "%F%"
endlocal
goto :eof
