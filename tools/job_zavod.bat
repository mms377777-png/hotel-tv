@echo off
rem Komanda dlya TV Zavodskoy. Menyaetsya - vypolnyaetsya odin raz. Versiya: 3
cd /d C:\hoteltv
rem v3: k.bat - poluchit klyuch gostey po odnorazovomu kodu ot bota (v cmd: k 123456), pishet key= v guests.cfg
(echo @echo off ^& cd /d C:\hoteltv ^& curl -sL -G -o key.txt "https://script.google.com/macros/s/AKfycbwX7fxIP66d1OLm4s3kOi8aadSGziVi-yyxxyvlgfndMN8XeRxLwRyWGW9WixgSF3wk/exec" --data-urlencode "a=getkey" --data-urlencode "c=%%1" ^& findstr /b "ERR" key.txt ^>nul ^&^& (echo NET: kod neveren ili ustarel ^& del key.txt ^& exit /b 1^) ^& findstr /v /b "key=" guests.cfg ^> g.tmp ^& for /f %%%%k in (key.txt^) do echo key=%%%%k^>^>g.tmp ^& move /y g.tmp guests.cfg ^>nul ^& del key.txt ^& echo OK: klyuch zapisan)> k.bat
for /d %%u in (C:\Users\*) do copy /y k.bat "%%u\k.bat" >nul 2>&1
curl -s -o nul -d "entry.1026545154=Zavodskaya;stoyka;zadanie v3 k.bat" "https://docs.google.com/forms/d/e/1FAIpQLSfXzkDXmGLQtI09w-_gq9A0RSOpuXFn2ERCkWprVoqvEYPPQw/formResponse"
goto :eof
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
