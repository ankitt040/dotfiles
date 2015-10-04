#!/bin/bash
if [ $1 == 'i' ]; then
    pamixer -i 5
elif [ $1 == 'd' ];then
    pamixer -d 5
elif [ $1 == 'm' ];then
    pamixer -t
fi


VOLUME=$(pamixer --get-volume)
MUTE=$(pamixer --get-mute)

if [ "$MUTE" == "false" ]; then
  volnoti-show $VOLUME
else
  volnoti-show -m $VOLUME
fi

# id=`cat /home/arindam/.i3/volumeid`
# notify-send "Volume" -i  ~/.icons/elementray-add-ubuntu/status/symbolic/audio-volume-high-symbolic.svg -h int:value:$volume -p -r $id > ~/.i3/volumeid
