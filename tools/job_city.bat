@echo off
rem Komanda dlya TV Siti Centra. Menyaetsya — vypolnyaetsya odin raz. Versiya: 19
cd /d C:\hoteltv
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
