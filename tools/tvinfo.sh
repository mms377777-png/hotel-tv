# Na TV: kratkaya svodka dlya stoyki: <nomer> <versionCode> <est_gost 0/1> <rutube> <kinopoisk> <okko> <ivi>
# 06.11.2026: otmetka "stoyka byla" - prilozhenie po ney reshaet, nuzhno li perezapustit otladku po Wi-Fi (AdbKeeper)
run-as ru.hotelkms.tv touch files/stand_seen 2>/dev/null
X=$(run-as ru.hotelkms.tv cat shared_prefs/hotel_tv.xml 2>/dev/null | tr '\n' ' ')
R=$(echo "$X" | sed -n 's/.*name="room">\([^<]*\)<.*/\1/p' | head -1 | tr -d ' ')
G=$(echo "$X" | grep -c 'name="guest_name">[^<]')
V=$(dumpsys package ru.hotelkms.tv 2>/dev/null | sed -n 's/.*versionCode=\([0-9]*\).*/\1/p' | head -1)
has() { pm path "$1" >/dev/null 2>&1 && echo 1 || echo 0; }
echo "${R:-none} ${V:-0} $G $(has ru.rutube.app) $(has ru.kinopoisk.tv) $(has tv.okko.androidtv) $(has ru.ivi.client)"
