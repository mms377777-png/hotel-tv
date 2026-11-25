@echo off
rem Komanda dlya TV Pushkina. Menyaetsya - vypolnyaetsya odin raz. Versiya: 37
rem v37 (25.11.2026): opyty so stoykoy otmeneny (pravilo Mikhaila) - snimaem flagi opyta
cd /d C:\hoteltv
del opyt.go >nul 2>&1
del opyt.skipped >nul 2>&1
goto :eof
