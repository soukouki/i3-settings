
source ~/.config/i3/scr-misskey/config.sh

wezterm imgcat ~/tmp/scr-misskey.jpg

echo ""
echo "Enter message (If you don't post, press enter)"
read message

if [ -z "${message}" ]; then
  exit
fi

# upload to misskey

folder_id=$(curl "${misskey_root}/drive/folders" \
  -H 'content-type: application/json' \
  --data-raw "{\"name\":\"${folder_name}\", \"i\":\"${misskey_token}\"}" \
  --compressed | jq -r ".[] | select(.name == \"${folder_name}\") | .id")

if [ -z "${folder_id}" ]; then
  folder_id=$(curl "${misskey_root}/drive/folders/create" \
    -H 'content-type: application/json' \
    --data-raw "{\"name\":\"${folder_name}\", \"i\":\"${misskey_token}\"}" \
    --compressed | jq -r ".id")
fi

echo "folder_id: ${folder_id}"

# rewrite above

file_id=$(curl "${misskey_root}/drive/files/create" \
  -H 'content-type: multipart/form-data' \
  -F i="${misskey_token}" \
  -F folderId="${folder_id}" \
  -F file=@${HOME}/tmp/scr-misskey.jpg \
  -F name=$(date --iso-8601=seconds) | jq -r ".id")

echo "file_id: ${file_id}"

# if file_id is "null", print error and exit
if [ "${file_id}" = "null" ]; then
  echo "Error: file_id is null"
  exit
fi

curl "${misskey_root}/notes/create" \
 -H 'content-type: application/json' \
 --data-raw "{\"text\":\"${message}\", \"i\":\"${misskey_token}\", \"fileIds\":[\"${file_id}\"]}" \
 --compressed

sleep 20