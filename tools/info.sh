# Na TV: kratkaya informatsiya dlya tablitsy
ip=$(ip -4 -o addr show wlan0 2>/dev/null | awk '{print $4}' | cut -d/ -f1)
m=$(cat /sys/class/net/wlan0/address 2>/dev/null)
v=$(dumpsys package ru.hotelkms.tv | grep -m1 versionName | cut -d= -f2)
rt=$(pm path ru.rutube.app >/dev/null 2>&1 && echo da || echo net)
kp=$(pm path ru.kinopoisk.tv >/dev/null 2>&1 && echo da || echo net)
acc=$(dumpsys account | grep -c 'Account {')
echo "$ip;$(getprop ro.product.brand) $(getprop ro.product.model);$(getprop ro.serialno);$m;Android $(getprop ro.build.version.release);hotel-tv $v;rutube $rt;kinopoisk $kp;uchetok $acc"
