#!/bin/sh

echo Preparing OV5640 in RAW BAYER MODE
media-ctl -d /dev/media0 --set-v4l2 '4:0[fmt:SBGGR8_1X8/1280x720@1/30 field:none colorspace:srgb xfer:srgb ycbcr:601 quantization:full-range]'
media-ctl -d /dev/media0 --set-v4l2 '"microchip_isc_scaler":0[fmt:SBGGR8_1X8/1280x720 field:none colorspace:srgb]'
echo Ready to capture at 1280x720

