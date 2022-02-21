#!/bin/sh

v4l2-ctl -v pixelformat=RGBP,height=720,width=1280
fswebcam -p RGB565 -r 1280x720 -S 20 tinyRGB565.png

v4l2-ctl -v pixelformat=AR24,height=720,width=1280
fswebcam -p ABGR32 -r 1280x720 -S 20 tinyABGR32.png

v4l2-ctl -v pixelformat=GREY,height=720,width=1280
fswebcam -p GREY -r 1280x720 -S 20 tinyGREY.png

v4l2-ctl -v pixelformat=YU12,height=720,width=1280
fswebcam -p YUV420P -r 1280x720 -S 20 tinyYUV420P.png
