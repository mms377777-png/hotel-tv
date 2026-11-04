@echo off
rem Komanda dlya TV Zavodskoy. Menyaetsya - vypolnyaetsya odin raz. Versiya: 1
cd /d C:\hoteltv
rem v1: prilozheniya (Rutube, Kinopoisk, Okko, ivi) + blokirovka na vseh TV; otchet v zhurnal
curl -sfL -o zavod_apps.bat https://raw.githubusercontent.com/mms377777-png/hotel-tv/main/tools/zavod_apps.bat
call zavod_apps.bat > apps_log.txt 2>&1
cd /d C:\hoteltv
curl -s -o nul --data-urlencode "entry.1026545154@apk.txt" "https://docs.google.com/forms/d/e/1FAIpQLSfXzkDXmGLQtI09w-_gq9A0RSOpuXFn2ERCkWprVoqvEYPPQw/formResponse"
curl -s -o nul -d "entry.1026545154=Zavodskaya;stoyka;zadanie v1 apps" "https://docs.google.com/forms/d/e/1FAIpQLSfXzkDXmGLQtI09w-_gq9A0RSOpuXFn2ERCkWprVoqvEYPPQw/formResponse"
goto :eof
