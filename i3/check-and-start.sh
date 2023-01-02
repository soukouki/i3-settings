#!/usr/bin/env zsh

#args
process_search_term=$1
exec_command=$2
workspace=$3

i3-msg workspace number $workspace

if ! pgrep -x $process_search_term; then
    i3-msg mode "check for starting $exec_command [retype: exec $exec_command]"
    sleep 0.5
    i3-msg mode default
fi
