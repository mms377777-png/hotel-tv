# 07.11.2026: proverka storozha tyunera (v109): versiya, process, sluzhba, razresheniya, chto pishet
echo "v=$(dumpsys package ru.hotelkms.tv | grep -m1 -o 'versionCode=[0-9]*') pid=$(pidof ru.hotelkms.tv) sluzhba=$(dumpsys activity services ru.hotelkms.tv | grep -c 'isForeground=true')"
echo "usage=$(appops get ru.hotelkms.tv GET_USAGE_STATS | cut -c1-60) saw=$(appops get ru.hotelkms.tv SYSTEM_ALERT_WINDOW | cut -c1-40)"
echo "log: $(logcat -d 2>/dev/null | grep -E 'TunerGuard|AndroidRuntime.*hotelkms|FATAL' | tail -6 | cut -c1-200 | tr '\n' ';')"
