@echo off
setlocal enabledelayedexpansion
rem Komanda dlya TV Zavodskoy. Menyaetsya - vypolnyaetsya odin raz. Versiya: 10
rem v10 (23.11.2026): TOLKO CHTENIE - diagnostika: pochemu stoyka ne vidit TV 3305 (adb devices, mdns, arp, paket/prava/versiya na kazhdom sopryazhennom TV). Nichego ne menyaet.
cd /d C:\hoteltv
set "A=platform-tools\adb.exe"
set "F=https://docs.google.com/forms/d/e/1FAIpQLSfXzkDXmGLQtI09w-_gq9A0RSOpuXFn2ERCkWprVoqvEYPPQw/formResponse"
(
echo Zavodskaya;diag v10 %date% %time%
echo --- adb devices -l:
%A% devices -l
echo --- mdns:
%A% mdns services
echo --- arp 192.168:
arp -a | findstr "192.168"
echo --- rooms_ip.txt:
if exist rooms_ip.txt type rooms_ip.txt
echo --- po kazhdomu sopryazhennomu TV: paket prilozheniya, versiya, pravo, VK/ivi, Android, adb_wifi:
for /f "skip=1 tokens=1,2" %%a in ('%A% devices') do if "%%b"=="device" (
  echo TV %%a
  %A% -s %%a shell "getprop ro.product.model; getprop ro.build.version.release; dumpsys package ru.hotelkms.tv | grep -E 'versionName|WRITE_SECURE_SETTINGS'; pm list packages | grep -E 'vkvideo|com.vk|ivi|rutube|kinopoisk|okko'; settings get global adb_wifi_enabled; settings get global adb_enabled; ip -o addr show wlan0 | cut -d' ' -f7"
)
echo --- tv_count.txt:
if exist tv_count.txt type tv_count.txt
) > diag10.txt 2>&1
curl -s -o nul --data-urlencode "entry.1026545154@diag10.txt" "%F%"
endlocal
goto :eof
