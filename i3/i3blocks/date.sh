#!/bin/sh
#~/scripts/i3blocks/blocklets/date.sh

case $BLOCK_BUTTON in
#   3)date '+%a %b %d, %Y' ;;
#   1)gsimplecal ;;
  3)speedcrunch ;;

esac

date '+%I:%M:%S'
