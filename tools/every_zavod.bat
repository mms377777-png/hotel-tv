@echo off
rem Kazhdye 5 minut (Zavodskaya): perepodklyuchenie TV po mdns, schet TV na svyazi (v zhurnal pri izmenenii), prilozhenie na novye TV, komandy bota (tvcare). Versiya 2
rem v2 (06.11.2026): v1 byl bit - v fayle propali %% i \ (platform-tools\adb.exe), every.bat padal s oshibkoy sintaksisa, lock ne snimalsya, tvcare ne zapuskalsya, kody tehnika ne zabiralis
setlocal enabledelayedexpansion
cd /d C:\hoteltv
set "A=platform-tools\adb.exe"
set "F=https://docs.google.com/forms/d/e/1FAIpQLSfXzkDXmGLQtI09w-_gq9A0RSOpuXFn2ERCkWprVoqvEYPPQw/formResponse"
rem adb-server zapuskaem zaranee: esli on startuet vnutri for /f, for zhdet ego vechno i pomoshnik zavisaet
%A% start-server >nul 2>&1
rem perepodklyuchenie TV po Wi-Fi: posledniy stolbec stroki mdns = ip:port
for /f "delims=" %%L in ('%A% mdns services 2^>nul ^| findstr _adb-tls-connect') do (
  set "HP="
  for %%h in (%%L) do set "HP=%%h"
  %A% connect !HP! >nul 2>&1
)
set N2=0
for /f "skip=1 tokens=1,2" %%a in ('%A% devices') do if "%%b"=="device" set /a N2+=1
set "LN="
if exist tv_count.txt set /p LN=<tv_count.txt
if not "!N2!"=="!LN!" (curl -s -o nul -d "entry.1026545154=Zavodskaya;stoyka;TV na svyazi;!N2!" "%F%" & (echo !N2!)>tv_count.txt)
rem novye TV (sopryazheny, no bez prilozheniya) - zavod.bat stavit prilozhenie tolko na te, gde ego net (DUP dlya ostalnyh)
set "NEW="
for /f "skip=1 tokens=1,2" %%a in ('%A% devices') do if "%%b"=="device" (
  %A% -s %%a shell pm path ru.hotelkms.tv >nul 2>&1 || set "NEW=1"
)
if defined NEW (
  curl -sfL -o zavod.bat https://raw.githubusercontent.com/mms377777-png/hotel-tv/main/tools/zavod.bat && call zavod.bat >nul 2>&1
  cd /d C:\hoteltv
  curl -s -o nul --data-urlencode "entry.1026545154@install_log.txt" "%F%"
)
rem Dogonyaem TV (versiya, prilozheniya) i komandy bota-tekhnika, kody sopryazheniya ot tehnika
cd /d C:\hoteltv
curl -sfL -o tvcare.bat https://raw.githubusercontent.com/mms377777-png/hotel-tv/main/tools/tvcare.bat
call tvcare.bat zavod
