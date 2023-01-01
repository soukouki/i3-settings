#!/usr/bin/env bash
# https://qiita.com/atsuya0/items/f4f2e34560afd22e48a3 を元に改造

set -euCo pipefail

function get_volume() {
  pactl list sinks | grep 'Volume' | grep -o '[0-9]*%' | tail -2 | tr -d '%'
}

function get_muted() {
  pactl list sinks | grep 'Mute' | sed 's/[[:space:]]//g' | cut -d: -f2 | tail -1
}

function to_line() {
  seq -s '-' $1 3 100 | tr -d '[:digit:]'
}

function to_meters() {
  echo "[$(to_line $(expr 100 - $1))|$(to_line $1)]"
}

function print_volume() {
  local -r volume=$(get_volume)
  [[ ${volume} -gt 100 ]] \
    && echo -e "${volume}\n" \
    || echo -e "$(to_meters ${volume})\n"
}

function main() {
  which pactl &> /dev/null || return 1
  LANG=C

  print_volume

  declare -Ar colors=( ['yes']='#434447' ['no']='#8fa1b3' )
  echo "${colors[$(get_muted)]}"
}

main