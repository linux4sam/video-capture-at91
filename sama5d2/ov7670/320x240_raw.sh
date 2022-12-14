#!/bin/sh

echo Preparing OV7670 in RAW BAYER MODE
media-ctl -d /dev/media0 --set-v4l2 '4:0[fmt:SBGGR8_1X8/320x240@1/24 field:none colorspace:srgb]'
media-ctl -d /dev/media0 --set-v4l2 '"microchip_isc_scaler":0[fmt:SBGGR8_1X8/320x240 field:none colorspace:srgb]'
echo Ready to capture at 320x240

