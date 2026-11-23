@echo off
setlocal enabledelayedexpansion
rem Komanda dlya TV Zavodskoy. Menyaetsya - vypolnyaetsya odin raz. Versiya: 15
rem v15 (23.11.2026): TOLKO CHTENIE - pochemu stoyka ne avtorizovana na TV: klyuchi adb (adbkey) po profilyam, kto zapuskaet adb, versiya adb, mdns, devices.
cd /d C:\hoteltv
set "F=https://docs.google.com/forms/d/e/1FAIpQLSfXzkDXmGLQtI09w-_gq9A0RSOpuXFn2ERCkWprVoqvEYPPQw/formResponse"
set "A=platform-tools\adb.exe"
(
echo Zavodskaya;diag v15 %date% %time%
echo --- whoami:
whoami
echo --- adbkey po profilyam:
dir /a /tc "C:\Users\*\.android\adbkey*" 2>nul
dir /a /tc "C:\Windows\System32\config\systemprofile\.android\adbkey*" 2>nul
dir /a /tc "C:\hoteltv\.android\adbkey*" 2>nul
echo --- env ANDROID_*:
set ANDROID 2>nul
echo --- adb.exe processy:
tasklist /v /fi "imagename eq adb.exe" /fo list 2>nul | findstr /i "Image PID User"
echo --- adb version:
%A% version
echo --- adb devices -l:
%A% devices -l
echo --- mdns:
%A% mdns services
echo --- zadacha HotelTV:
schtasks /query /tn HotelTV /v /fo list 2>nul | findstr /i "Run Status Last Next Logon"
) > diag15.txt 2>&1
curl -s -o nul --data-urlencode "entry.1026545154@diag15.txt" "%F%"
endlocal
goto :eof
