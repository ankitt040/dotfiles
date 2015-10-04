#!/bin/bash

if [ $1 = 'i' ]; then
    xbacklight -inc 3
elif [ $1 = 'd' ]; then
    xbacklight -dec 3
fi

volume=`xbacklight -get| awk '{printf("%d\n",$1 + 0.5)}'`
# volume=$((volume*2))
id=`cat ~/.i3/volumeid`
# id=`cat ~/.i3/brightnessid`
# echo $id
notify-send "Volume" -i  ~/.icons/elementray-add-ubuntu/status/symbolic/brightness-display-symbolic.svg -h int:value:$volume -p -r $id > ~/.i3/volumeid
