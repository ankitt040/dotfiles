#!/bin/bash
CARD="${1:-0}"
MIXER="${2:-default}" # use pulse for pulseaudio, default is alsa
SCONTROL="${3:-Master}"

# case $BLOCK_BUTTON in
#   3) amixer -q sset $SCONTROL toggle ;; # right click, mute/unmute
#   4) amixer -q sset $SCONTROL 1%+ ;;    # scroll up, increase
#   5) amixer -q sset $SCONTROL 1%- ;;    # scroll down, decrease
# esac
case $BLOCK_BUTTON in
  3) pamixer --toggle-mute ;; # right click, mute/unmute
  4) pamixer --increase 5 ;;    # scroll up, increase
  5) pamixer --decrease 5 ;;    # scroll down, decrease
esac

volume () {
    pamixer --get-volume
  # amixer -c $CARD -M -D $MIXER get $SCONTROL
}

format () {
  perl -ne 'if (/\[(\d+%)\].*\[(on|off)\]/) {CORE::say $2 eq "off" ? "   " : "$1"; exit}'
}

volume
# volume | format
