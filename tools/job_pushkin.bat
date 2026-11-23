@echo off
rem Komanda dlya TV Pushkina. Menyaetsya - vypolnyaetsya odin raz. Versiya: 36
rem v36 (24.11.2026): opyt standby na TV komnaty 317 (svobodna po 1S) - flag opyt.go s nomerom; every_pushkin vyzovet standby_opyt.bat
cd /d C:\hoteltv
del opyt.skipped >nul 2>&1
echo 317> opyt.go
goto :eof
