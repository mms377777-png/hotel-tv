# Na TV: postavit prilozhenie iz RuStore. sh rustore.sh <paket>
P=$1
tap() {
  uiautomator dump /sdcard/ui.xml >/dev/null 2>&1
  b=$(grep -o "text=\"$1\"[^>]*bounds=\"[^\"]*\"" /sdcard/ui.xml | head -1 | sed 's/.*bounds="\[\([0-9]*\),\([0-9]*\)\]\[\([0-9]*\),\([0-9]*\)\]"/\1 \2 \3 \4/')
  [ -z "$b" ] && return 1
  set -- $b
  input tap $(( ($1+$3)/2 )) $(( ($2+$4)/2 ))
  return 0
}
if pm path $P >/dev/null 2>&1; then echo "$P uzhe est"; exit 0; fi
am start -a android.intent.action.VIEW -d "rustore://apps.rustore.ru/app/$P" >/dev/null 2>&1
sleep 10
i=0
while [ $i -lt 36 ]; do
  pm path $P >/dev/null 2>&1 && { echo "$P OK"; input keyevent KEYCODE_HOME; exit 0; }
  tap "Скачать" || tap "Установить" || tap "Продолжить" || tap "Разрешить" || tap "ОК" || tap "Принять" || tap "Пропустить" || tap "Не сейчас"
  sleep 5
  i=$((i+1))
done
echo "$P NE USTANOVLEN; ekran:"
uiautomator dump /sdcard/ui.xml >/dev/null 2>&1
grep -o 'text="[^"]*"' /sdcard/ui.xml | grep -v 'text=""' | tr '\n' ' ' | head -c 600
input keyevent KEYCODE_HOME
