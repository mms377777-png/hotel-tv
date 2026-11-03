@echo off
rem Kinopoisk i Okko (cherez RuStore) i Rutube (pryamaya ssylka) na vse TV. Zapusk: call apps.bat <Pushkin|Siti>
cd /d C:\hoteltv
set A=platform-tools\adb.exe
curl -sfL -o RuStoreTV.apk https://static.rustore.ru/release/RuStoreTV.apk
curl -sfL -o rt.apk https://rutube.ru/androidtv/latest/
curl -sfL -o rustore.sh https://raw.githubusercontent.com/mms377777-png/hotel-tv/main/tools/rustore.sh
echo %1;apk;> apk.txt
for %%F in (RuStoreTV.apk rt.apk) do echo %%F %%~zF >> apk.txt
if exist done_sn.txt del done_sn.txt
for /f "skip=1 tokens=1,2" %%a in ('%A% devices') do if "%%b"=="device" call :one %%a
curl -s -o nul --data-urlencode "entry.1026545154@apk.txt" "https://docs.google.com/forms/d/e/1FAIpQLSfXzkDXmGLQtI09w-_gq9A0RSOpuXFn2ERCkWprVoqvEYPPQw/formResponse"
goto :eof
:one
set S=%1
set SN=
for /f %%s in ('%A% -s %S% shell getprop ro.serialno') do set SN=%%s
if exist done_sn.txt findstr /x /c:"%SN%" done_sn.txt >nul && goto :eof
echo %SN%>> done_sn.txt
echo [%S%] >> apk.txt
%A% -s %S% install -r rt.apk 2>&1 | find /v "Performing" >> apk.txt
%A% -s %S% install -r RuStoreTV.apk 2>&1 | find /v "Performing" >> apk.txt
for /f %%p in ('%A% -s %S% shell "pm list packages | grep -i -e vk.store -e rustore | cut -d: -f2"') do %A% -s %S% shell appops set %%p REQUEST_INSTALL_PACKAGES allow
rem v nomere zhivut gosti (na TV est imya gostya) - RuStore ne otkryvaem, chtoby ne meshat; postavim posle vyezda
set G=0
for /f %%g in ('%A% -s %S% shell "run-as ru.hotelkms.tv cat shared_prefs/hotel_tv.xml 2>/dev/null | grep -c 'guest_name..[^<]'"') do set G=%%g
if not "%G%"=="0" (echo gost v nomere - RuStore propushen >> apk.txt& goto :eof)
%A% -s %S% push rustore.sh /data/local/tmp/rustore.sh >nul 2>&1
%A% -s %S% shell sh /data/local/tmp/rustore.sh ru.kinopoisk.tv >> apk.txt 2>&1
%A% -s %S% shell sh /data/local/tmp/rustore.sh tv.okko.androidtv >> apk.txt 2>&1
goto :eof
