#!/bin/sh

v4l2-ctl -v pixelformat=RGBP,height=480,width=640
fswebcam -p RGB565 -r 640x480 -S 20 tinyRGB565.jpeg

v4l2-ctl -v pixelformat=YUYV,height=480,width=640
fswebcam -p YUYV -r 640x480 -S 20 tinyYUYV.jpeg

v4l2-ctl -v pixelformat=UYVY,height=480,width=640
fswebcam -p UYVY -r 640x480 -S 20 tinyUYVY.jpeg

v4l2-ctl -v pixelformat=VYUY,height=480,width=640
fswebcam -p VYUY -r 640x480 -S 20 tinyVYUY.jpeg

v4l2-ctl -v pixelformat=AR24,height=480,width=640
fswebcam -p ABGR32 -r 640x480 -S 20 tinyABGR32.jpeg

v4l2-ctl -v pixelformat="Y16 ",height=480,width=640
fswebcam -p Y16 -r 640x480 -S 20 tinyY16.jpeg

v4l2-ctl -v pixelformat=GREY,height=480,width=640
fswebcam -p GREY -r 640x480 -S 20 tinyGREY.jpeg

v4l2-ctl -v pixelformat=YU12,height=480,width=640
fswebcam -p YUV420P -r 640x480 -S 20 tinyYUV420P.jpeg
