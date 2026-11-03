@echo off
rem Pomoshnik HotelTV v3: kazhdye 5 minut - every_<x>.bat (proverki, komandy bota), zatem odnorazovaya komanda job_<x>.bat, esli ona novaya.
rem Zapusk iz zadachi Windows "HotelTV": conhost.exe --headless C:\hoteltv\runner3.bat <pushkin|city>
rem every_<x>.bat idet otdelnym processom (every.lock). Esli TV propal posredi komandy, adb zhdet ego beskonechno i zapusk visit;
rem togda cherez 2 sleduyushchih tika (~10 min) ubivaem adb - zavisshiy zapusk zavershaetsya, a novyy idet kak obychno.
setlocal enabledelayedexpansion
cd /d C:\hoteltv
if exist every.lock (
  set "W=0"
  if exist every.wait set /p W=<every.wait
  set /a W+=1
  if !W! GEQ 2 (
    taskkill /f /im adb.exe >nul 2>&1
    del every.lock >nul 2>&1
    curl -s -o nul -d "entry.1026545154=HotelTV;%1;zavisshiy adb perezapushchen" "https://docs.google.com/forms/d/e/1FAIpQLSfXzkDXmGLQtI09w-_gq9A0RSOpuXFn2ERCkWprVoqvEYPPQw/formResponse"
    set "W=0"
  )
  (echo !W!)> every.wait
  if exist every.lock goto :job
)
(echo 0)> every.wait
curl -sfL -o every_new.bat "https://raw.githubusercontent.com/mms377777-png/hotel-tv/main/tools/every_%1.bat" && copy /y every_new.bat every.bat >nul
rem adb-server zapuskaem do perenapravleniya v fayl - inache on derzhit zhurnal i sleduyushchie zapuski padayut ("fayl zanyat")
platform-tools\adb.exe start-server >nul 2>&1
del every_log.txt >nul 2>&1
set "EL=every_log.txt"
if exist every_log.txt set "EL=every_log2.txt"
(echo %date% %time%)> every.lock
if exist every.bat start "hoteltv-every" /b cmd /c "call every.bat > %EL% 2>&1 & del C:\hoteltv\every.lock"
:job
cd /d C:\hoteltv
curl -sfL -o job_new.bat "https://raw.githubusercontent.com/mms377777-png/hotel-tv/main/tools/job_%1.bat" || exit /b
fc /b job_new.bat job_last.bat >nul 2>&1 && exit /b
copy /y job_new.bat job_last.bat >nul
if exist wifi.cmd call wifi.cmd
set "JL=job_log.txt"
(echo ==== %date% %time% job_%1)>> job_log.txt || set "JL=job_log2.txt"
echo ==== %date% %time% job_%1 >> %JL%
call job_last.bat >> %JL% 2>&1
