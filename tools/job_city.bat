@echo off
rem Komanda dlya TV Siti Centra. Menyaetsya — vypolnyaetsya odin raz. Versiya: 3
cd /d C:\hoteltv
curl -sfL -o city.bat https://raw.githubusercontent.com/mms377777-png/hotel-tv/main/tools/city.bat
call city.bat
for /f "skip=1 tokens=1,2" %%a in ('platform-tools\adb.exe devices') do if "%%b"=="device" platform-tools\adb.exe -s %%a shell pm grant ru.hotelkms.tv android.permission.WRITE_SECURE_SETTINGS
rem v2: perevod pomoshnika na runner2.bat (dobavleny proverki kazhdye 5 minut)
curl -sfL -o runner2.bat https://raw.githubusercontent.com/mms377777-png/hotel-tv/main/tools/runner2.bat && schtasks /change /tn HotelTV /tr "conhost.exe --headless C:\hoteltv\runner2.bat city"
