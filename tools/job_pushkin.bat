@echo off
rem Komanda dlya TV Pushkina. Menyaetsya - vypolnyaetsya odin raz. Versiya: 32
rem v32 (23.11.2026): TOLKO CHTENIE - pochemu ne prishel rezultat opyta v31: hvost job_log, fayly opyt31/focus31, protsessy adb/powershell/curl.
cd /d C:\hoteltv
set "F=https://docs.google.com/forms/d/e/1FAIpQLSfXzkDXmGLQtI09w-_gq9A0RSOpuXFn2ERCkWprVoqvEYPPQw/formResponse"
(
echo Pushkin;diag v32 %date% %time%
echo --- job_log hvost:
if exist job_log.txt powershell -NoProfile -Command "Get-Content job_log.txt -Tail 25"
if exist job_log2.txt powershell -NoProfile -Command "Get-Content job_log2.txt -Tail 15"
echo --- opyt31.txt:
if exist opyt31.txt type opyt31.txt
echo --- focus31.txt:
if exist focus31.txt type focus31.txt
echo --- protsessy:
tasklist /fi "imagename eq adb.exe" /nh
tasklist /fi "imagename eq powershell.exe" /nh
tasklist /fi "imagename eq curl.exe" /nh
tasklist /fi "imagename eq cmd.exe" /nh
echo --- fayly:
dir /o-d job_last.bat opyt31.txt probe29.txt every.lock every.wait 2>nul
) > diag32.txt 2>&1
curl -s -o nul --data-urlencode "entry.1026545154@diag32.txt" "%F%"
goto :eof
