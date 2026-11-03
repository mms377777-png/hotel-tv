@echo off
rem Pomoshnik HotelTV v2: kazhdye 5 minut - every_<x>.bat (proverki), zatem odnorazovaya komanda job_<x>.bat, esli ona novaya.
rem Zapusk iz zadachi Windows "HotelTV": conhost.exe --headless C:\hoteltv\runner2.bat <pushkin|city>
cd /d C:\hoteltv
curl -sfL -o every_new.bat "https://raw.githubusercontent.com/mms377777-png/hotel-tv/main/tools/every_%1.bat" && copy /y every_new.bat every.bat >nul
rem adb-server zapuskaem do perenapravleniya v fayl - inache on derzhit every_log.txt i sleduyushchie zapuski padayut ("fayl zanyat")
platform-tools\adb.exe start-server >nul 2>&1
del every_log.txt >nul 2>&1
set "EL=every_log.txt"
if exist every_log.txt set "EL=every_log2.txt"
if exist every.bat call every.bat > %EL% 2>&1
cd /d C:\hoteltv
curl -sfL -o job_new.bat "https://raw.githubusercontent.com/mms377777-png/hotel-tv/main/tools/job_%1.bat" || exit /b
fc /b job_new.bat job_last.bat >nul 2>&1 && exit /b
copy /y job_new.bat job_last.bat >nul
if exist wifi.cmd call wifi.cmd
set "JL=job_log.txt"
(echo ==== %date% %time% job_%1)>> job_log.txt || set "JL=job_log2.txt"
echo ==== %date% %time% job_%1 >> %JL%
call job_last.bat >> %JL% 2>&1
