#!/usr/bin/env bash

sleep 1 && killall trayer
trayer --edge top\
       --align right\
       --SetDockType true\
       --SetPartialStrut true\
       --expand true\
       --height 22\
       --distance 0\
       --distancefrom right\
       --transparent true\
       --alpha 0\
       --tint 0x161616\
       --widthtype request\
       --monitor 0\
       --margin 0\
