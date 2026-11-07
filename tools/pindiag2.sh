# 07.11.2026: kakoy ekran sprashival PIN 18+ - istoriya otkrytyh ekranov (usagestats) 16:30-17:59 i sledy v logcat
echo "tz=$(getprop persist.sys.timezone) now=$(date '+%H:%M')"
echo "ekrany: $(dumpsys usagestats 2>/dev/null | grep -E 'time="[0-9-]+ 1(6:[3-5]|7:[0-5])' | grep -E 'ACTIVITY_RESUMED' | sed -E 's/.*time="[0-9-]+ ([0-9:]+)".*class=([^ ]+).*/\1 \2/' | uniq | tail -40 | tr '\n' ';')"
echo "pin-ekrany (vse vremya): $(dumpsys usagestats 2>/dev/null | grep -E 'ACTIVITY_RESUMED' | grep -i -E 'pin|parent|rating|lock|age|adult|password|block' | sed -E 's/.*time="([^"]+)".*class=([^ ]+).*/\1 \2/' | sort -u | tail -15 | tr '\n' ';')"
echo "logcat: $(logcat -d 2>/dev/null | grep -i -E 'parental|rating|pincode|pin_code|PinDialog|blocked' | tail -15 | cut -c1-160 | tr '\n' ';')"
