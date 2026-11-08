# 08.11.2026: chasy TV (Siti 12 pokazyval 29 oktyabrya): vremya TV, avtovremya, popytka sinhronizacii po NTP
e1=$(date +%s)
at=$(settings get global auto_time)
echo "epoch=$e1 tv=$(date '+%d.%m.%Y %H:%M:%S') tz=$(getprop persist.sys.timezone) auto_time=$at ntp=$(settings get global ntp_server)"
[ "$at" = "1" ] || settings put global auto_time 1
r=$(cmd network_time_update_service force_refresh 2>&1 | head -c 100)
sleep 3
e2=$(date +%s)
echo "refresh=$r posle=$(date '+%d.%m.%Y %H:%M:%S') sdvig=$((e2-e1-3))"
