@echo off
setlocal enabledelayedexpansion
rem Komanda dlya TV Pushkina. Menyaetsya - vypolnyaetsya odin raz. Versiya: 29
rem v29 (23.11.2026): TOLKO CHTENIE - razvedka rezhima ozhidaniya (standby) na odnom vklyuchennom TV: kakie nastroyki Wi-Fi/pitaniya est. Zhdet do 3 min poyavleniya TV, dalee odin TV.
cd /d C:\hoteltv
set "A=platform-tools\adb.exe"
set "F=https://docs.google.com/forms/d/e/1FAIpQLSfXzkDXmGLQtI09w-_gq9A0RSOpuXFn2ERCkWprVoqvEYPPQw/formResponse"
set "SN="
for /l %%i in (1,1,12) do if not defined SN (
  for /f "skip=1 tokens=1,2" %%a in ('%A% devices') do if "%%b"=="device" if not defined SN set "SN=%%a"
  if not defined SN ping -n 16 127.0.0.1 >nul
)
(
echo Pushkin;standby probe v29 %date% %time% TV=!SN!
if defined SN (
  %A% -s !SN! shell "echo ---model; getprop ro.product.model; getprop ro.product.board; getprop ro.hardware; getprop ro.build.version.release; getprop ro.build.fingerprint; echo ---settings; settings get global wifi_sleep_policy; settings get global stay_on_while_plugged_in; settings get global adb_wifi_enabled; settings get global adb_enabled; settings get global wifi_on; echo ---global grep; settings list global | grep -i -E 'wifi|wake|standby|sleep|power|doze' | head -40; echo ---system grep; settings list system | grep -i -E 'wake|standby|sleep|power|cec' | head -30; echo ---secure grep; settings list secure | grep -i -E 'wake|standby|sleep|power|cec|screensaver' | head -30"
  %A% -s !SN! shell "echo ---props; getprop | grep -i -E 'standby|wowlan|wake|suspend|deepsleep|quick|fastboot|cec|network.*stand|persist.sys.power|wifi.*sleep' | head -50; echo ---power; dumpsys power | grep -i -E 'mWakefulness|Display Power|SuspendBlockers|mWakeLock|mHoldingWakeLock' | head -15; echo ---wifi; dumpsys wifi | grep -i -E 'wowlan|suspend|power ?save|low latency|scan always|wifi is|Wi-Fi is' | head -20; echo ---cmdwifi; cmd wifi status 2>&1 | head -20; echo ---hdmi; dumpsys hdmi_control 2>&1 | head -12; echo ---deviceidle; dumpsys deviceidle 2>&1 | head -8; echo ---net; ls /sys/class/net; ip -o addr show | head -6"
)
) > probe29.txt 2>&1
curl -s -o nul --data-urlencode "entry.1026545154@probe29.txt" "%F%"
endlocal
goto :eof
