#!/usr/bin/env bash
# https://qiita.com/atsuya0/items/f4f2e34560afd22e48a3 を元に改造

set -euCo pipefail

function online_icon() {
  [[ $# -eq 0 ]] && return 1
  local -ar icons=('' '' '' '' '')
  local index
  index=$(expr $1 % ${#icons[@]})
  echo ${icons[${index}]}
}

function echo_battery() {
  [[ $# -eq 1 ]] \
    && echo -e "\"full_text\": \"$1 \"" \
    || echo -e "\"full_text\": \"$1 \", \"color\": \"$2\""
}

function get_battery() {
  [[ -e '/sys/class/power_supply/BAT0/capacity' ]] \
    && cat '/sys/class/power_supply/BAT0/capacity' \
    || echo 0
}

function get_battery_actual() {
  local now=$(cat '/sys/class/power_supply/BAT0/charge_now')
  local full=$(cat '/sys/class/power_supply/BAT0/charge_full_design')

  echo "scale=1; ($now * 100) / $full" | bc
}

function online() {
  [[ $(cat /sys/class/power_supply/BAT0/status) = "Charging" ]] \
    && return 0
  return 1
}

function main() {
  local -Ar \
    high=( ['value']=79 ['icon']='' ['color']='#08d137') \
    middle=( ['icon']='' ['color']='#8fa1b3') \
    low=( ['value']=21 ['icon']='' ['color']='#f73525')

  local online_icon='' cnt=0
  while sleep 1; do
    cnt=$(expr ${cnt} + 1)

    if online; then
      #online_icon=$(online_icon ${cnt})
      online_icon='  \uf0e7 '
    else
      [[ -z ${online_icon} && $(expr ${cnt} % 60) -ne 1 ]] \
        && continue
      online_icon=''
    fi

    local battery
    battery=$(get_battery)
    local battery_actual
    battery_actual=$(get_battery_actual)

    if [[ ${battery} -eq 0 ]]; then
      echo_battery ${online_icon}
    elif [[ ${battery} -gt ${high['value']} ]];then
      echo_battery \
        "${online_icon:-${high['icon']}} ${battery_actual}%" ${high['color']}
    elif [[ ${battery} -lt ${low['value']} ]];then
      echo_battery \
        "${online_icon:-${low['icon']}} ${battery_actual}%" ${low['color']}
    else
      echo_battery \
        "${online_icon:-${middle['icon']}} ${battery_actual}%" ${middle['color']}
    fi
  done
}

main
