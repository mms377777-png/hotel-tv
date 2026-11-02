@echo off
cd /d C:\hoteltv
for %%d in (108 109 110 111 112) do (
 platform-tools\adb.exe connect 192.168.1.%%d:5555 >nul
 echo == 192.168.1.%%d
 platform-tools\adb.exe -s 192.168.1.%%d:5555 shell "dumpsys account | grep Account.{; pm list packages -3 | cut -d: -f2 | xargs echo"
 echo.
)
