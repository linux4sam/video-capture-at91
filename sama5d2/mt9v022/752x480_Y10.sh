#!/bin/sh

. $(dirname "$0")/../../utils.sh

echo Preparing MT9V022 in Y10 10bits mode
media-ctl -d /dev/media0 --set-v4l2 '4:0[fmt:Y10_1X10/752x480 field:none colorspace:srgb]'
media-ctl -d /dev/media0 --set-v4l2 "\"$(get_scaler_name)\":0[fmt:Y10_1X10/752x480 field:none colorspace:srgb]"
echo Ready to capture at 752x480
