@echo off
rem Svodka po vsem TV v zhurnal: call info.bat <Pushkin|Siti>
cd /d C:\hoteltv
set A=platform-tools\adb.exe
curl -sfL -o info.sh https://raw.githubusercontent.com/mms377777-png/hotel-tv/main/tools/info.sh
echo %1;info;> info.txt
if exist done_sn.txt del done_sn.txt
for /f "skip=1 tokens=1,2" %%a in ('%A% devices') do if "%%b"=="device" call :one %%a
curl -s -o nul --data-urlencode "entry.1026545154@info.txt" "https://docs.google.com/forms/d/e/1FAIpQLSfXzkDXmGLQtI09w-_gq9A0RSOpuXFn2ERCkWprVoqvEYPPQw/formResponse"
goto :eof
:one
set SN=
for /f %%s in ('%A% -s %1 shell getprop ro.serialno') do set SN=%%s
if exist done_sn.txt findstr /x /c:"%SN%" done_sn.txt >nul && goto :eof
echo %SN%>> done_sn.txt
%A% -s %1 push info.sh /data/local/tmp/info.sh >nul 2>&1
%A% -s %1 shell sh /data/local/tmp/info.sh >> info.txt 2>&1
goto :eof
