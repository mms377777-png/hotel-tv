@echo off
rem Pomoshnik HotelTV v2: kazhdye 5 minut - every_<x>.bat (proverki), zatem odnorazovaya komanda job_<x>.bat, esli ona novaya.
rem Zapusk iz zadachi Windows "HotelTV": conhost.exe --headless C:\hoteltv\runner2.bat <pushkin|city>
cd /d C:\hoteltv
curl -sfL -o every_new.bat "https://raw.githubusercontent.com/mms377777-png/hotel-tv/main/tools/every_%1.bat" && copy /y every_new.bat every.bat >nul
if exist every.bat call every.bat > every_log.txt 2>&1
cd /d C:\hoteltv
curl -sfL -o job_new.bat "https://raw.githubusercontent.com/mms377777-png/hotel-tv/main/tools/job_%1.bat" || exit /b
fc /b job_new.bat job_last.bat >nul 2>&1 && exit /b
copy /y job_new.bat job_last.bat >nul
if exist wifi.cmd call wifi.cmd
echo ==== %date% %time% job_%1 >> job_log.txt
call job_last.bat >> job_log.txt 2>&1
