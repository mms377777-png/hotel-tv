@echo off
rem Ustanovka pomoshnika: setup.bat <pushkin|city> <WiFi SSID> <WiFi parol>
cd /d C:\hoteltv
> wifi.cmd echo set WSSID=%~2
>> wifi.cmd echo set WPASS=%~3
curl -sfL -o runner.bat https://raw.githubusercontent.com/mms377777-png/hotel-tv/main/tools/runner.bat
schtasks /create /f /sc minute /mo 5 /tn HotelTV /tr "conhost.exe --headless C:\hoteltv\runner.bat %1"
schtasks /run /tn HotelTV
echo GOTOVO: pomoshnik HotelTV ustanovlen dlya %1
