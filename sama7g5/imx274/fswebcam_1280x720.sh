#!/bin/sh

v4l2-ctl -v pixelformat=RGBP,height=720,width=1280
fswebcam -p RGB565 -r 1280x720 -S 20 smallRGB565.png

v4l2-ctl -v pixelformat=YUYV,height=720,width=1280
fswebcam -p YUYV -r 1280x720 -S 20 smallYUYV.png

v4l2-ctl -v pixelformat=UYVY,height=720,width=1280
fswebcam -p UYVY -r 1280x720 -S 20 smallUYVY.png

v4l2-ctl -v pixelformat=VYUY,height=720,width=1280
fswebcam -p VYUY -r 1280x720 -S 20 smallVYUY.png

v4l2-ctl -v pixelformat=AR24,height=720,width=1280
fswebcam -p ABGR32 -r 1280x720 -S 20 smallABGR32.png

v4l2-ctl -v pixelformat="Y16 ",height=720,width=1280
fswebcam -p Y16 -r 1280x720 -S 20 smallY16.png

v4l2-ctl -v pixelformat=GREY,height=720,width=1280
fswebcam -p GREY -r 1280x720 -S 20 smallGREY.png

v4l2-ctl -v pixelformat=YU12,height=720,width=1280
fswebcam -p YUV420P -r 1280x720 -S 20 smallYUV420P.png
