@echo off
rem Kazhdye 5 minut (Siti): esli poyavilsya novyy TV (vklyuchili otladku) - stavim prilozhenie i nastroyki.
setlocal enabledelayedexpansion
cd /d C:\hoteltv
set N=0
set LIST=
for /f "skip=1 tokens=1,2" %%a in ('platform-tools\adb.exe devices') do if "%%b"=="device" (set /a N+=1 & set "LIST=!LIST! %%a")
set OLD=
if exist devlist.txt set /p OLD=<devlist.txt
if "!LIST!"=="!OLD!" goto :eof
echo ==== %date% %time% novye TV: !LIST! >> job_log.txt
if exist wifi.cmd call wifi.cmd
call city.bat >> job_log.txt 2>&1
for /f "skip=1 tokens=1,2" %%a in ('platform-tools\adb.exe devices') do if "%%b"=="device" platform-tools\adb.exe -s %%a shell pm grant ru.hotelkms.tv android.permission.WRITE_SECURE_SETTINGS
(echo !LIST!)>devlist.txt
curl -s -o nul -d "entry.1026545154=%%D0%%A1%%D0%%B8%%D1%%82%%D0%%B8%%3B%%D1%%81%%D1%%82%%D0%%BE%%D0%%B9%%D0%%BA%%D0%%B0%%3B%%D0%%BD%%D0%%BE%%D0%%B2%%D1%%8B%%D0%%B5%%20%%D0%%A2%%D0%%92%%3Badb%%3D!N!" "https://docs.google.com/forms/d/e/1FAIpQLSfXzkDXmGLQtI09w-_gq9A0RSOpuXFn2ERCkWprVoqvEYPPQw/formResponse"
