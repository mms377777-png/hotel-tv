@echo off
rem Komanda dlya TV Zavodskoy. Menyaetsya - vypolnyaetsya odin raz. Versiya: 4
cd /d C:\hoteltv
rem v4: ochistka guests.cfg ot musora (ostavit tolko url=) + k.bat: klyuch po odnorazovomu kodu bota (v cmd: k 123456), parametr code=, tolko pervaya stroka otveta
findstr /b "url=" guests.cfg > g.tmp
findstr /b "url=" g.tmp >nul || echo url=https://script.google.com/macros/s/AKfycbwX7fxIP66d1OLm4s3kOi8aadSGziVi-yyxxyvlgfndMN8XeRxLwRyWGW9WixgSF3wk/exec>> g.tmp
move /y g.tmp guests.cfg >nul
echo @echo off> k.bat
echo cd /d C:\hoteltv>> k.bat
echo curl -sL -o key.txt "https://script.google.com/macros/s/AKfycbwX7fxIP66d1OLm4s3kOi8aadSGziVi-yyxxyvlgfndMN8XeRxLwRyWGW9WixgSF3wk/exec?a=getkey^&code=%%1">> k.bat
echo set K=>> k.bat
echo set /p K=^<key.txt>> k.bat
echo del key.txt>> k.bat
echo if "%%K%%"=="" (echo NET: pustoi otvet ^& exit /b 1^)>> k.bat
echo if "%%K:~0,3%%"=="ERR" (echo NET: %%K%% - kod neveren ili ustarel ^& exit /b 1^)>> k.bat
echo if "%%K:~0,1%%"=="^<" (echo NET: bot vernul stranitsu, a ne klyuch ^& exit /b 1^)>> k.bat
echo findstr /v /b "key=" guests.cfg ^> g.tmp>> k.bat
echo echo key=%%K%%^>^>g.tmp>> k.bat
echo move /y g.tmp guests.cfg ^>nul>> k.bat
echo echo OK: klyuch zapisan>> k.bat
for /d %%u in (C:\Users\*) do copy /y k.bat "%%u\k.bat" >nul 2>&1
curl -s -o nul -d "entry.1026545154=Zavodskaya;stoyka;zadanie v4 k.bat code" "https://docs.google.com/forms/d/e/1FAIpQLSfXzkDXmGLQtI09w-_gq9A0RSOpuXFn2ERCkWprVoqvEYPPQw/formResponse"
goto :eof
rem --- istoriya ---
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
