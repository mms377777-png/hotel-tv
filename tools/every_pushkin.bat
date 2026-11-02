@echo off
rem Kazhdye 5 minut: proverka telefonov Pushkina. Pishet v zhurnal (Google Forma) tolko pri izmenenii i raz v chas.
setlocal enabledelayedexpansion
cd /d C:\hoteltv
set "F=https://docs.google.com/forms/d/e/1FAIpQLSfXzkDXmGLQtI09w-_gq9A0RSOpuXFn2ERCkWprVoqvEYPPQw/formResponse"
set "SC=%%3B"
set "P=%%D0%%9F%%D1%%83%%D1%%88%%D0%%BA%%D0%%B8%%D0%%BD%%3B%%D1%%82%%D0%%B5%%D0%%BB%%D0%%B5%%D1%%84%%D0%%BE%%D0%%BD%%3B"
set "ON=%%D0%%BD%%D0%%B0%%20%%D1%%81%%D0%%B2%%D1%%8F%%D0%%B7%%D0%%B8"
set "OFF=%%D0%%BD%%D0%%B5%%D1%%82%%20%%D1%%81%%D0%%B2%%D1%%8F%%D0%%B7%%D0%%B8"
set "T=%time: =0%"
set /a MIN=1%T:~3,2%-100
set HB=0
if %MIN% LSS 5 set HB=1
if not exist state mkdir state
for %%i in (122 200 201 202 203 204 205 206 208 209 210 211 212 213 214 215 216) do (
  set "S=OFF"
  ping -n 3 -w 1500 192.168.1.%%i | find "TTL=" >nul && set "S=ON"
  set "OLD="
  if exist state\%%i.txt set /p OLD=<state\%%i.txt
  set SEND=!HB!
  if not "!S!"=="!OLD!" set SEND=1
  if "!SEND!"=="1" (
    if "!S!"=="ON" (set "V=!ON!") else (set "V=!OFF!")
    curl -s -o nul -d "entry.1026545154=!P!192.168.1.%%i!SC!!V!" "!F!" && echo !S!>state\%%i.txt
    echo 192.168.1.%%i !S!
  )
)
