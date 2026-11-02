# Na TV: spisok uchetok i teksty ekrana nastroek akkauntov (dlya udaleniya uchetok prezhnih gostey)
dumpsys account | grep 'Account {' | tr -d '\r\n'
echo ' || '
am start -a android.settings.SYNC_SETTINGS >/dev/null 2>&1
sleep 4
uiautomator dump /sdcard/ui.xml >/dev/null 2>&1
grep -o 'text="[^"]*"' /sdcard/ui.xml | tr '\n' ' '
echo ' || '
dumpsys window | grep -m1 mCurrentFocus
input keyevent KEYCODE_HOME
