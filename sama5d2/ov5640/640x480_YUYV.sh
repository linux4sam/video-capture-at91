#!/bin/sh

. $(dirname "$0")/../../utils.sh

echo Preparing OV5640 in YUYV 8bits mode
media-ctl -d /dev/media0 --set-v4l2 '4:0[fmt:YUYV8_2X8/640x480@1/24 field:none colorspace:srgb]'
media-ctl -d /dev/media0 --set-v4l2 "\"$(get_scaler_name)\":0[fmt:YUYV8_2X8/640x480 field:none colorspace:srgb]"
echo Ready to capture at 640x480
