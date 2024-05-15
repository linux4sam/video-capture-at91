#!/bin/sh

v4l2-ctl -v pixelformat=RGBP,height=1080,width=1920
fswebcam -p RGB565 -r 1920x1080 -S 20 fullRGB565.jpeg

v4l2-ctl -v pixelformat=YUYV,height=1080,width=1920
fswebcam -p YUYV -r 1920x1080 -S 20 fullYUYV.jpeg

v4l2-ctl -v pixelformat=UYVY,height=1080,width=1920
fswebcam -p UYVY -r 1920x1080 -S 20 fullUYVY.jpeg

v4l2-ctl -v pixelformat=VYUY,height=1080,width=1920
fswebcam -p VYUY -r 1920x1080 -S 20 fullVYUY.jpeg

v4l2-ctl -v pixelformat=AR24,height=1080,width=1920
fswebcam -p ABGR32 -r 1920x1080 -S 20 fullABGR32.jpeg

v4l2-ctl -v pixelformat="Y16 ",height=1080,width=1920
fswebcam -p Y16 -r 1920x1080 -S 20 fullY16.jpeg

v4l2-ctl -v pixelformat=GREY,height=1080,width=1920
fswebcam -p GREY -r 1920x1080 -S 20 fullGREY.jpeg

v4l2-ctl -v pixelformat=YU12,height=1080,width=1920
fswebcam -p YUV420P -r 1920x1080 -S 20 fullYUV420P.jpeg
