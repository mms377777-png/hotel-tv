@echo off
rem Komanda dlya TV Pushkina. Menyaetsya — vypolnyaetsya odin raz. Versiya: 8
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
rem v8: spisok uchetok na TV i ekran "Akkaunty" (dlya udaleniya uchetok prezhnih gostey)
for %%I in (110 111 112) do (
  echo Pushkin;uchetki;192.168.1.%%I> acc.txt
  platform-tools\adb.exe -s 192.168.1.%%I:5555 shell "dumpsys account | grep 'Account {' | tr -d '\r\n'" >> acc.txt
  platform-tools\adb.exe -s 192.168.1.%%I:5555 shell "am start -a android.settings.SYNC_SETTINGS >/dev/null; sleep 4; uiautomator dump /sdcard/ui.xml >/dev/null; grep -o 'text=\"[^\"]*\"' /sdcard/ui.xml | tr '\n' ' '; input keyevent KEYCODE_HOME" >> acc.txt
  curl -s -o nul --data-urlencode "entry.1026545154@acc.txt" "https://docs.google.com/forms/d/e/1FAIpQLSfXzkDXmGLQtI09w-_gq9A0RSOpuXFn2ERCkWprVoqvEYPPQw/formResponse"
)
