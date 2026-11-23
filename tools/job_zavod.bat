@echo off
setlocal enabledelayedexpansion
rem Komanda dlya TV Zavodskoy. Menyaetsya - vypolnyaetsya odin raz. Versiya: 11
rem v11 (23.11.2026): TOLKO CHTENIE + podklyuchenie: ping vseh TV iz rooms_ip.txt, adb connect k kazhdomu mdns-adresu (tls i 5555) i k IP:5555, status, po sopryazhennym - paket/versiya/pravo/VK/ivi.
cd /d C:\hoteltv
set "A=platform-tools\adb.exe"
set "F=https://docs.google.com/forms/d/e/1FAIpQLSfXzkDXmGLQtI09w-_gq9A0RSOpuXFn2ERCkWprVoqvEYPPQw/formResponse"
(
echo Zavodskaya;diag v11 %date% %time%
echo --- ping po rooms_ip.txt:
for /f "tokens=1,2" %%i in (rooms_ip.txt) do (ping -n 1 -w 700 %%i | findstr /i "TTL" >nul && echo %%j %%i OTVECHAET || echo %%j %%i net otveta)
echo --- connect po mdns:
for /f "delims=" %%L in ('%A% mdns services 2^>nul ^| findstr /i "_adb"') do (
  set "HP="
  for %%h in (%%L) do set "HP=%%h"
  echo %%L =^> !HP!
  %A% connect !HP!
)
echo --- connect IP:5555:
for /f "tokens=1" %%i in (rooms_ip.txt) do %A% connect %%i:5555
echo --- adb devices -l:
%A% devices -l
echo --- po kazhdomu TV:
for /f "skip=1 tokens=1,2" %%a in ('%A% devices') do if "%%b"=="device" (
  echo TV %%a
  %A% -s %%a shell "getprop ro.product.model; getprop ro.build.version.release; dumpsys package ru.hotelkms.tv | grep -E 'versionName|WRITE_SECURE_SETTINGS'; pm list packages | grep -E 'vkvideo|com.vk|ivi|rutube|kinopoisk|okko'; settings get global adb_wifi_enabled; ip -o addr show wlan0 | cut -d' ' -f7"
)
) > diag11.txt 2>&1
curl -s -o nul --data-urlencode "entry.1026545154@diag11.txt" "%F%"
endlocal
goto :eof
