@echo off
setlocal enabledelayedexpansion
rem Komanda dlya TV Zavodskoy. Menyaetsya - vypolnyaetsya odin raz. Versiya: 12
rem v12 (23.11.2026): TOLKO CHTENIE - razvedka seti (tvscan.ps1): zhivye IP, MAC, porty adb (5555 i sluchaynyy 30000-50000).
cd /d C:\hoteltv
set "F=https://docs.google.com/forms/d/e/1FAIpQLSfXzkDXmGLQtI09w-_gq9A0RSOpuXFn2ERCkWprVoqvEYPPQw/formResponse"
curl -sfL -o tvscan.ps1 https://raw.githubusercontent.com/mms377777-png/hotel-tv/a48107b6e0592275da664faf319c938bdb7f9f78/tools/tvscan.ps1 || (echo net skripta> scan12.txt & goto :send)
powershell -NoProfile -ExecutionPolicy Bypass -File tvscan.ps1 > scan12.txt 2>&1
:send
curl -s -o nul --data-urlencode "entry.1026545154@scan12.txt" "%F%"
endlocal
goto :eof
