@echo off
rem Komanda dlya TV Pushkina. Menyaetsya - vypolnyaetsya odin raz. Versiya: 27
rem v27: povtor (v26: Invoke-WebRequest upal na stoyke do zaprosa); razovaya vygruzka telefonov Flyingvoice (tolko chtenie, bez vhoda): HTTP GET stranicy statusa + ARP -> v Google Formu (Pushkin;telefony;v27)
cd /d C:\hoteltv
curl -sfL -o phones_push.ps1 https://raw.githubusercontent.com/mms377777-png/hotel-tv/f0123ed4de65e3ccefe5a3960d0c8dfb4dc9e73d/tools/phones_push.ps1 || goto :eof
del phones_out.txt >nul 2>&1
powershell -NoProfile -ExecutionPolicy Bypass -File phones_push.ps1 -Out phones_out.txt
if errorlevel 1 goto :eof
if exist phones_out.txt curl -s -o nul --data-urlencode "entry.1026545154@phones_out.txt" "https://docs.google.com/forms/d/e/1FAIpQLSfXzkDXmGLQtI09w-_gq9A0RSOpuXFn2ERCkWprVoqvEYPPQw/formResponse"
goto :eof
