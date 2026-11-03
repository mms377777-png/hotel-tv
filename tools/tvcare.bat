@echo off
rem Kazhdye 5 minut: 1) dogonyaem TV, kotorye propustili obnovlenie (byli vyklyucheny): novaya versiya prilozheniya, Rutube/Kinopoisk/Okko;
rem 2) vypolnyaem komandy bota-tekhnika iz gruppy administratorov (perezapusk prilozheniya, imya gostya, perezagruzka TV i t.d.).
rem Zapusk: call tvcare.bat <pushkin|city>
setlocal enabledelayedexpansion
cd /d C:\hoteltv
set "A=platform-tools\adb.exe"
set "H=%~1"
if /i "%H%"=="city" (set "HN=Siti") else (set "HN=Pushkin")
curl -sfL -o tvinfo.sh https://raw.githubusercontent.com/mms377777-png/hotel-tv/main/tools/tvinfo.sh
curl -sfL -o apkver_new.txt https://github.com/mms377777-png/hotel-tv/releases/download/latest/version.txt
set LV=0
if exist apkver_new.txt set /p LV=<apkver_new.txt
set HV=0
if exist apkver_have.txt set /p HV=<apkver_have.txt
type nul > tvmap.txt
for /f "skip=1 tokens=1,2 delims=	" %%a in ('%A% devices') do if "%%b"=="device" call :dev "%%a"
rem --- komandy bota ---
if not exist guests.cfg goto :catchup
set "URL=" & set "KEY="
for /f "usebackq tokens=1,* delims==" %%a in ("guests.cfg") do (
  if "%%a"=="url" set "URL=%%b"
  if "%%a"=="key" set "KEY=%%b"
)
if not defined KEY goto :catchup
curl -sL -o tvq.txt "%URL%?a=tvq&h=%H%&k=%KEY%"
for /f "usebackq tokens=1-3 delims=|" %%a in ("tvq.txt") do call :cmd %%a %%b %%c
:catchup
for /f "usebackq tokens=1-5 delims=	" %%a in ("tvmap.txt") do call :fix "%%b" %%a %%c %%d %%e
goto :eof

:fix
set "S=%~1" & set "R=%2" & set "V=%3" & set "G=%4" & set "AP=%5"
if !LV! GTR 0 if !V! GTR 0 if !V! LSS !LV! call :upd
if "!G!"=="0" if not "!AP!"=="111" call :apps
goto :eof

:dev
set "S=%~1"
%A% -s "%S%" push tvinfo.sh /data/local/tmp/tvinfo.sh >nul 2>&1
set "INFO="
for /f "delims=" %%i in ('%A% -s "%S%" shell sh /data/local/tmp/tvinfo.sh 2^>nul') do set "INFO=%%i"
if not defined INFO goto :eof
set R=0& set V=0& set G=0& set RT=1& set KP=1& set OK=1
for /f "tokens=1-6" %%a in ("!INFO!") do (set "R=%%a"& set "V=%%b"& set "G=%%c"& set "RT=%%d"& set "KP=%%e"& set "OK=%%f")
if /i "!R!"=="none" set "R=0"
(echo !R!	!S!	!V!	!G!	!RT!!KP!!OK!)>> tvmap.txt
goto :eof

:upd
if not "!HV!"=="!LV!" (curl -sfL -o hotel-tv.apk https://github.com/mms377777-png/hotel-tv/releases/download/latest/hotel-tv.apk && (echo !LV!)> apkver_have.txt & set "HV=!LV!")
%A% -s "%S%" install -r hotel-tv.apk > upd.txt 2>&1
%A% -s "%S%" shell pm grant ru.hotelkms.tv android.permission.WRITE_SECURE_SETTINGS >nul 2>&1
%A% -s "%S%" shell am start -n ru.hotelkms.tv/.MainActivity >nul 2>&1
findstr /c:"Success" upd.txt >nul && set "RES=ok" || set "RES=oshibka"
curl -s -o nul -d "entry.1026545154=%HN%;obnovlenie;!R!;!V! na !LV! !RES!" "https://docs.google.com/forms/d/e/1FAIpQLSfXzkDXmGLQtI09w-_gq9A0RSOpuXFn2ERCkWprVoqvEYPPQw/formResponse"
goto :eof

:apps
set "M=apps_!S::=_!"
set "M=!M:.=_!"
set "M=!M: =_!"
set "M=!M:(=_!"
set "M=!M:)=_!"
set "LD="
if exist "!M!.txt" set /p LD=<"!M!.txt"
if "!LD!"=="%date%" goto :eof
(echo %date%)> "!M!.txt"
curl -sfL -o apps.bat https://raw.githubusercontent.com/mms377777-png/hotel-tv/main/tools/apps.bat
call apps.bat %HN% "%S%"
cd /d C:\hoteltv
goto :eof

:cmd
set "ID=%~1" & set "RM=%~2" & set "AC=%~3"
set "DS="
for /f "usebackq tokens=1,2 delims=	" %%a in ("tvmap.txt") do if "%%a"=="%RM%" if not defined DS set "DS=%%b"
set "RES=off"
if not defined DS goto :rep
set "RES=ok"
if "%AC%"=="restart_app" (%A% -s "!DS!" shell am force-stop ru.hotelkms.tv & %A% -s "!DS!" shell am start -n ru.hotelkms.tv/.MainActivity >nul 2>&1)
if "%AC%"=="reboot_tv" %A% -s "!DS!" reboot >nul 2>&1
if "%AC%"=="resend_guest" (del /q guests_state\* >nul 2>&1)
if "%AC%"=="reinstall_app" call :reinst
if "%AC%"=="clear_accounts" (curl -sfL -o rmacc.sh https://raw.githubusercontent.com/mms377777-png/hotel-tv/main/tools/rmacc.sh & %A% -s "!DS!" push rmacc.sh /data/local/tmp/rmacc.sh >nul 2>&1 & %A% -s "!DS!" shell sh /data/local/tmp/rmacc.sh >nul 2>&1 & %A% -s "!DS!" shell am start -n ru.hotelkms.tv/.MainActivity >nul 2>&1)
:rep
curl -sL -o nul "%URL%?a=tvr&k=%KEY%&id=%ID%&r=!RES!"
goto :eof

:reinst
curl -sfL -o hotel-tv.apk https://github.com/mms377777-png/hotel-tv/releases/download/latest/hotel-tv.apk
%A% -s "!DS!" install -r hotel-tv.apk > upd.txt 2>&1
findstr /c:"Success" upd.txt >nul || set "RES=err"
%A% -s "!DS!" shell pm grant ru.hotelkms.tv android.permission.WRITE_SECURE_SETTINGS >nul 2>&1
%A% -s "!DS!" shell cmd package set-home-activity ru.hotelkms.tv/.MainActivity >nul 2>&1
%A% -s "!DS!" shell cmd role add-role-holder --user 0 android.app.role.HOME ru.hotelkms.tv >nul 2>&1
%A% -s "!DS!" shell pm disable-user --user 0 com.google.android.tvlauncher >nul 2>&1
%A% -s "!DS!" shell am start -n ru.hotelkms.tv/.MainActivity >nul 2>&1
goto :eof
