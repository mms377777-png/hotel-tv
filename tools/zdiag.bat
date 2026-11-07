@echo off
rem 07.11.2026: razovaya diagnostika stoyki Zavodskoy - pochemu ne vidit TV (s 01:18 TV ne shlyut zamery)
cd /d C:\hoteltv
set "A=platform-tools\adb.exe"
(
echo Zavodskaya;zdiag;stoyka zhiva %date% %time%
echo --- ipconfig:
ipconfig | findstr /i "IPv4 Gateway Shlyuz adapter"
echo --- adb devices:
%A% devices
echo --- mdns:
%A% mdns services 2^>nul | find /c "_adb-tls-connect"
echo --- ping shlyuz i TV:
for /f "tokens=2 delims=:" %%g in ('ipconfig ^| findstr /i "Gateway Shlyuz"') do for %%x in (%%g) do ping -n 1 -w 800 %%x | findstr /i "TTL"
for /f "tokens=1" %%i in (rooms_ip.txt) do ping -n 1 -w 500 %%i | findstr /i "TTL"
echo --- arp 192.168:
arp -a | find /c "192.168"
echo --- internet:
curl -s -o nul -w "%%{http_code}" https://www.google.com
echo.
echo --- schtasks:
schtasks /query /fo list 2^>nul | findstr /i "hotel every"
) > zdiag.txt 2>&1
curl -s -o nul --data-urlencode "entry.1026545154@zdiag.txt" "https://docs.google.com/forms/d/e/1FAIpQLSfXzkDXmGLQtI09w-_gq9A0RSOpuXFn2ERCkWprVoqvEYPPQw/formResponse"
