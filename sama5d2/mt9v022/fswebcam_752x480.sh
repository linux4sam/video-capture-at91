#!/bin/sh

v4l2-ctl -v pixelformat=GREY,height=480,width=752
fswebcam -p GREY -r 752x480 -S 20 tinyGREY.png

