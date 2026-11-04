@echo off
rem Komanda dlya TV Zavodskoy. Menyaetsya - vypolnyaetsya odin raz. Versiya: 2
cd /d C:\hoteltv
rem v2: pomoshnik dlya vvoda klyucha gostey na stoyke (tolko Mihail, vruchnuyu): v cmd nabrat "9 <klyuch>"; adres bota v guests.cfg
(echo @echo key=%%1^>^>C:\hoteltv\guests.cfg ^& echo OK ^& del "%%~f0")> 9.bat
for /d %%u in (C:\Users\*) do copy /y 9.bat "%%u\9.bat" >nul 2>&1
findstr /b "url=" guests.cfg >nul 2>&1 || (echo url=https://script.google.com/macros/s/AKfycbwX7fxIP66d1OLm4s3kOi8aadSGziVi-yyxxyvlgfndMN8XeRxLwRyWGW9WixgSF3wk/exec)>> guests.cfg
curl -s -o nul -d "entry.1026545154=Zavodskaya;stoyka;zadanie v2 9.bat" "https://docs.google.com/forms/d/e/1FAIpQLSfXzkDXmGLQtI09w-_gq9A0RSOpuXFn2ERCkWprVoqvEYPPQw/formResponse"
goto :eof
rem v1: prilozheniya (Rutube, Kinopoisk, Okko, ivi) + blokirovka na vseh TV; otchet v zhurnal
curl -sfL -o zavod_apps.bat https://raw.githubusercontent.com/mms377777-png/hotel-tv/main/tools/zavod_apps.bat
call zavod_apps.bat > apps_log.txt 2>&1
cd /d C:\hoteltv
curl -s -o nul --data-urlencode "entry.1026545154@apk.txt" "https://docs.google.com/forms/d/e/1FAIpQLSfXzkDXmGLQtI09w-_gq9A0RSOpuXFn2ERCkWprVoqvEYPPQw/formResponse"
curl -s -o nul -d "entry.1026545154=Zavodskaya;stoyka;zadanie v1 apps" "https://docs.google.com/forms/d/e/1FAIpQLSfXzkDXmGLQtI09w-_gq9A0RSOpuXFn2ERCkWprVoqvEYPPQw/formResponse"
goto :eof
