
# screenshot and upload to misskey
# Dependencies: scrot, curl, jq, vscode, convert(ImageMagick)

# config.sh should contain:
#   misskey_token
#   misskey_root(e.g. https://misskey.io/api)
#   folder_name(e.g. screenshot)

echo "Debug: [$(date --rfc-3339=seconds)] start" >> ~/tmp/scr-misskey.log
source ~/.config/i3/scr-misskey/config.sh

rm ~/tmp/scr-misskey.png ~/tmp/scr-misskey.jpg

echo "Debug: [$(date --rfc-3339=seconds)] screenshot" >> ~/tmp/scr-misskey.log
scrot -u ~/tmp/scr-misskey.png

echo "Debug: [$(date --rfc-3339=seconds)] convert" >> ~/tmp/scr-misskey.log
convert ~/tmp/scr-misskey.png -quality 80 ~/tmp/scr-misskey.jpg

# display image by vscode

echo "Debug: [$(date --rfc-3339=seconds)] open vscode to display image" >> ~/tmp/scr-misskey.log
code ~/tmp/scr-misskey.jpg

# prepare text file which user input message etc.

channels=$(curl "${misskey_root}/channels/followed" \
  -H 'content-type: application/json' \
  --data-raw "{\"i\":\"${misskey_token}\", \"limit\":100}" \
  --compressed | jq -r ".[].name" | sed -z 's/\n/, /g' | sed -z 's/, $//g')

# lines start with "#" are comments
# "---" is separator
exec 3>&1
cat << EOF > ~/tmp/scr-misskey.txt
# Feed message (If you don't post, don't input anything)



---
# Which channel do you want to post? (If you don't want, don't input anything)
# You are following these channels: ${channels}



---
EOF
exec 3>&-

# edit text file by vim

# open text file by vscode
echo "Debug: [$(date --rfc-3339=seconds)] open vscode to edit text" >> ~/tmp/scr-misskey.log
code --wait ~/tmp/scr-misskey.txt

# analyse text file

sed -i -e '/^#/d' ~/tmp/scr-misskey.txt
csplit -f ~/tmp/ -b scr-misskey-%01d.txt ~/tmp/scr-misskey.txt '/^---$/' '%^$%' '/^---$/'


# message is before separator
# and preserve newlines which between message
message=$(cat ~/tmp/scr-misskey-0.txt | sed -z 's/\n\n*/\n/g' | sed -z 's/\n$//g')
if [ -z "${message}" ]; then
  echo "Success: [$(date --rfc-3339=seconds)] no message" >> ~/tmp/scr-misskey.log
  exit
fi
echo "Debug: [$(date --rfc-3339=seconds)] message: ${message}" >> ~/tmp/scr-misskey.log

# channel is after separator
# and remove newlines
channel_name=$(cat ~/tmp/scr-misskey-1.txt | sed -z 's/\n//g')
if [ -z "${channel_name}" ]; then
  channel_name=""
  echo "Debug: [$(date --rfc-3339=seconds)] no channel" >> ~/tmp/scr-misskey.log
fi
echo "Debug: [$(date --rfc-3339=seconds)] channel_name: ${channel_name}" >> ~/tmp/scr-misskey.log

# fetch channel_id

if [ -z "${channel_name}" ]; then
  channel_id=""
  echo "Debug: [$(date --rfc-3339=seconds)] no channel" >> ~/tmp/scr-misskey.log
else
  channel_id=$(curl "${misskey_root}/channels/followed" \
    -H 'content-type: application/json' \
    --data-raw "{\"i\":\"${misskey_token}\", \"limit\":100}" \
    --compressed | jq -r ".[] | select(.name == \"${channel_name}\") | .id")
  
  # if channel_id is null, print error message and exit
  if [ -z "${channel_id}" ]; then
    echo "Error: [$(date --rfc-3339=seconds)] cannot get channel_id" >> ~/tmp/scr-misskey.log
    exit 1
  fi
fi
echo "Debug: [$(date --rfc-3339=seconds)] channel_id: ${channel_id}" >> ~/tmp/scr-misskey.log

# fetch folder_id

folder_id=$(curl "${misskey_root}/drive/folders" \
  -H 'content-type: application/json' \
  --data-raw "{\"name\":\"${folder_name}\", \"i\":\"${misskey_token}\"}" \
  --compressed | jq -r ".[] | select(.name == \"${folder_name}\") | .id")

if [ -z "${folder_id}" ]; then
  echo "Debug: [$(date --rfc-3339=seconds)] create folder because folder is not exists" >> ~/tmp/scr-misskey.log
  folder_id=$(curl "${misskey_root}/drive/folders/create" \
    -H 'content-type: application/json' \
    --data-raw "{\"name\":\"${folder_name}\", \"i\":\"${misskey_token}\"}" \
    --compressed | jq -r ".id")
fi
echo "Debug: [$(date --rfc-3339=seconds)] folder_id: ${folder_id}" >> ~/tmp/scr-misskey.log

# if folder_id is null, print error message and exit
if [ -z "${folder_id}" ]; then
  echo "Error: [$(date --rfc-3339=seconds)] cannot get folder_id" >> ~/tmp/scr-misskey.log
  exit 1
fi

# upload file

file_id=$(curl "${misskey_root}/drive/files/create" \
  -H 'content-type: multipart/form-data' \
  -F i="${misskey_token}" \
  -F folderId="${folder_id}" \
  -F name="$(date --rfc-3339=seconds).jpg" \
  -F file=@"${HOME}/tmp/scr-misskey.jpg" \
  --compressed | jq -r ".id")
echo "Debug: [$(date --rfc-3339=seconds)] file_id: ${file_id}" >> ~/tmp/scr-misskey.log

# if file_id is null, print error message and exit
if [ -z "${file_id}" ]; then
  echo "Error: [$(date --rfc-3339=seconds)] cannot upload file" >> ~/tmp/scr-misskey.log
  exit 1
fi

# post message

if [ -z "${channel_id}" ]; then
  output=$(curl "${misskey_root}/notes/create" \
    -H 'content-type: application/json' \
    --data-raw "{\"i\":\"${misskey_token}\", \"text\":\"${message}\", \"fileIds\":[\"${file_id}\"]}" \
    --compressed)
else
  output=$(curl "${misskey_root}/notes/create" \
    -H 'content-type: application/json' \
    --data-raw "{\"i\":\"${misskey_token}\", \"text\":\"${message}\", \"fileIds\":[\"${file_id}\"], \"channelId\":\"${channel_id}\"}" \
    --compressed)
fi

echo "Debug: [$(date --rfc-3339=seconds)] output: ${output}" >> ~/tmp/scr-misskey.log

# if fail, print error message, delete file uploaded and exit
if [ $(echo ${output} | grep -q "error") ]; then
  echo "Error: [$(date --rfc-3339=seconds)] cannot post message ${output}" >> ~/tmp/scr-misskey.log

  curl "${misskey_root}/drive/files/delete" \
    -H 'content-type: application/json' \
    --data-raw "{\"i\":\"${misskey_token}\", \"fileId\":\"${file_id}\"}" \
    --compressed

  exit 1
fi

# if success, print success message
echo "Success: [$(date --rfc-3339=seconds)] post message" >> ~/tmp/scr-misskey.log

