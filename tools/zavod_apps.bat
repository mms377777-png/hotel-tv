@echo off
rem Zavodskaya: blokirovka (kak v Pushkine) + prilozheniya. Zapusk: C:\hoteltv\zavod_apps.bat
cd /d C:\hoteltv
set A=platform-tools\adb.exe
if exist lock_sn.txt del lock_sn.txt
for /f "skip=1 tokens=1,2" %%a in ('%A% devices') do if "%%b"=="device" call :lock %%a
call apps.bat Zavod
type apk.txt
goto :eof
:lock
set SN=
for /f %%s in ('%A% -s %1 shell getprop ro.serialno') do set SN=%%s
if exist lock_sn.txt findstr /x /c:"%SN%" lock_sn.txt >nul && goto :eof
echo %SN%>> lock_sn.txt
echo LOCK %SN%
%A% -s %1 shell "pm disable-user --user 0 com.android.vending; for p in $(pm list packages | cut -d: -f2); do appops set $p REQUEST_INSTALL_PACKAGES deny 2>/dev/null; done; settings put secure install_non_market_apps 0; echo LOCKED"
goto :eof
