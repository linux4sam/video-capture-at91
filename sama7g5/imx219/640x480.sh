#!/bin/sh

. $(dirname "$0")/../../utils.sh

media-ctl -d /dev/media0 --set-v4l2 '"imx219 1-0010":0[fmt:SRGGB10_1X10/640x480]'
media-ctl -d /dev/media0 --set-v4l2 '"dw-csi.0":0[fmt:SRGGB10_1X10/640x480]'
media-ctl -d /dev/media0 --set-v4l2 '"csi2dc":0[fmt:SRGGB10_1X10/640x480]'
media-ctl -d /dev/media0 --set-v4l2 "\"$(get_scaler_name)\":0[fmt:SRGGB10_1X10/640x480]"
echo "Ready to capture at 640x480"
