#!/usr/bin/env bash
set -e
PKG="org.akanework.gramophone"
mkdir -p shots

echo "=== wait boot ==="
adb wait-for-device
until [ "$(adb shell getprop sys.boot_completed | tr -d '\r')" = "1" ]; do sleep 2; done
sleep 6

echo "=== adb root ==="
adb root || true
sleep 3
adb wait-for-device
sleep 2

echo "=== reduce system load & hide ANR dialogs ==="
adb shell settings put global hide_error_dialogs 1 || true
adb shell settings put global window_animation_scale 0.0 || true
adb shell settings put global transition_animation_scale 0.0 || true
adb shell settings put global animator_duration_scale 0.0 || true
sleep 5

echo "=== install apk ==="
APK_FILE=$(ls *.apk | head -1)
echo "installing: $APK_FILE"
adb install -r -g "$APK_FILE"
# debug build has applicationIdSuffix ".debug" — detect real package name
PKG=$(adb shell pm list packages 2>/dev/null | grep -i gramophone | head -1 | sed 's/package://; s/\r//')
[ -z "$PKG" ] && PKG="org.akanework.gramophone"
echo "real package: $PKG"

echo "=== grant permissions ==="
adb shell pm grant $PKG android.permission.READ_MEDIA_AUDIO 2>/dev/null || true
adb shell pm grant $PKG android.permission.READ_EXTERNAL_STORAGE 2>/dev/null || true
adb shell pm grant $PKG android.permission.POST_NOTIFICATIONS 2>/dev/null || true

echo "=== generate audio (python wav) ==="
python3 << 'PYEOF'
import math, struct, wave
for i, freq in enumerate([440, 550, 660, 770], 1):
    w = wave.open(f'/tmp/t{i}.wav', 'w')
    w.setnchannels(1); w.setsampwidth(2); w.setframerate(44100)
    n = 44100 * 60
    frames = bytearray()
    for t in range(n):
        v = int(20000 * math.sin(2 * math.pi * freq * t / 44100))
        frames += struct.pack('<h', v)
    w.writeframes(bytes(frames)); w.close()
print("wavs ok")
PYEOF

echo "=== wait sdcard ready (FUSE reconnect after adb root) ==="
SDCARD_OK=0
for i in 1 2 3 4 5 6 7 8 9 10; do
  if adb shell "mkdir -p /sdcard/Music && touch /sdcard/Music/.probe && rm /sdcard/Music/.probe" 2>/dev/null; then
    SDCARD_OK=1
    echo "sdcard ready (try $i)"
    break
  fi
  echo "sdcard not ready (try $i)"; sleep 6
done
[ "$SDCARD_OK" = "1" ] || { echo "FATAL: sdcard never ready"; exit 1; }

adb push /tmp/t1.wav /sdcard/Music/LiquidDream01.wav
adb push /tmp/t2.wav /sdcard/Music/LiquidDream02.wav
adb push /tmp/t3.wav /sdcard/Music/LiquidDream03.wav
adb push /tmp/t4.wav /sdcard/Music/LiquidDream04.wav

echo "=== media scan ==="
for i in 1 2 3 4; do
  adb shell am broadcast -a android.intent.action.MEDIA_SCANNER_SCAN_FILE -d "file:///sdcard/Music/LiquidDream0$i.wav" || true
done
sleep 5

# dynamic screen size
SIZE=$(adb shell wm size | grep -o '[0-9]*x[0-9]*' | tail -1)
W=${SIZE%x*}
H=${SIZE#*x}
echo "screen: ${W}x${H}"
MID_X=$((W / 2))
SONG_Y=$((H * 32 / 100))
MINI_Y=$((H - 130))

echo "=== dark mode ==="
adb shell cmd uimode night yes
sleep 2

echo "=== keep screen awake & dismiss keyguard ==="
adb shell input keyevent KEYCODE_WAKEUP || true
adb shell svc power stayon true || true
adb shell wm dismiss-keyguard || true
sleep 2

echo "=== launch (explicit full component; .ui relative path breaks under debug suffix) ==="
# real package detected above (org.akanework.gramophone.debug), but activity class
# path stays org.akanework.gramophone.ui.MainActivity (manifest package unchanged)
adb shell am start -n "$PKG/org.akanework.gramophone.ui.MainActivity"
APP_UP=0
for i in $(seq 1 20); do
  FOCUS=$(adb shell dumpsys window | grep -i mCurrentFocus || true)
  echo "focus[$i]: $FOCUS"
  if echo "$FOCUS" | grep -qi "gramophone" && ! echo "$FOCUS" | grep -qi "leakcanary"; then
    APP_UP=1; echo "app foreground (try $i)"; break
  fi
  # if leakcanary hijacked the foreground, explicitly relaunch main activity
  if [ $((i % 4)) = "0" ]; then
    adb shell am start -n "$PKG/org.akanework.gramophone.ui.MainActivity" || true
  fi
  sleep 3
done
[ "$APP_UP" = "1" ] || { echo "WARN: app not foreground, continuing anyway"; }
adb shell wm dismiss-keyguard || true
sleep 6
# wake again right before first screencap to avoid black compositor frames
adb shell input keyevent KEYCODE_WAKEUP || true
sleep 1
adb exec-out screencap -p > shots/1_library_dark.png

echo "=== tap first song ==="
adb shell input tap $MID_X $SONG_Y
sleep 5
adb shell dumpsys window | grep -i mCurrentFocus || true
adb exec-out screencap -p > shots/2_minibar_dark.png

echo "=== expand full player ==="
adb shell input tap $MID_X $MINI_Y
sleep 5
adb shell dumpsys window | grep -i mCurrentFocus || true
adb exec-out screencap -p > shots/3_player_dark.png
adb shell input keyevent 4
sleep 2

echo "=== light mode ==="
adb shell cmd uimode night no
sleep 4
adb exec-out screencap -p > shots/4_library_light.png
adb shell input tap $MID_X $MINI_Y
sleep 4
adb exec-out screencap -p > shots/5_player_light.png

echo "=== done ==="
ls -la shots/
