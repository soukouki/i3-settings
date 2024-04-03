#!/bin/bash

# 第一引数にupdateを指定すると画像を入れ替えます

current_minute=$(date +'%M')
multiple_of_10=$((current_minute / 10 * 10))

tmpdir="/tmp/sou7-wallpaper"

function fetch_origin_file() {
  if [ ! -d "$tmpdir" ]; then
    mkdir "$tmpdir"
  fi
  cd "$(dirname "$(readlink -f "$0")")"
  cp "$(sou7-wallpaper/fetch-wallpaper.sh)" "$tmpdir/origin.jpg"
}

if [ "$1" = "update" ]; then
  fetch_origin_file
fi
if [ "$current_minute" -eq "$multiple_of_10" ]; then
  fetch_origin_file
fi

current_date=$(date "+%Y-%m-%d\n%H:%M")

convert "$tmpdir/origin.jpg" \
  -fill "#fff6" -pointsize 200 -gravity SouthWest -annotate +50+350 $(date "+%Y-%m-%d") \
  -fill "#fff6" -pointsize 300 -gravity SouthWest -annotate +50+50 $(date "+%H:%M") \
  "$tmpdir/wallpaper.jpg"


export DISPLAY=:0
feh --bg-fill --randomize "$tmpdir/wallpaper.jpg"
