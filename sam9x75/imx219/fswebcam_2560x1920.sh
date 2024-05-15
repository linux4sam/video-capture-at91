#!/bin/sh

v4l2-ctl -v pixelformat=RGBP,height=1920,width=2560
fswebcam -p RGB565 -r 2560x1920 -S 20 bigRGB565.jpeg

v4l2-ctl -v pixelformat=YUYV,height=1920,width=2560
fswebcam -p YUYV -r 2560x1920 -S 20 bigYUYV.jpeg

v4l2-ctl -v pixelformat=UYVY,height=1920,width=2560
fswebcam -p UYVY -r 2560x1920 -S 20 bigUYVY.jpeg

v4l2-ctl -v pixelformat=VYUY,height=1920,width=2560
fswebcam -p VYUY -r 2560x1920 -S 20 bigVYUY.jpeg

v4l2-ctl -v pixelformat=AR24,height=1920,width=2560
fswebcam -p ABGR32 -r 2560x1920 -S 20 bigABGR32.jpeg

v4l2-ctl -v pixelformat="Y16 ",height=1920,width=2560
fswebcam -p Y16 -r 2560x1920 -S 20 bigY16.jpeg

v4l2-ctl -v pixelformat=GREY,height=1920,width=2560
fswebcam -p GREY -r 2560x1920 -S 20 bigGREY.jpeg

v4l2-ctl -v pixelformat=YU12,height=1920,width=2560
fswebcam -p YUV420P -r 2560x1920 -S 20 bigYUV420P.jpeg
