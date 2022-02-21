#!/bin/sh

v4l2-ctl -v pixelformat=RGBP,height=480,width=640
fswebcam -p RGB565 -r 640x480 -S 20 RGB565_LE_640_480.png

v4l2-ctl -v pixelformat=YUYV,height=480,width=640
fswebcam -p YUYV -r 640x480 -S 20 YUYV_640_480.png

