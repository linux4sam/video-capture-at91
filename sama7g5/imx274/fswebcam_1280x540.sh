#!/bin/sh

v4l2-ctl -v pixelformat=RGBP,height=540,width=1280
fswebcam -p RGB565 -r 1280x540 -S 20 tinyRGB565.png

v4l2-ctl -v pixelformat=YUYV,height=540,width=1280
fswebcam -p YUYV -r 1280x540 -S 20 tinyYUYV.png

v4l2-ctl -v pixelformat=UYVY,height=540,width=1280
fswebcam -p UYVY -r 1280x540 -S 20 tinyUYVY.png

v4l2-ctl -v pixelformat=VYUY,height=540,width=1280
fswebcam -p VYUY -r 1280x540 -S 20 tinyVYUY.png

v4l2-ctl -v pixelformat=AR24,height=540,width=1280
fswebcam -p ABGR32 -r 1280x540 -S 20 tinyABGR32.png

v4l2-ctl -v pixelformat="Y16 ",height=540,width=1280
fswebcam -p Y16 -r 1280x540 -S 20 tinyY16.png

v4l2-ctl -v pixelformat=GREY,height=540,width=1280
fswebcam -p GREY -r 1280x540 -S 20 tinyGREY.png

v4l2-ctl -v pixelformat=YU12,height=540,width=1280
fswebcam -p YUV420P -r 1280x540 -S 20 tinyYUV420P.png
