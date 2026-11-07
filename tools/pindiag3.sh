# 07.11.2026: PIN 18+ - gde tyuner MediaTek i gostinichnyy rezhim hranyat roditelskiy kontrol, mozhno li snyat udalenno
echo "kanalov=$(content query --uri content://android.media.tv/channel --projection _id 2>/dev/null | grep -c Row)"
echo "providers: $(dumpsys package providers 2>/dev/null | grep -o -E 'Authority: \"?[^ \"]*(mediatek|mtk|gdch|tvcenter|tvinput)[^ \"]*' | sort -u | tr '\n' ' ')"
echo "tvcenter-pin: $(dumpsys package com.mediatek.wwtv.tvcenter 2>/dev/null | grep -o -E '[A-Za-z0-9_.]*(Pin|PIN|Parental|parental|Rating|rating|Lock|Block)[A-Za-z0-9_.]*' | sort -u | head -25 | tr '\n' ' ')"
echo "gdch: $(pm list packages 2>/dev/null | grep -i -e gdch -e hotel | tr '\n' ' ') | $(dumpsys package com.gdch.hotel 2>/dev/null | grep -o -E 'com\.gdch\.hotel[A-Za-z0-9_.]*(Activity|Provider|Receiver|Service)' | sort -u | head -20 | tr '\n' ' ')"
for u in content://com.mediatek.tv.internal.data/global_value content://com.mediatek.wwtv.tvcenter.provider content://com.gdch.hotel.provider; do
  echo "q $u: $(content query --uri $u 2>&1 | grep -i -E 'rating|parent|pin|lock|block|age|Error|Exception|denied' | head -8 | cut -c1-160 | tr '\n' ' ')"
done
