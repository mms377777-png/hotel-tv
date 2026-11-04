@echo off
rem Kazhdye 5 minut (Zavodskaya): pereподключение TV po mdns, schet TV na svyazi (v zhurnal pri izmenenii), komandy bota (tvcare).
setlocal enabledelayedexpansion
cd /d C:\hoteltv
platform-toolsdb.exe start-server >nul 2>&1
for /f "delims=" %L in ('platform-toolsdb.exe mdns services 2^>nul ^| findstr _adb-tls-connect') do (
  for %h in (%L) do set "HP=%h"
  platform-toolsdb.exe connect !HP! >nul 2>&1
)
set N2=0
for /f "skip=1 tokens=1,2" %a in ('platform-toolsdb.exe devices') do if "%b"=="device" set /a N2+=1
set "LN="
if exist tv_count.txt set /p LN=<tv_count.txt
if not "!N2!"=="!LN!" (curl -s -o nul -d "entry.1026545154=Zavodskaya;stoyka;TV na svyazi;!N2!" "https://docs.google.com/forms/d/e/1FAIpQLSfXzkDXmGLQtI09w-_gq9A0RSOpuXFn2ERCkWprVoqvEYPPQw/formResponse" & (echo !N2!)>tv_count.txt)
rem novye TV (sopryazheny vruchnuyu, no bez prilozheniya) - zavod.bat stavit prilozhenie tolko na te, gde ego net (DUP dlya ostalnyh)
for /f "skip=1 tokens=1,2" %a in ('platform-toolsdb.exe devices') do if "%b"=="device" (
  platform-toolsdb.exe -s %a shell pm path ru.hotelkms.tv >nul 2>&1 || set NEW=1
)
if defined NEW (curl -sfL -o zavod.bat https://raw.githubusercontent.com/mms377777-png/hotel-tv/main/tools/zavod.bat && call zavod.bat >nul 2>&1 & cd /d C:\hoteltv & curl -s -o nul --data-urlencode "entry.1026545154@install_log.txt" "https://docs.google.com/forms/d/e/1FAIpQLSfXzkDXmGLQtI09w-_gq9A0RSOpuXFn2ERCkWprVoqvEYPPQw/formResponse")
rem Dogonyaem TV (versiya, prilozheniya) i komandy bota-tekhnika
curl -sfL -o tvcare.bat https://raw.githubusercontent.com/mms377777-png/hotel-tv/main/tools/tvcare.bat
call tvcare.bat zavod
