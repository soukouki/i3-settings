#!/usr/bin/env zsh

#args
process_search_term=$1
exec_command=$2
workspace=$3

i3-msg workspace number $3

if ! pgrep -x $1; then
    i3-msg mode "check for starting $2 [retype: exec $2]"
    sleep 0.5
    i3-msg mode default
fi
