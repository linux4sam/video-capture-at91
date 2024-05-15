#!/bin/sh

v4l2-ctl -v pixelformat=RGBP,height=1232,width=1640
fswebcam -p RGB565 -r 1640x1232 -S 20 panoRGB565.jpeg

v4l2-ctl -v pixelformat=YUYV,height=1232,width=1640
fswebcam -p YUYV -r 1640x1232 -S 20 panoYUYV.jpeg

v4l2-ctl -v pixelformat=UYVY,height=1232,width=1640
fswebcam -p UYVY -r 1640x1232 -S 20 panoUYVY.jpeg

v4l2-ctl -v pixelformat=VYUY,height=1232,width=1640
fswebcam -p VYUY -r 1640x1232 -S 20 panoVYUY.jpeg

v4l2-ctl -v pixelformat=AR24,height=1232,width=1640
fswebcam -p ABGR32 -r 1640x1232 -S 20 panoABGR32.jpeg

v4l2-ctl -v pixelformat="Y16 ",height=1232,width=1640
fswebcam -p Y16 -r 1640x1232 -S 20 panoY16.jpeg

v4l2-ctl -v pixelformat=GREY,height=1232,width=1640
fswebcam -p GREY -r 1640x1232 -S 20 panoGREY.jpeg

v4l2-ctl -v pixelformat=YU12,height=1232,width=1640
fswebcam -p YUV420P -r 1640x1232 -S 20 panoYUV420P.jpeg
