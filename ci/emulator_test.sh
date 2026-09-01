#!/usr/bin/env bash
set -e
PKG="org.akanework.gramophone"
mkdir -p shots

echo "=== wait boot ==="
adb wait-for-device
until [ "$(adb shell getprop sys.boot_completed | tr -d '\r')" = "1" ]; do sleep 2; done
sleep 6

echo "=== adb root (protected broadcast needs root) ==="
adb root || true
sleep 3
adb wait-for-device
sleep 2

echo "=== grant permissions ==="
adb shell pm grant $PKG android.permission.READ_MEDIA_AUDIO 2>/dev/null || true
adb shell pm grant $PKG android.permission.READ_EXTERNAL_STORAGE 2>/dev/null || true
adb shell pm grant $PKG android.permission.POST_NOTIFICATIONS 2>/dev/null || true

echo "=== generate audio (python wav, no ffmpeg needed) ==="
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
adb shell mkdir -p /sdcard/Music
adb push /tmp/t1.wav /sdcard/Music/LiquidDream01.wav
adb push /tmp/t2.wav /sdcard/Music/LiquidDream02.wav
adb push /tmp/t3.wav /sdcard/Music/LiquidDream03.wav
adb push /tmp/t4.wav /sdcard/Music/LiquidDream04.wav

echo "=== media scan ==="
for i in 1 2 3 4; do
  adb shell am broadcast -a android.intent.action.MEDIA_SCANNER_SCAN_FILE -d "file:///sdcard/Music/LiquidDream0$i.wav" || true
done
sleep 4

# dynamic screen size
SIZE=$(adb shell wm size | grep -o '[0-9]*x[0-9]*' | tail -1)
W=${SIZE%x*}
H=${SIZE#*x}
echo "screen: ${W}x${H}"
MID_X=$((W / 2))
SONG_Y=$((H * 30 / 100))
MINI_Y=$((H - 170))

echo "=== dark mode ==="
adb shell cmd uimode night yes
sleep 2

echo "=== launch ==="
adb shell am start -n $PKG/.ui.MainActivity
sleep 10
adb exec-out screencap -p > shots/1_library_dark.png

echo "=== tap first song ==="
adb shell input tap $MID_X $SONG_Y
sleep 4
adb exec-out screencap -p > shots/2_minibar_dark.png

echo "=== expand full player ==="
adb shell input tap $MID_X $MINI_Y
sleep 4
adb exec-out screencap -p > shots/3_player_dark.png
adb shell input keyevent 4
sleep 2

echo "=== light mode ==="
adb shell cmd uimode night no
sleep 3
adb exec-out screencap -p > shots/4_library_light.png
adb shell input tap $MID_X $MINI_Y
sleep 3
adb exec-out screencap -p > shots/5_player_light.png

echo "=== done ==="
ls -la shots/
