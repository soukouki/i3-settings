
# screenshot and upload to misskey
# Dependencies: scrot, curl, jq, wezterm, convert

# config.sh should contain:
#   misskey_token
#   misskey_root(eg. https://misskey.io/api)
#   folder_name(eg. screenshot)

rm ~/tmp/scr-misskey.png ~/tmp/scr-misskey.jpg
# take screenshot

scrot -u ~/tmp/scr-misskey.png
convert ~/tmp/scr-misskey.png -quality 80 ~/tmp/scr-misskey.jpg

wezterm start --always-new-process ~/.config/i3/scr-misskey/console.sh
