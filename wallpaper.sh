#!/bin/bash

# 夏至の日出・日没時刻
summer_solstice_sunrise="4:20"
summer_solstice_sunset="19:05"

# 冬至の日出・日没時刻
winter_solstice_sunrise="6:56"
winter_solstice_sunset="16:26"

# よしなに変える
export DISPLAY=:0

function coefficient() {
    current_date=$(date +"%j")
    # 夏至(1.0)、冬至(0.0)として、どちらに近いのか係数を計算
    if [ $current_date -lt 172 ]; then
        # 夏至より前
        coefficient=$(echo "scale=2; ($current_date + 10) / 182" | bc)
    else if [ $current_date -gt 355 ]; then
        # 冬至より後
        coefficient=$(echo "scale=2; ($current_date - 355) / 182" | bc)
    else
        # 夏至と冬至の間
        coefficient=$(echo "scale=2; 1 - ($current_date - 172) / 183" | bc)
    fi
    fi
    echo $coefficient
}

function sunrise() {
    current_date=$(date +"%j")
    sunrise_difference=$((($(date -d "$summer_solstice_sunrise" +"%s") - $(date -d "$winter_solstice_sunrise" +"%s")) / 182))
    coefficient=$(coefficient)
    sunrise_interpolation=$(echo "scale=0; $coefficient * 182 * $sunrise_difference" | bc)
    current_sunrise=$(date -d "$winter_solstice_sunrise+0900 + $sunrise_interpolation seconds" +"%H:%M")
    echo $current_sunrise
}

function sunset() {
    current_date=$(date +"%j")
    sunset_difference=$((($(date -d "$summer_solstice_sunset" +"%s") - $(date -d "$winter_solstice_sunset" +"%s")) / 182))
    coefficient=$(coefficient)
    sunset_interpolation=$(echo "scale=0; $coefficient * 182.0 * $sunset_difference" | bc)
    current_sunset=$(date -d "$winter_solstice_sunset+0900 + $sunset_interpolation seconds" +"%H:%M")
    echo $current_sunset
}

# 画像ディレクトリのパス
day_directory="/home/sou7/Pictures/day/"
sunset_directory="/home/sou7/Pictures/sunset/"
night_directory="/home/sou7/Pictures/night/"

# fehを使ってデスクトップの背景を設定する関数
set_wallpaper() {
    feh --bg-fill --randomize $1
}

# 現在の時刻が日出・日没の2時間以内、昼間、夜間の3つに場合分け
current_time=$(date +"%H:%M")
echo "current time: $current_time"
sunrise_time=$(sunrise)
echo "sunrise time: $sunrise_time"
sunset_time=$(sunset)
echo "sunset time: $sunset_time"

if [[ $current_time > $(date -d "$sunrise_time+0900 + 2 hours" +"%H:%M") && $current_time < $(date -d "$sunset_time+0900 - 2 hours" +"%H:%M") ]]; then
    # 昼間
    set_wallpaper "$day_directory"
elif [[ $current_time > $(date -d "$sunset_time+0900 + 2 hours" +"%H:%M") || $current_time < $(date -d "$sunrize_time+0900 - 2 hours" +"%H:%M") ]]; then
    # 夜間
    set_wallpaper "$night_directory"
else
    # 日出時刻から日没時刻の2時間以内
    set_wallpaper "$sunset_directory"
fi
