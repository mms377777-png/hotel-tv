@echo off
rem Kazhdye 5 minut: 1) dogonyaem TV, kotorye propustili obnovlenie (byli vyklyucheny): novaya versiya prilozheniya, Rutube/Kinopoisk/Okko;
rem 2) vypolnyaem komandy bota-tekhnika iz gruppy administratorov (perezapusk prilozheniya, imya gostya, perezagruzka TV i t.d.).
rem Zapusk: call tvcare.bat <pushkin|city>
setlocal enabledelayedexpansion
cd /d C:\hoteltv
set "APPSDONE="
set "A=platform-tools\adb.exe"
set "H=%~1"
if /i "%H%"=="city" (set "HN=Siti") else if /i "%H%"=="zavod" (set "HN=Zavodskaya") else (set "HN=Pushkin")
curl -sfL -o tvinfo.sh https://raw.githubusercontent.com/mms377777-png/hotel-tv/main/tools/tvinfo.sh
curl -sfL -o apkver_new.txt https://github.com/mms377777-png/hotel-tv/releases/download/latest/version.txt
set LV=0
if exist apkver_new.txt set /p LV=<apkver_new.txt
set HV=0
if exist apkver_have.txt set /p HV=<apkver_have.txt
type nul > tvmap.txt
rem 06.11.2026: odin TV byvaet podklyuchen dvazhdy (ip:port i mdns-imya) - beryom tolko pervoe podklyuchenie (klyuch: serijnyy nomer + komnata)
set "SEEN= "
set "F=https://docs.google.com/forms/d/e/1FAIpQLSfXzkDXmGLQtI09w-_gq9A0RSOpuXFn2ERCkWprVoqvEYPPQw/formResponse"
for /f "skip=1 tokens=1,2 delims=	" %%a in ('%A% devices') do if "%%b"=="device" call :dev "%%a"
rem --- komandy bota ---
if not exist guests.cfg goto :catchup
set "URL=" & set "KEY="
for /f "usebackq tokens=1,* delims==" %%a in ("guests.cfg") do (
  if "%%a"=="url" set "URL=%%b"
  if "%%a"=="key" set "KEY=%%b"
)
if not defined KEY goto :catchup
rem 9.bat zapisal klyuch s probelom v kontse - ubiraem probely, inache curl ne otpravlyaet zapros ("Malformed input")
set "KEY=!KEY: =!"
rem 06.11.2026: soobshchaem botu, kakie TV vidim: nomer:versiya:RKOI (Rutube, Kinopoisk, Okko, ivi) - bot znaet, kto na svyazi i chego ne hvataet (storozh svyazi)
set "D="
for /f "usebackq tokens=1,3,5 delims=	" %%a in ("tvmap.txt") do set "D=!D!%%a:%%b:%%c,"
curl -sL -G -o nul "%URL%" --data-urlencode "a=tvseen" --data-urlencode "h=%H%" --data-urlencode "k=!KEY!" --data-urlencode "d=!D!"
rem staryy spisok udalyaem: pri pustom otvete curl fayl ne perezapisyvaet i komandy vypolnilis by snova
if exist tvq.txt del tvq.txt
curl -sL -G -o tvq.txt "%URL%" --data-urlencode "a=tvq" --data-urlencode "h=%H%" --data-urlencode "k=!KEY!"
if exist tvq.txt for /f "usebackq tokens=1-3 delims=|" %%a in ("tvq.txt") do call :cmd %%a %%b %%c
rem kody sopryazheniya ot tehnika (foto v gruppe "Kms internet" -> bot -> list TV-kody): stoyka sama sopryagaet i stavit prilozhenie
if exist tvp.txt del tvp.txt
curl -sL -G -o tvp.txt "%URL%" --data-urlencode "a=tvpair" --data-urlencode "h=%H%" --data-urlencode "k=!KEY!"
if exist tvp.txt for /f "usebackq tokens=1-4 delims=|" %%a in ("tvp.txt") do call :pair %%a %%b %%c %%d
rem imena gostey na TV bez PowerShell (na stoyke Siti PowerShell zavisaet): bot otdaet gotovuyu stroku base64 dlya GuestReceiver
if /i "%H%"=="city" call :guestsync
:catchup
for /f "usebackq tokens=1-5 delims=	" %%a in ("tvmap.txt") do call :fix "%%b" %%a %%c %%d %%e
goto :eof

:fix
set "S=%~1" & set "R=%2" & set "V=%3" & set "G=%4" & set "AP=%5"
if !LV! GTR 0 if !V! GTR 0 if !V! LSS !LV! call :upd
rem prilozheniya dogonyaem ne bolshe chem na odnom TV za zapusk: ustanovka idet minutami, a zapusk dolzhen ukladyvatsya v 5 minut (inache komandy bota zhdut)
rem 06.11.2026 (Mikhail): stavim i pri goste v nomere - pri pervoy vozmozhnosti, kogda TV vklyuchen
if not defined APPSDONE if not "!AP!"=="1111" call :apps
rem 07.11.2026: razovaya diagnostika PIN 18+ (otkuda zapros) - odin raz na kazhdyy TV, rezultat v zhurnal
rem 07.11.2026: storozh tyunera v prilozhenii - razresheniya (istoriya ekranov, otkryt svoy ekran), odin raz na TV
if not exist "perm1_!R!.txt" call :perm "%S%" & (echo ok)> "perm1_!R!.txt"
if !V! GEQ 110 if not exist "tgcheck110_!R!.txt" call :tgcheck
rem 07.11.2026: zhivaya proverka storozha tyunera - odin raz na TV resepshena Siti (gostya net): otkryt tyuner, cherez 40 s posmotret, chto na ekrane
if /i "%H%"=="city" if "!R!"=="0" if !V! GEQ 110 if not exist tgtest110.txt call :tgtest
if not exist "pindiag_!R!.txt" call :pindiag
if not exist "pindiag2_!R!.txt" call :pindiag2
if not exist "pindiag3_!R!.txt" call :pindiag3
goto :eof

:pindiag3
curl -sfL -o pindiag3.sh https://raw.githubusercontent.com/mms377777-png/hotel-tv/main/tools/pindiag3.sh
%A% -s "%S%" push pindiag3.sh /data/local/tmp/pindiag3.sh >nul 2>&1
<nul set /p "=%HN%;pin_diag3;!R!; " > "pindiag3_!R!.txt"
%A% -s "%S%" shell sh /data/local/tmp/pindiag3.sh >> "pindiag3_!R!.txt" 2>&1
findstr /c:"kanalov=" "pindiag3_!R!.txt" >nul || (del "pindiag3_!R!.txt" & goto :eof)
curl -s -o nul --data-urlencode "entry.1026545154@pindiag3_!R!.txt" "%F%"
goto :eof

:pindiag2
curl -sfL -o pindiag2.sh https://raw.githubusercontent.com/mms377777-png/hotel-tv/main/tools/pindiag2.sh
%A% -s "%S%" push pindiag2.sh /data/local/tmp/pindiag2.sh >nul 2>&1
<nul set /p "=%HN%;pin_diag2;!R!; " > "pindiag2_!R!.txt"
%A% -s "%S%" shell sh /data/local/tmp/pindiag2.sh >> "pindiag2_!R!.txt" 2>&1
findstr /c:"tz=" "pindiag2_!R!.txt" >nul || (del "pindiag2_!R!.txt" & goto :eof)
curl -s -o nul --data-urlencode "entry.1026545154@pindiag2_!R!.txt" "%F%"
goto :eof

:perm
rem storozh tyunera (TunerGuard): istoriya ekranov, otkryt ekran prilozheniya iz fona, chislo kanalov
%A% -s "%~1" shell appops set ru.hotelkms.tv GET_USAGE_STATS allow >nul 2>&1
%A% -s "%~1" shell appops set ru.hotelkms.tv SYSTEM_ALERT_WINDOW allow >nul 2>&1
%A% -s "%~1" shell pm grant ru.hotelkms.tv com.android.providers.tv.permission.READ_EPG_DATA >nul 2>&1
goto :eof

:tgtest
%A% -s "%S%" shell am start -n com.mediatek.wwtv.tvcenter/.nav.TurnkeyUiMainActivity >nul 2>&1
timeout /t 5 /nobreak >nul
set "F1="
for /f "delims=" %%f in ('%A% -s "%S%" shell "dumpsys window | grep mCurrentFocus" 2^>nul') do set "F1=%%f"
timeout /t 40 /nobreak >nul
set "F2="
for /f "delims=" %%f in ('%A% -s "%S%" shell "dumpsys window | grep mCurrentFocus" 2^>nul') do set "F2=%%f"
(echo %HN%;tg_test;!R!; cherez 5 s: !F1! ^| cherez 45 s: !F2!)> tgtest110.txt
curl -s -o nul --data-urlencode "entry.1026545154@tgtest110.txt" "%F%"
goto :eof

:tgcheck
curl -sfL -o tgcheck.sh https://raw.githubusercontent.com/mms377777-png/hotel-tv/main/tools/tgcheck.sh
%A% -s "%S%" push tgcheck.sh /data/local/tmp/tgcheck.sh >nul 2>&1
<nul set /p "=%HN%;tg_check;!R!; " > "tgcheck110_!R!.txt"
%A% -s "%S%" shell sh /data/local/tmp/tgcheck.sh >> "tgcheck110_!R!.txt" 2>&1
findstr /c:"usage=" "tgcheck110_!R!.txt" >nul || (del "tgcheck110_!R!.txt" & goto :eof)
curl -s -o nul --data-urlencode "entry.1026545154@tgcheck110_!R!.txt" "%F%"
goto :eof

:pindiag
if not exist pindiag.sh curl -sfL -o pindiag.sh https://raw.githubusercontent.com/mms377777-png/hotel-tv/main/tools/pindiag.sh
%A% -s "%S%" push pindiag.sh /data/local/tmp/pindiag.sh >nul 2>&1
<nul set /p "=%HN%;pin_diag;!R!; " > "pindiag_!R!.txt"
%A% -s "%S%" shell sh /data/local/tmp/pindiag.sh >> "pindiag_!R!.txt" 2>&1
curl -s -o nul --data-urlencode "entry.1026545154@pindiag_!R!.txt" "%F%"
goto :eof

:dev
set "S=%~1"
%A% -s "%S%" push tvinfo.sh /data/local/tmp/tvinfo.sh >nul 2>&1
set "INFO="
for /f "delims=" %%i in ('%A% -s "%S%" shell sh /data/local/tmp/tvinfo.sh 2^>nul') do set "INFO=%%i"
if not defined INFO goto :eof
set R=0& set V=0& set G=0& set RT=1& set KP=1& set OK=1& set IV=1& set "SN="
for /f "tokens=1-8" %%a in ("!INFO!") do (set "R=%%a"& set "V=%%b"& set "G=%%c"& set "RT=%%d"& set "KP=%%e"& set "OK=%%f"& if not "%%g"=="" set "IV=%%g"& set "SN=%%h")
if /i "!R!"=="none" set "R=0"
if "!SN!"=="x" set "SN="
if "!R!"=="0" set "SN="
rem goto vnutri bloka/for zdes nelzya - lomaet perebor TV v vyzyvayushchem for; poetomu flag DUP
set "DUP="
if defined SN for %%k in (" !SN!_!R! ") do if not "!SEEN:%%~k=!"=="!SEEN!" set "DUP=1"
if defined DUP goto :eof
if defined SN set "SEEN=!SEEN!!SN!_!R! "
(echo !R!	!S!	!V!	!G!	!RT!!KP!!OK!!IV!)>> tvmap.txt
goto :eof

:upd
if not "!HV!"=="!LV!" (curl -sfL -o hotel-tv.apk https://github.com/mms377777-png/hotel-tv/releases/download/latest/hotel-tv.apk && (echo !LV!)> apkver_have.txt & set "HV=!LV!")
rem 06.11.2026: chto na ekrane do obnovleniya - esli gost smotrit drugoe prilozhenie, nash ekran posle obnovleniya ne otkryvaem (ne vybivaem gostya)
set "FG="
for /f "delims=" %%f in ('%A% -s "%S%" shell "dumpsys window | grep mCurrentFocus" 2^>nul') do set "FG=%%f"
set "OURS=1"
if defined FG set "OURS="
if defined FG if not "!FG:hotelkms=!"=="!FG!" set "OURS=1"
if defined FG if not "!FG:launcher=!"=="!FG!" set "OURS=1"
%A% -s "%S%" install -r hotel-tv.apk > upd.txt 2>&1
%A% -s "%S%" shell pm grant ru.hotelkms.tv android.permission.WRITE_SECURE_SETTINGS >nul 2>&1
call :perm "%S%"
if defined OURS %A% -s "%S%" shell am start -n ru.hotelkms.tv/.MainActivity >nul 2>&1
findstr /c:"Success" upd.txt >nul && set "RES=ok" || set "RES=oshibka"
rem 06.11.2026: pri oshibke v zhurnal - prichina iz otveta ustanovki (offline, mesto, podpis)
if "!RES!"=="ok" (<nul set /p "=%HN%;obnovlenie;!R!;!V! na !LV! ok" > updlog.txt) else (
  <nul set /p "=%HN%;obnovlenie;!R!;!V! na !LV! oshibka | prichina: " > updlog.txt
  findstr /i /c:"Failure" /c:"error" /c:"offline" /c:"not found" upd.txt >> updlog.txt || type upd.txt >> updlog.txt
)
curl -s -o nul --data-urlencode "entry.1026545154@updlog.txt" "%F%"
goto :eof

:reboot
rem 06.11.2026: TV vklyuchili menshe 15 minut nazad (rozetka) - perezagruzka ne nuzhna i sryvaet obnovlenie prilozheniya
set "UP=99999"
for /f "tokens=1 delims=. " %%u in ('%A% -s "!DS!" shell cat /proc/uptime 2^>nul') do set "UP=%%u"
if !UP! LSS 900 (
  curl -s -o nul --data-urlencode "entry.1026545154=%HN%;perezagruzka;!RM!;propushchena - TV vklyuchen !UP! s nazad" "%F%"
  goto :eof
)
%A% -s "!DS!" reboot >nul 2>&1
goto :eof

:apps
set "M=apps_!S::=_!"
set "M=!M:.=_!"
set "M=!M: =_!"
set "M=!M:(=_!"
set "M=!M:)=_!"
rem 06.11.2026: ne raz v den, a raz v 2 chasa, ne bolshe 3 popytok v den na odin TV (RuStore na ekrane u gostya ~1-2 min)
rem fayl: <data> <minuta dnya poslednej popytki> <popytok segodnya>
set "T=%time: =0%"
set /a NOWM=1%T:~0,2%*60-6000+1%T:~3,2%-100
set "LD=" & set "LM=0" & set "LN=0"
if exist "!M!.txt" for /f "usebackq tokens=1-3" %%x in ("!M!.txt") do (set "LD=%%x" & set "LM=%%y" & set "LN=%%z")
if not defined LN set "LN=0"
if not "!LD!"=="%date%" (set "LM=-999" & set "LN=0")
set /a GAP=NOWM-LM
if !LN! GEQ 3 goto :eof
if !GAP! LSS 120 goto :eof
set /a LN=LN+1
(echo %date% !NOWM! !LN!)> "!M!.txt"
set "APPSDONE=1"
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
if "%AC%"=="reboot_tv" call :reboot
if "%AC%"=="resend_guest" (del /q guests_state\* >nul 2>&1)
if "%AC%"=="reinstall_app" call :reinst
if "%AC%"=="install_ivi" call :ivi
if "%AC%"=="fix_ivi" call :fixivi
if "%AC%"=="clear_accounts" call :clearapps
if "%AC%"=="clear_accounts" (curl -sfL -o rmacc.sh https://raw.githubusercontent.com/mms377777-png/hotel-tv/main/tools/rmacc.sh & %A% -s "!DS!" push rmacc.sh /data/local/tmp/rmacc.sh >nul 2>&1 & %A% -s "!DS!" shell sh /data/local/tmp/rmacc.sh >nul 2>&1 & %A% -s "!DS!" shell am start -n ru.hotelkms.tv/.MainActivity >nul 2>&1)
:rep
curl -sL -G -o nul "%URL%" --data-urlencode "a=tvr" --data-urlencode "k=!KEY!" --data-urlencode "id=%ID%" --data-urlencode "r=!RES!"
goto :eof

:ivi
rem ivi iz RuStore po zaprosu administratora - stavim i pri goste (gost sam prosit)
curl -sfL -o rustore.sh https://raw.githubusercontent.com/mms377777-png/hotel-tv/main/tools/rustore.sh
%A% -s "!DS!" push rustore.sh /data/local/tmp/rustore.sh >nul 2>&1
%A% -s "!DS!" shell timeout 100 sh /data/local/tmp/rustore.sh ru.ivi.client > ivi.txt 2>&1
rem uspekh - tolko esli rustore.sh napisal "OK" ili "uzhe est" (pustoy otvet = TV propal ili ustanovka oborvalas)
findstr /c:"ru.ivi.client OK" /c:"ru.ivi.client uzhe est" ivi.txt >nul || set "RES=err"
%A% -s "!DS!" shell am start -n ru.hotelkms.tv/.MainActivity >nul 2>&1
goto :eof

:guestsync
if exist gb64.txt del gb64.txt
curl -sL -G -o gb64.txt "%URL%" --data-urlencode "a=guests" --data-urlencode "f=b64" --data-urlencode "h=%H%" --data-urlencode "k=!KEY!"
if not exist gb64.txt goto :eof
set "GB="
set /p GB=<gb64.txt
if not defined GB goto :eof
if not exist guests_state md guests_state
for /f "usebackq tokens=2 delims=	" %%s in ("tvmap.txt") do call :gsend "%%s"
goto :eof

:gsend
set "S=%~1"
set "M=!S::=_!"
set "M=!M:.=_!"
set "M=!M: =_!"
set "M=!M:(=_!"
set "M=!M:)=_!"
set "OLD="
if exist "guests_state\!M!.b64" set /p OLD=<"guests_state\!M!.b64"
rem tot zhe spisok uzhe otpravlen na etot TV - ne dergaem TV kazhdye 5 minut
if "!OLD!"=="!GB!" goto :eof
%A% -s "%S%" shell am broadcast -n ru.hotelkms.tv/.GuestReceiver --es map !GB! > gr.txt 2>&1
rem otvet data=... - TV prinyal (staraya versiya prilozheniya otvechaet bez data - poprobuem v sleduyushchiy raz)
findstr /c:"data=" gr.txt >nul && (echo !GB!)> "guests_state\!M!.b64"
goto :eof

:clearapps
rem kak pri vyezde v guests.ps1: sbrosit dannye storonnih prilozheniy (vhody v Kinopoisk, Okko, ivi...), krome nashego i RuStore
for /f "tokens=2 delims=:" %%p in ('%A% -s "!DS!" shell pm list packages -3 2^>nul') do (
  echo %%p| findstr /r /c:"^ru\.hotelkms\.tv" /c:"^ru\.vk\.store" /c:"^ru\.rustore" >nul || %A% -s "!DS!" shell pm clear %%p >nul 2>&1
)
goto :eof

:fixivi
rem ivi pishet "Chto-to poshlo ne tak": sbrosit dannye ivi i zapustit zanovo; esli ivi net - RES=noivi
%A% -s "!DS!" shell pm clear ru.ivi.client > ivi.txt 2>&1
findstr /c:"Success" ivi.txt >nul || (set "RES=noivi" & goto :eof)
%A% -s "!DS!" shell monkey -p ru.ivi.client -c android.intent.category.LEANBACK_LAUNCHER 1 >nul 2>&1
goto :eof

:reinst
curl -sfL -o hotel-tv.apk https://github.com/mms377777-png/hotel-tv/releases/download/latest/hotel-tv.apk
%A% -s "!DS!" install -r hotel-tv.apk > upd.txt 2>&1
findstr /c:"Success" upd.txt >nul || set "RES=err"
%A% -s "!DS!" shell pm grant ru.hotelkms.tv android.permission.WRITE_SECURE_SETTINGS >nul 2>&1
call :perm "!DS!"
%A% -s "!DS!" shell cmd package set-home-activity ru.hotelkms.tv/.MainActivity >nul 2>&1
%A% -s "!DS!" shell cmd role add-role-holder --user 0 android.app.role.HOME ru.hotelkms.tv >nul 2>&1
%A% -s "!DS!" shell pm disable-user --user 0 com.google.android.tvlauncher >nul 2>&1
%A% -s "!DS!" shell am start -n ru.hotelkms.tv/.MainActivity >nul 2>&1
goto :eof

:pair
rem %1 stroka lista, %2 nomer, %3 ip:port sopryazheniya, %4 kod
set "PID=%~1" & set "PRM=%~2" & set "PHP=%~3" & set "PCD=%~4"
set "PRES=fail"
%A% pair %PHP% %PCD% > pair_out.txt 2>&1
findstr /c:"Successfully paired" pair_out.txt >nul || goto :prep
set "PRES=noconn"
for /f "tokens=1 delims=:" %%i in ("%PHP%") do set "PIP=%%i"
timeout /t 3 /nobreak >nul
set "PH="
for /f "delims=" %%L in ('%A% mdns services 2^>nul ^| findstr /c:"!PIP!:" ^| findstr _adb-tls-connect') do (for %%h in (%%L) do set "PH=%%h")
if not defined PH goto :prep
%A% connect !PH! >nul 2>&1
set "PSN="
for /f %%s in ('%A% -s !PH! shell getprop ro.serialno') do set "PSN=%%s"
if not defined PSN goto :prep
findstr /b "!PSN! " rooms_sn.txt >nul 2>&1 || (echo !PSN! %PRM%)>> rooms_sn.txt
rem ustanovka tolko na etot TV (ONLY) - ustanovshchik gostinitsy
set "ONLY=!PH!"
curl -sfL -o inst_%H%.bat https://raw.githubusercontent.com/mms377777-png/hotel-tv/main/tools/%H%.bat
call inst_%H%.bat > inst_pair.txt 2>&1
set "ONLY="
cd /d C:\hoteltv
set "PRES=ok"
curl -s -o nul --data-urlencode "entry.1026545154@install_log.txt" "https://docs.google.com/forms/d/e/1FAIpQLSfXzkDXmGLQtI09w-_gq9A0RSOpuXFn2ERCkWprVoqvEYPPQw/formResponse"
:prep
curl -sL -G -o nul "%URL%" --data-urlencode "a=tvpaired" --data-urlencode "k=!KEY!" --data-urlencode "id=%PID%" --data-urlencode "r=!PRES!"
goto :eof
