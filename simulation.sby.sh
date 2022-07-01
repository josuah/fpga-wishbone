#!/bin/sh -eu
printf '%s\n' "" "[tasks]" "prove" "cover"
printf '%s\n' "" "[files]" "$@"
printf '%s\n' "" "[engines]" "smtbmc"
printf '%s\n' "" "[script]" "read -formal $*" "prep -top simulation"
printf '%s\n' "" "[options]" "prove: mode prove" "cover: mode cover" "depth 40"
