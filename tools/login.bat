@echo off
rem login.bat <chast serijnogo> : otkryt vhod Google na TV i pokazat tekst ekrana
cd /d C:\hoteltv
set S=
for /f "tokens=1" %%a in ('platform-tools\adb.exe devices ^| findstr %1') do set S=%%a
if not defined S (echo NET TV %1 & goto :eof)
echo TV %S%
platform-tools\adb.exe -s %S% shell input keyevent 224
platform-tools\adb.exe -s %S% shell am start -a android.settings.ADD_ACCOUNT_SETTINGS --esa account_types com.google
timeout /t 8 >nul
platform-tools\adb.exe -s %S% shell uiautomator dump /sdcard/u.xml >nul
platform-tools\adb.exe -s %S% pull /sdcard/u.xml u.xml >nul
powershell -noprofile -command "([xml](gc u.xml -Encoding UTF8)).SelectNodes('//node') | %% { $_.text } | ? { $_ } | Out-File -Encoding utf8 ui.txt" 2>nul
type ui.txt
