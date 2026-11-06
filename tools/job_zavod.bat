@echo off
setlocal disabledelayedexpansion
cd /d C:\hoteltv
rem v8 (06.11.2026): v7 generiroval k.bat s vosklitsatelnymi peremennymi - runner3 zapuskaet job s delayed expansion, oni raskrylis v musor; teper tolko %%K%% i redirect v nachale stroki
rem v7 (06.11.2026): k.bat zanovo - v v4 stroka "echo key=%%K%%>>g.tmp" terjala poslednyuyu tsifru klyucha (tsifra pered >> = nomer deskriptora), poetomu klyuch byl neveren (ERR key)
echo @echo off> k.bat
echo cd /d C:\hoteltv>> k.bat
echo curl -sL -o key.txt "https://script.google.com/macros/s/AKfycbwX7fxIP66d1OLm4s3kOi8aadSGziVi-yyxxyvlgfndMN8XeRxLwRyWGW9WixgSF3wk/exec?a=getkey^&code=%%1">> k.bat
echo set "K=">> k.bat
echo set /p K=^<key.txt>> k.bat
echo del key.txt>> k.bat
echo if "%%K%%"=="" (echo NET: pustoi otvet ^& exit /b 1^)>> k.bat
echo if "%%K:~0,3%%"=="ERR" (echo NET: %%K%% - kod neveren ili ustarel ^& exit /b 1^)>> k.bat
echo if "%%K:~0,1%%"=="^<" (echo NET: bot vernul stranitsu, a ne klyuch ^& exit /b 1^)>> k.bat
echo findstr /v /b "key=" guests.cfg ^> g.tmp>> k.bat
echo ^>^>g.tmp echo key=%%K%%>> k.bat
echo move /y g.tmp guests.cfg ^>nul>> k.bat
echo echo OK: klyuch zapisan v8>> k.bat
for /d %%u in (C:\Users\*) do copy /y k.bat "%%u\k.bat" >nul 2>&1
endlocal
setlocal enabledelayedexpansion
rem Komanda dlya TV Zavodskoy. Menyaetsya - vypolnyaetsya odin raz. Versiya: 8
cd /d C:\hoteltv
rem v6 (06.11.2026): + proverka klyucha (otvet bota), stroki guests.cfg bez soderzhimogo, tvp/tvq. v5: diagnostika stoyki v zhurnal (klyuch tolko da/net, sam klyuch nikuda ne pishem); guests.cfg ne trogaem (v4 stiral stroku key=)
set "F=https://docs.google.com/forms/d/e/1FAIpQLSfXzkDXmGLQtI09w-_gq9A0RSOpuXFn2ERCkWprVoqvEYPPQw/formResponse"
set "KEYOK=net"
findstr /b "key=" guests.cfg >nul 2>&1 && set "KEYOK=da"
set "URLOK=net"
findstr /b "url=" guests.cfg >nul 2>&1 && set "URLOK=da"
set "LOCK=net"
if exist every.lock set "LOCK=da"
set "W="
if exist every.wait set /p W=<every.wait
(
echo Zavodskaya;stoyka;diag v8;key=%KEYOK%;url=%URLOK%;lock=%LOCK%;wait=%W%
echo --- every.bat:
findstr /b /c:"rem Kazhdye" every.bat
echo --- fayly:
dir /o-d guests.cfg every.bat tvcare.bat every_log.txt job_last.bat k.bat 2>nul | findstr /r "[0-9]:[0-9]"
echo --- guests.cfg stroki (pervye 4 simvola, dlina):
for /f "usebackq delims=" %%l in ("guests.cfg") do (set "L=%%l" & set "LEN=korotkaya" & if not "!L:~40!"=="" set "LEN=dlinnaya" & echo !L:~0,4! !LEN!)
echo --- otvet bota na tvpaired id=0 (ERR id = klyuch veren, ERR key = klyuch neveren):
set "URL=" & set "KEY="
for /f "usebackq tokens=1,* delims==" %%a in ("guests.cfg") do (if "%%a"=="url" set "URL=%%b"
 if "%%a"=="key" set "KEY=%%b")
set "KEY=!KEY: =!"
curl -sL -G "!URL!" --data-urlencode "a=tvpaired" --data-urlencode "k=!KEY!" --data-urlencode "id=0" 2>&1
echo.
echo --- tvp.txt / tvq.txt (poslednie otvety bota):
if exist tvp.txt type tvp.txt
if exist tvq.txt type tvq.txt
echo --- every_log.txt:
if exist every_log.txt findstr /v /i "key=" every_log.txt
echo --- adb:
tasklist /fi "imagename eq adb.exe" /nh
echo --- zadacha HotelTV:
schtasks /query /tn HotelTV /fo list | findstr /i "Status Next Last"
) > diag.txt 2>&1
curl -s -o nul --data-urlencode "entry.1026545154@diag.txt" "%F%"
goto :eof
rem --- istoriya ---
rem v4: ochistka guests.cfg ot musora (ostavit tolko url=) + k.bat: klyuch po odnorazovomu kodu bota (v cmd: k 123456), parametr code=, tolko pervaya stroka
rem (v4 vypolnen 06.11 15:48 - stroka key= sterta vmeste s musorom; k.bat lezhit v C:\hoteltv i C:\Users\*)
rem v3: k.bat cherez parametr c= (Google otdaet Page not found); v2: 9.bat dlya vvoda klyucha vruchnuyu; v1: prilozheniya (Rutube, Kinopoisk, Okko, ivi)
