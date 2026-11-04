@echo off
rem Zavodskaya: udalit lishnie prilozheniya so vseh TV na svyazi. Zapusk: C:\hoteltv\zavod_clean.bat
cd /d C:\hoteltv
set A=platform-toolsdb.exe
for /f "skip=1 tokens=1,2" %%a in ('%A% devices') do if "%%b"=="device" call :one %%a
goto :eof
:one
echo ---- %1
for %%p in (mobi.zona limehd.ru.ctv com.google.android.videos ru.more.play) do %A% -s %1 shell pm uninstall --user 0 %%p
goto :eof
