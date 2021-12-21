#!/bin/sh

v4l2-ctl -v pixelformat=RGBP,height=2160,width=3264
fswebcam -p RGB565 -r 3264x2160 -S 20 bigRGB565.png

v4l2-ctl -v pixelformat=YUYV,height=2160,width=3264
fswebcam -p YUYV -r 3264x2160 -S 20 bigYUYV.png

v4l2-ctl -v pixelformat=UYVY,height=2160,width=3264
fswebcam -p UYVY -r 3264x2160 -S 20 bigUYVY.png

v4l2-ctl -v pixelformat=VYUY,height=2160,width=3264
fswebcam -p VYUY -r 3264x2160 -S 20 bigVYUY.png

v4l2-ctl -v pixelformat=AR24,height=2160,width=3264
fswebcam -p ABGR32 -r 3264x2160 -S 20 bigABGR32.png

v4l2-ctl -v pixelformat="Y16 ",height=2160,width=3264
fswebcam -p Y16 -r 3264x2160 -S 20 bigY16.png

v4l2-ctl -v pixelformat=GREY,height=2160,width=3264
fswebcam -p GREY -r 3264x2160 -S 20 bigGREY.png

v4l2-ctl -v pixelformat=YU12,height=2160,width=3264
fswebcam -p YUV420P -r 3264x2160 -S 20 bigYUV420P.png
