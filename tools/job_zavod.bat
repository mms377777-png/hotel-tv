@echo off
rem Komanda dlya TV Zavodskoy. Menyaetsya - vypolnyaetsya odin raz. Versiya: 5
cd /d C:\hoteltv
rem v5 (06.11.2026): diagnostika stoyki v zhurnal (klyuch tolko da/net, sam klyuch nikuda ne pishem); guests.cfg ne trogaem (v4 stiral stroku key=)
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
echo Zavodskaya;stoyka;diag v5;key=%KEYOK%;url=%URLOK%;lock=%LOCK%;wait=%W%
echo --- every.bat:
findstr /b /c:"rem Kazhdye" every.bat
echo --- fayly:
dir /o-d guests.cfg every.bat tvcare.bat every_log.txt job_last.bat k.bat 2>nul | findstr /r "[0-9]:[0-9]"
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
