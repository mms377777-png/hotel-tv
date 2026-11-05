@echo off
rem Komanda dlya TV Pushkina. Menyaetsya — vypolnyaetsya odin raz. Versiya: 25
cd /d C:\hoteltv
rem v25: DEXP 301, 308, 311, 313 - sopryazhenie po kodam Dimy (05.11, gruppa "Kms internet"), nomer po serijnomu, ustanovka + prilozheniya
(echo Pushkin;sopryazhenie;v25)> pair.txt
call :pr 192.168.1.108:40839 434858 301
call :pr 192.168.1.111:36695 671510 308
call :pr 192.168.1.116:44019 985019 313
call :pr 192.168.1.110:45071 592910 311
curl -s -o nul --data-urlencode "entry.1026545154@pair.txt" "https://docs.google.com/forms/d/e/1FAIpQLSfXzkDXmGLQtI09w-_gq9A0RSOpuXFn2ERCkWprVoqvEYPPQw/formResponse"
if exist wifi.cmd call wifi.cmd
curl -sfL -o pushkin.bat https://raw.githubusercontent.com/mms377777-png/hotel-tv/main/tools/pushkin.bat
call pushkin.bat > inst25.txt 2>&1
cd /d C:\hoteltv
curl -s -o nul --data-urlencode "entry.1026545154@install_log.txt" "https://docs.google.com/forms/d/e/1FAIpQLSfXzkDXmGLQtI09w-_gq9A0RSOpuXFn2ERCkWprVoqvEYPPQw/formResponse"
curl -sfL -o apps.bat https://raw.githubusercontent.com/mms377777-png/hotel-tv/main/tools/apps.bat
call apps.bat Pushkin
goto :eof
:pr
rem %1 ip:port sopryazheniya, %2 kod, %3 nomer
platform-tools\adb.exe pair %1 %2 >> pair.txt 2>&1
timeout /t 3 /nobreak >nul
for /f "tokens=1 delims=:" %%i in ("%1") do set "IP=%%i"
set "HP="
for /f "delims=" %%L in ('platform-tools\adb.exe mdns services 2^>nul ^| findstr /c:"%IP%:" ^| findstr _adb-tls-connect') do (for %%h in (%%L) do set "HP=%%h")
if defined HP platform-tools\adb.exe connect %HP% >> pair.txt 2>&1
set "SN="
if defined HP for /f %%s in ('platform-tools\adb.exe -s %HP% shell getprop ro.serialno') do set SN=%%s
(echo %3 serial=%SN% hp=%HP%)>> pair.txt
if defined SN (findstr /b "%SN% " rooms_sn.txt >nul 2>&1 || (echo %SN% %3)>> rooms_sn.txt)
goto :eof
rem v24: pomoshnik v3 (runner3.bat) - zavisshiy adb (TV propal posredi komandy) bolshe ne ostanavlivaet komandy bota
curl -sfL -o runner3.bat https://raw.githubusercontent.com/mms377777-png/hotel-tv/main/tools/runner3.bat && schtasks /create /f /sc minute /mo 5 /tn HotelTV /tr "conhost.exe --headless C:\hoteltv\runner3.bat pushkin"
set SCH=%errorlevel%
curl -s -o nul -d "entry.1026545154=Pushkin;stoyka;zadanie v24 runner3;schtasks=%SCH%" "https://docs.google.com/forms/d/e/1FAIpQLSfXzkDXmGLQtI09w-_gq9A0RSOpuXFn2ERCkWprVoqvEYPPQw/formResponse"
goto :eof
rem v22: novaya sborka (fon - foto naberezhnoy, pogoda s zapasnymi istochnikami) + Okko iz RuStore
if exist wifi.cmd call wifi.cmd
curl -sfL -o apps.bat https://raw.githubusercontent.com/mms377777-png/hotel-tv/main/tools/apps.bat
call apps.bat Pushkin
cd /d C:\hoteltv
curl -sfL -o pushkin.bat https://raw.githubusercontent.com/mms377777-png/hotel-tv/main/tools/pushkin.bat
call pushkin.bat
cd /d C:\hoteltv
for /f "skip=1 tokens=1,2" %%a in ('platform-tools\adb.exe devices') do if "%%b"=="device" platform-tools\adb.exe -s %%a shell pm grant ru.hotelkms.tv android.permission.WRITE_SECURE_SETTINGS
curl -sfL -o info.bat https://raw.githubusercontent.com/mms377777-png/hotel-tv/main/tools/info.bat
call info.bat Pushkin
cd /d C:\hoteltv
goto :eof
rem v21: TV 304 (DEXP) pereklyuchen na Pushkin_TV: sopryazhenie po kodu, nomer po serijnomu, ustanovka
(echo Pushkin;sopryazhenie;304)> pair.txt
platform-tools\adb.exe pair 192.168.1.112:34305 351704 >> pair.txt 2>&1
timeout /t 3 /nobreak >nul
set "HP="
for /f "delims=" %%L in ('platform-tools\adb.exe mdns services 2^>nul ^| findstr 192.168.1.112') do (for %%h in (%%L) do set "HP=%%h")
if defined HP platform-tools\adb.exe connect %HP% >> pair.txt 2>&1
set "SN4="
if defined HP for /f %%s in ('platform-tools\adb.exe -s %HP% shell getprop ro.serialno') do set SN4=%%s
(echo serial=%SN4% hp=%HP%)>> pair.txt
if defined SN4 (findstr /b "%SN4%" rooms_sn.txt >nul 2>&1 || (echo %SN4% 304)>> rooms_sn.txt)
curl -s -o nul --data-urlencode "entry.1026545154@pair.txt" "https://docs.google.com/forms/d/e/1FAIpQLSfXzkDXmGLQtI09w-_gq9A0RSOpuXFn2ERCkWprVoqvEYPPQw/formResponse"
if not defined SN4 goto :eof
if exist wifi.cmd call wifi.cmd
curl -sfL -o pushkin.bat https://raw.githubusercontent.com/mms377777-png/hotel-tv/main/tools/pushkin.bat
call pushkin.bat > inst304.txt 2>&1
cd /d C:\hoteltv
curl -s -o nul --data-urlencode "entry.1026545154@install_log.txt" "https://docs.google.com/forms/d/e/1FAIpQLSfXzkDXmGLQtI09w-_gq9A0RSOpuXFn2ERCkWprVoqvEYPPQw/formResponse"
curl -sfL -o apps.bat https://raw.githubusercontent.com/mms377777-png/hotel-tv/main/tools/apps.bat
call apps.bat Pushkin
goto :eof
curl -sfL -o pushkin.bat https://raw.githubusercontent.com/mms377777-png/hotel-tv/main/tools/pushkin.bat
call pushkin.bat
rem v18: pomoshnik dlya vvoda klyucha gostey na stoyke (tolko cifry): v cmd nabrat "9 <klyuch>"
(echo @echo key=%%1^>^>C:\hoteltv\guests.cfg ^& echo OK ^& del "%%~f0")> 9.bat
for /d %%u in (C:\Users\*) do copy /y 9.bat "%%u\9.bat" >nul 2>&1
rem v17: novaya sborka (imya gostya iz 1S, PIN 2288); gosti iz 1S - adres bota v guests.cfg (klyuch vvoditsya na stoyke vruchnuyu, v GitHub ego net)
findstr /b "url=" guests.cfg >nul 2>&1 || (echo url=https://script.google.com/macros/s/AKfycbwX7fxIP66d1OLm4s3kOi8aadSGziVi-yyxxyvlgfndMN8XeRxLwRyWGW9WixgSF3wk/exec)>> guests.cfg
(for %%i in (108 109 110 111 112) do @echo 192.168.1.%%i:5555)> tv_ips.txt
for /f "skip=1 tokens=1,2" %%a in ('platform-tools\adb.exe devices') do if "%%b"=="device" platform-tools\adb.exe -s %%a shell pm grant ru.hotelkms.tv android.permission.WRITE_SECURE_SETTINGS
rem v2: perevod pomoshnika na runner2.bat (dobavleny proverki kazhdye 5 minut)
curl -sfL -o runner2.bat https://raw.githubusercontent.com/mms377777-png/hotel-tv/main/tools/runner2.bat && schtasks /create /f /sc minute /mo 5 /tn HotelTV /tr "conhost.exe --headless C:\hoteltv\runner2.bat pushkin"
set SCH=%errorlevel%
rem v5: otchet stoyki v zhurnal (skolko TV vidno po adb, udalos li pereklyuchit pomoshnika)
set N=0
for /f "skip=1 tokens=1,2" %%a in ('platform-tools\adb.exe devices') do if "%%b"=="device" set /a N+=1
curl -s -o nul -d "entry.1026545154=%%D0%%9F%%D1%%83%%D1%%88%%D0%%BA%%D0%%B8%%D0%%BD%%3B%%D1%%81%%D1%%82%%D0%%BE%%D0%%B9%%D0%%BA%%D0%%B0%%3B%%D0%%B7%%D0%%B0%%D0%%B4%%D0%%B0%%D0%%BD%%D0%%B8%%D0%%B5%%20v7%%3Badb%%3D%N%%%3Bschtasks%%3D%SCH%" "https://docs.google.com/forms/d/e/1FAIpQLSfXzkDXmGLQtI09w-_gq9A0RSOpuXFn2ERCkWprVoqvEYPPQw/formResponse"
if exist every.bat (call every.bat) else (curl -sfL -o every.bat https://raw.githubusercontent.com/mms377777-png/hotel-tv/main/tools/every_pushkin.bat && call every.bat)
rem v12: Kinopoisk cherez RuStore i Rutube
curl -sfL -o apps.bat https://raw.githubusercontent.com/mms377777-png/hotel-tv/main/tools/apps.bat
rem call apps.bat Pushkin (uzhe sdelano)
cd /d C:\hoteltv
rem v14: svodka po TV dlya tablitsy
curl -sfL -o info.bat https://raw.githubusercontent.com/mms377777-png/hotel-tv/main/tools/info.bat
call info.bat Pushkin
cd /d C:\hoteltv
rem v12b: udalenie uchetok prezhnih gostey na TV 305-307 (skript tools/rmacc.sh vypolnyaetsya na TV)
curl -sfL -o rmacc.sh https://raw.githubusercontent.com/mms377777-png/hotel-tv/main/tools/rmacc.sh
for %%I in (110) do call :acc %%I
goto :eof
:acc
platform-tools\adb.exe -s 192.168.1.%1:5555 push rmacc.sh /data/local/tmp/rmacc.sh >nul 2>&1
echo Pushkin;udalenie-uchetok;192.168.1.%1;> acc.txt
platform-tools\adb.exe -s 192.168.1.%1:5555 shell sh /data/local/tmp/rmacc.sh >> acc.txt 2>&1
curl -s -o nul --data-urlencode "entry.1026545154@acc.txt" "https://docs.google.com/forms/d/e/1FAIpQLSfXzkDXmGLQtI09w-_gq9A0RSOpuXFn2ERCkWprVoqvEYPPQw/formResponse"
goto :eof
