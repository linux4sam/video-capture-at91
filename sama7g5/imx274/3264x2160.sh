#!/bin/sh

media-ctl -d /dev/media0 --set-v4l2 '"IMX274 1-001a":0[fmt:SRGGB10_1X10/3840x2160@9/87]'
media-ctl -d /dev/media0 --set-v4l2 '"dw-csi.0":0[fmt:SRGGB10_1X10/3840x2160]'
media-ctl -d /dev/media0 --set-v4l2 '"csi2dc":0[fmt:SRGGB10_1X10/3840x2160]'
media-ctl -d /dev/media0 --set-v4l2 '"atmel_isc_scaler":0[fmt:SRGGB10_1X10/3264x2160]'
echo "Ready to capture at 3264x2160"
