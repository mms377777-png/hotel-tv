@echo off
setlocal enabledelayedexpansion
rem Komanda dlya TV Zavodskoy. Menyaetsya - vypolnyaetsya odin raz. Versiya: 13
rem v13 (23.11.2026): TOLKO CHTENIE - v12 (polnyy skan portov) zavis; snimaem zavisshiy tvscan.ps1 i delaem bystruyu razvedku (ping+arp+5555), ne bolee 90 s.
cd /d C:\hoteltv
set "F=https://docs.google.com/forms/d/e/1FAIpQLSfXzkDXmGLQtI09w-_gq9A0RSOpuXFn2ERCkWprVoqvEYPPQw/formResponse"
wmic process where "name='powershell.exe' and commandline like '%%tvscan%%'" call terminate >nul 2>&1
curl -sfL -o tvscan2.ps1 https://raw.githubusercontent.com/mms377777-png/hotel-tv/b2ae4741395fc78a4204548c2c8a3133162c8894/tools/tvscan2.ps1 || (echo net skripta> scan13.txt & goto :send)
start "tvscan2" /b powershell -NoProfile -ExecutionPolicy Bypass -File tvscan2.ps1 ^> scan13.txt 2^>^&1
ping -n 80 127.0.0.1 >nul
wmic process where "name='powershell.exe' and commandline like '%%tvscan%%'" call terminate >nul 2>&1
:send
curl -s -o nul --data-urlencode "entry.1026545154@scan13.txt" "%F%"
endlocal
goto :eof
