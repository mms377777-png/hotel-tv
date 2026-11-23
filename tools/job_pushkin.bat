@echo off
rem Komanda dlya TV Pushkina. Menyaetsya - vypolnyaetsya odin raz. Versiya: 35
rem v35 (24.11.2026): tolko chtenie - rooms_sn.txt i devices v zhurnal (dlya opyta po nomeru komnaty)
cd /d C:\hoteltv
(echo pushkin rooms_sn:& type rooms_sn.txt & echo devices:& platform-tools\adb.exe devices) > rsn.txt 2>&1
curl -s -o nul --data-urlencode "entry.1026545154@rsn.txt" "https://docs.google.com/forms/d/e/1FAIpQLSfXzkDXmGLQtI09w-_gq9A0RSOpuXFn2ERCkWprVoqvEYPPQw/formResponse"
goto :eof
