@echo off
rem Komanda dlya TV Pushkina. Menyaetsya — vypolnyaetsya odin raz. Versiya: 15
cd /d C:\hoteltv
curl -sfL -o pushkin.bat https://raw.githubusercontent.com/mms377777-png/hotel-tv/main/tools/pushkin.bat
call pushkin.bat
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
