@echo off
rem Komanda dlya TV Siti Centra. Menyaetsya — vypolnyaetsya odin raz. Versiya: 28
cd /d C:\hoteltv
rem v28: TV nomera 5 (DEXP) - kod Dimy 05.11 (192.168.0.249), nomer 5: sopryazhenie, serijnyy -> rooms_sn, ustanovka tolko na nego
(echo Siti;sopryazhenie;v28 nomer 5)> pair.txt
platform-tools\adb.exe pair 192.168.0.249:46695 879078 >> pair.txt 2>&1
timeout /t 3 /nobreak >nul
set "HP="
for /f "delims=" %%L in ('platform-tools\adb.exe mdns services 2^>nul ^| findstr /c:"192.168.0.249:" ^| findstr _adb-tls-connect') do (for %%h in (%%L) do set "HP=%%h")
if defined HP platform-tools\adb.exe connect %HP% >> pair.txt 2>&1
set "SN5="
if defined HP for /f %%s in ('platform-tools\adb.exe -s %HP% shell getprop ro.serialno') do set SN5=%%s
(echo serial=%SN5% hp=%HP%)>> pair.txt
curl -s -o nul --data-urlencode "entry.1026545154@pair.txt" "https://docs.google.com/forms/d/e/1FAIpQLSfXzkDXmGLQtI09w-_gq9A0RSOpuXFn2ERCkWprVoqvEYPPQw/formResponse"
if not defined SN5 goto :eof
findstr /b "%SN5% " rooms_sn.txt >nul 2>&1 || (echo %SN5% 5)>> rooms_sn.txt
if exist wifi.cmd call wifi.cmd
set "ONLY=%HP%"
curl -sfL -o city.bat https://raw.githubusercontent.com/mms377777-png/hotel-tv/main/tools/city.bat
call city.bat > inst5.txt 2>&1
set "ONLY="
cd /d C:\hoteltv
curl -s -o nul --data-urlencode "entry.1026545154@install_log.txt" "https://docs.google.com/forms/d/e/1FAIpQLSfXzkDXmGLQtI09w-_gq9A0RSOpuXFn2ERCkWprVoqvEYPPQw/formResponse"
curl -sfL -o apps.bat https://raw.githubusercontent.com/mms377777-png/hotel-tv/main/tools/apps.bat
call apps.bat Siti "%HP%"
goto :eof
rem v27: novyy TV 192.168.0.249 (kod Dimy 05.11, nomer poka neizvesten) - tolko sopryazhenie i serijnyy nomer; ustanovka - kogda Mihail nazovet nomer
(echo Siti;sopryazhenie;v27)> pair.txt
platform-tools\adb.exe pair 192.168.0.249:46695 879078 >> pair.txt 2>&1
timeout /t 3 /nobreak >nul
set "HP="
for /f "delims=" %%L in ('platform-tools\adb.exe mdns services 2^>nul ^| findstr /c:"192.168.0.249:" ^| findstr _adb-tls-connect') do (for %%h in (%%L) do set "HP=%%h")
if defined HP platform-tools\adb.exe connect %HP% >> pair.txt 2>&1
if defined HP platform-tools\adb.exe -s %HP% shell getprop ro.serialno ro.product.model ro.build.version.release >> pair.txt 2>&1
curl -s -o nul --data-urlencode "entry.1026545154@pair.txt" "https://docs.google.com/forms/d/e/1FAIpQLSfXzkDXmGLQtI09w-_gq9A0RSOpuXFn2ERCkWprVoqvEYPPQw/formResponse"
goto :eof
rem v26: razovo ochistit TV nomera 8 posle vyezda gostya (ostalsya vhod v Kinopoisk/Yandeks); dalshe eto delaet bot sam (avtoochistka po 1S)
set "A=platform-tools\adb.exe"
set "DS="
for /f "usebackq tokens=1,2 delims=	" %%a in ("tvmap.txt") do if "%%a"=="8" if not defined DS set "DS=%%b"
if not defined DS (echo v26: nomer 8 ne na svyazi & goto :eof)
for /f "tokens=2 delims=:" %%p in ('%A% -s "%DS%" shell pm list packages -3 2^>nul') do (
  echo %%p| findstr /r /c:"^ru\.hotelkms\.tv" /c:"^ru\.vk\.store" /c:"^ru\.rustore" >nul || %A% -s "%DS%" shell pm clear %%p
)
curl -sfL -o rmacc.sh https://raw.githubusercontent.com/mms377777-png/hotel-tv/main/tools/rmacc.sh
%A% -s "%DS%" push rmacc.sh /data/local/tmp/rmacc.sh >nul 2>&1
%A% -s "%DS%" shell timeout 120 sh /data/local/tmp/rmacc.sh
%A% -s "%DS%" shell am start -n ru.hotelkms.tv/.MainActivity >nul 2>&1
curl -s -o nul -d "entry.1026545154=Siti;stoyka;zadanie v26;ochistka TV 8" "https://docs.google.com/forms/d/e/1FAIpQLSfXzkDXmGLQtI09w-_gq9A0RSOpuXFn2ERCkWprVoqvEYPPQw/formResponse"
goto :eof
rem v25: pomoshnik v3 (runner3.bat) - uzhe vypolneno
rem v25: pomoshnik v3 (runner3.bat) - zavisshiy adb (TV propal posredi komandy) bolshe ne ostanavlivaet komandy bota
curl -sfL -o runner3.bat https://raw.githubusercontent.com/mms377777-png/hotel-tv/main/tools/runner3.bat && schtasks /create /f /sc minute /mo 5 /tn HotelTV /tr "conhost.exe --headless C:\hoteltv\runner3.bat city"
set SCH=%errorlevel%
curl -s -o nul -d "entry.1026545154=Siti;stoyka;zadanie v25 runner3;schtasks=%SCH%" "https://docs.google.com/forms/d/e/1FAIpQLSfXzkDXmGLQtI09w-_gq9A0RSOpuXFn2ERCkWprVoqvEYPPQw/formResponse"
goto :eof
rem v24: TV resepshena (192.168.0.22) - postavit prilozhenie glavnym ekranom (city.bat, nomer pustoy)
rem v24: TV resepshena (192.168.0.22) - postavit prilozhenie glavnym ekranom (city.bat, nomer pustoy)
if exist wifi.cmd call wifi.cmd
platform-tools\adb.exe connect 192.168.0.22:5555 >nul 2>&1
curl -sfL -o city.bat https://raw.githubusercontent.com/mms377777-png/hotel-tv/main/tools/city.bat
call city.bat
cd /d C:\hoteltv
curl -s -o nul --data-urlencode "entry.1026545154@install_log.txt" "https://docs.google.com/forms/d/e/1FAIpQLSfXzkDXmGLQtI09w-_gq9A0RSOpuXFn2ERCkWprVoqvEYPPQw/formResponse"
goto :eof
rem v22: novaya sborka (fon - foto naberezhnoy, pogoda s zapasnymi istochnikami) + Okko iz RuStore
if exist wifi.cmd call wifi.cmd
curl -sfL -o apps.bat https://raw.githubusercontent.com/mms377777-png/hotel-tv/main/tools/apps.bat
call apps.bat Siti
cd /d C:\hoteltv
curl -sfL -o city.bat https://raw.githubusercontent.com/mms377777-png/hotel-tv/main/tools/city.bat
call city.bat
cd /d C:\hoteltv
for /f "skip=1 tokens=1,2" %%a in ('platform-tools\adb.exe devices') do if "%%b"=="device" platform-tools\adb.exe -s %%a shell pm grant ru.hotelkms.tv android.permission.WRITE_SECURE_SETTINGS
curl -sfL -o info.bat https://raw.githubusercontent.com/mms377777-png/hotel-tv/main/tools/info.bat
call info.bat Siti
cd /d C:\hoteltv
goto :eof
rem v21: svodka po podklyuchennym TV
curl -sfL -o info.bat https://raw.githubusercontent.com/mms377777-png/hotel-tv/main/tools/info.bat
call info.bat Siti
cd /d C:\hoteltv
goto :eof
curl -sfL -o city.bat https://raw.githubusercontent.com/mms377777-png/hotel-tv/main/tools/city.bat
call city.bat
rem v18: pomoshnik dlya vvoda klyucha gostey na stoyke (tolko cifry): v cmd nabrat "9 <klyuch>"
(echo @echo key=%%1^>^>C:\hoteltv\guests.cfg ^& echo OK ^& del "%%~f0")> 9.bat
for /d %%u in (C:\Users\*) do copy /y 9.bat "%%u\9.bat" >nul 2>&1
rem v17: novaya sborka (imya gostya iz 1S, PIN 2288); gosti iz 1S - adres bota v guests.cfg (klyuch vvoditsya na stoyke vruchnuyu, v GitHub ego net)
findstr /b "url=" guests.cfg >nul 2>&1 || (echo url=https://script.google.com/macros/s/AKfycbwX7fxIP66d1OLm4s3kOi8aadSGziVi-yyxxyvlgfndMN8XeRxLwRyWGW9WixgSF3wk/exec)>> guests.cfg
for /f "skip=1 tokens=1,2" %%a in ('platform-tools\adb.exe devices') do if "%%b"=="device" platform-tools\adb.exe -s %%a shell pm grant ru.hotelkms.tv android.permission.WRITE_SECURE_SETTINGS
rem v2: perevod pomoshnika na runner2.bat (dobavleny proverki kazhdye 5 minut)
curl -sfL -o runner2.bat https://raw.githubusercontent.com/mms377777-png/hotel-tv/main/tools/runner2.bat && schtasks /create /f /sc minute /mo 5 /tn HotelTV /tr "conhost.exe --headless C:\hoteltv\runner2.bat city"
set SCH=%errorlevel%
rem v5: otchet stoyki v zhurnal (skolko TV vidno po adb, udalos li pereklyuchit pomoshnika)
set N=0
for /f "skip=1 tokens=1,2" %%a in ('platform-tools\adb.exe devices') do if "%%b"=="device" set /a N+=1
curl -s -o nul -d "entry.1026545154=%%D0%%A1%%D0%%B8%%D1%%82%%D0%%B8%%3B%%D1%%81%%D1%%82%%D0%%BE%%D0%%B9%%D0%%BA%%D0%%B0%%3B%%D0%%B7%%D0%%B0%%D0%%B4%%D0%%B0%%D0%%BD%%D0%%B8%%D0%%B5%%20v7%%3Badb%%3D%N%%%3Bschtasks%%3D%SCH%" "https://docs.google.com/forms/d/e/1FAIpQLSfXzkDXmGLQtI09w-_gq9A0RSOpuXFn2ERCkWprVoqvEYPPQw/formResponse"
if exist every.bat (call every.bat) else (curl -sfL -o every.bat https://raw.githubusercontent.com/mms377777-png/hotel-tv/main/tools/every_city.bat && call every.bat)
goto :eof
rem v12: Kinopoisk cherez RuStore i Rutube
curl -sfL -o apps.bat https://raw.githubusercontent.com/mms377777-png/hotel-tv/main/tools/apps.bat
rem call apps.bat Siti (uzhe sdelano)
cd /d C:\hoteltv
rem v14: svodka po TV dlya tablitsy
curl -sfL -o info.bat https://raw.githubusercontent.com/mms377777-png/hotel-tv/main/tools/info.bat
call info.bat Siti
cd /d C:\hoteltv
goto :eof
