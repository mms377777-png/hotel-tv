@echo off
rem Pomoshnik HotelTV: raz v 5 minut beret komandu dlya TV iz GitHub i vypolnyaet, esli ona novaya.
rem Zapusk iz zadachi Windows "HotelTV": conhost.exe --headless C:\hoteltv\runner.bat <pushkin|city>
cd /d C:\hoteltv
curl -sfL -o job_new.bat "https://raw.githubusercontent.com/mms377777-png/hotel-tv/main/tools/job_%1.bat" || exit /b
fc /b job_new.bat job_last.bat >nul 2>&1 && exit /b
copy /y job_new.bat job_last.bat >nul
if exist wifi.cmd call wifi.cmd
echo ==== %date% %time% job_%1 >> job_log.txt
call job_last.bat >> job_log.txt 2>&1
