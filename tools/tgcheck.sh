# 07.11.2026: proverka storozha tyunera (v108): zapushcheno li prilozhenie, razresheniya, chto pishet
echo "v=$(dumpsys package ru.hotelkms.tv | grep -m1 versionCode | tr -s ' ') pid=$(pidof ru.hotelkms.tv)"
echo "usage=$(appops get ru.hotelkms.tv GET_USAGE_STATS) saw=$(appops get ru.hotelkms.tv SYSTEM_ALERT_WINDOW) epg=$(dumpsys package ru.hotelkms.tv | grep -m1 READ_EPG_DATA | tr -s ' ')"
echo "log: $(logcat -d 2>/dev/null | grep -E 'TunerGuard|HotelTV.*(FATAL|Exception)|AndroidRuntime.*hotelkms' | tail -8 | cut -c1-200 | tr '\n' ';')"
