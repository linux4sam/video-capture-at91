#!/bin/sh

. $(dirname "$0")/../../utils.sh

echo Preparing OV7440 in RAW BAYER MODE
media-ctl --set-v4l2 '4:0[fmt:SBGGR8_1X8/640x480@1/60 field:none colorspace:srgb]'
media-ctl --set-v4l2 "\"$(get_scaler_name)\":0[fmt:SBGGR8_1X8/640x480 field:none colorspace:srgb]"
echo Ready to capture at 640x480

