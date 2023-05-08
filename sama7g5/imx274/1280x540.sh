#!/bin/sh

. $(dirname "$0")/../../utils.sh

media-ctl -d /dev/media0 --set-v4l2 '"IMX274 1-001a":0[fmt:SRGGB10_1X10/1280x540@1/30]'
media-ctl -d /dev/media0 --set-v4l2 '"dw-csi.0":0[fmt:SRGGB10_1X10/1280x540]'
media-ctl -d /dev/media0 --set-v4l2 '"csi2dc":0[fmt:SRGGB10_1X10/1280x540]'
media-ctl -d /dev/media0 --set-v4l2 "\"$(get_scaler_name)\":0[fmt:SRGGB10_1X10/1280x540]"
echo "Ready to capture at 1280x540"
