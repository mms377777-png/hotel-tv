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
platform-tools\adb.exe -s %S% shell "grep -o 'text=\"[^\"]*\"' /sdcard/u.xml | grep -v 'text=\"\"'" > ui.txt
chcp 65001 >nul
type ui.txt
