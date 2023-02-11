
# screenshot and upload to misskey
# Dependencies: scrot, curl, jq, wezterm

# config.sh should contain:
#   misskey_token
#   misskey_root(eg. https://misskey.io/api)
#   folder_name(eg. screenshot)

rm ~/tmp/scr-misskey.png
# take screenshot

scrot ~/tmp/scr-misskey.png

wezterm start --always-new-process ~/.config/i3/scr-misskey/console.sh
