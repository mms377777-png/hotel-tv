# 07.11.2026: otkuda zapros PIN 18+ (Pushkin 305) - razovaya diagnostika: tyuner, roditelskiy kontrol, reytingi
echo "model=$(getprop ro.product.model) a=$(getprop ro.build.version.release) up=$(cut -d. -f1 /proc/uptime)"
echo "focus: $(dumpsys window | grep mCurrentFocus | head -1)"
echo "pkgs: $(pm list packages | cut -d: -f2 | grep -i -e tvcenter -e mediatek -e mtk -e realtek -e tuner -e livetv -e 'android.tv$' -e tv.settings -e parental -e dtv -e atv -e inputs -e tvinput | tr '\n' ' ')"
echo "secure: $(settings list secure | grep -i -e parent -e rating -e block -e pin -e lock -e age -e child | tr '\n' ' ')"
echo "global: $(settings list global | grep -i -e parent -e rating -e block -e pin -e lock -e age -e child -e tv_ | tr '\n' ' ')"
echo "system: $(settings list system | grep -i -e parent -e rating -e block -e pin -e lock -e age -e child | tr '\n' ' ')"
echo "tvinput: $(dumpsys tv_input 2>/dev/null | grep -i -e parental -e rating -e block -e 'inputId' | head -30 | tr -s ' ' | tr '\n' ' ')"
echo "props: $(getprop | grep -i -e parent -e rating -e pin -e lock -e 'vendor.mtk.tv' | head -20 | tr -d '\n')"
