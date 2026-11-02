# Na TV: udalit vse uchetki (Google, Yandeks) prezhnih gostey cherez Nastroyki -> Akkaunty
tap() {
  uiautomator dump /sdcard/ui.xml >/dev/null 2>&1
  b=$(grep -F -o "text=\"$1\"" -A0 /sdcard/ui.xml >/dev/null && sed 's/></>\n</g' /sdcard/ui.xml | grep -F "text=\"$1\"" | head -1 | grep -o 'bounds="[^"]*"' | sed 's/bounds="\[\([0-9]*\),\([0-9]*\)\]\[\([0-9]*\),\([0-9]*\)\]"/\1 \2 \3 \4/')
  [ -z "$b" ] && return 1
  set -- $b
  input tap $(( ($1+$3)/2 )) $(( ($2+$4)/2 ))
  return 0
}
n=0
while [ $n -lt 12 ]; do
  NAME=$(dumpsys account | grep -m1 'Account {' | sed 's/.*Account {name=\(.*\), type=.*/\1/')
  [ -z "$NAME" ] && { echo "uchetok net"; break; }
  am start -a android.settings.SYNC_SETTINGS >/dev/null 2>&1
  sleep 3
  if tap "$NAME"; then
    sleep 3
    tap "Удалить аккаунт" || tap "Удалить" || tap "Выйти"
    sleep 3
    tap "ОК" || tap "Удалить" || tap "Удалить аккаунт" || tap "Да" || tap "Выйти"
    sleep 4
    echo "udalyal: $NAME"
  else
    echo "ne nashel na ekrane: $NAME"; break
  fi
  n=$((n+1))
done
echo "ostalos:"; dumpsys account | grep 'Account {' | tr -d '\r\n'
uiautomator dump /sdcard/ui.xml >/dev/null 2>&1; grep -o 'text="[^"]*"' /sdcard/ui.xml | grep -v 'text=""' | tr '\n' ' ' | head -c 300
input keyevent KEYCODE_HOME
