# ISC Camera Capture Tool

## Overview

isc-capture.sh is a unified camera testing tool for Microchip ISC (Image Sensor Controller) based platforms. It automates validation of the ISC video capture pipeline by testing multiple pixel formats and resolutions.

Replaces board-specific scripts with single multi-platform tool supporting direct V4L2 capture for board bring-up, driver development, and CI/CD integration.

## Features

- Automated testing: 8 formats × 5 resolutions × N runs
- Multi-platform support with auto-detection
- Quick mode for fast validation
- Hardware diagnostics mode
- Remote copy with verification
- Storage management (auto-cleanup, remote-only mode)
- Test pattern support
- POSIX-compliant shell script
- Works without network connectivity

## Requirements

Required tools (usually pre-installed):
- fswebcam - Image capture
- v4l2-ctl - V4L2 device control
- media-ctl - Media pipeline configuration

Optional (only needed with -r option):
- ssh - Remote shell
- scp - Secure copy

## Installation

Copy script to external storage to avoid filling rootfs:

```bash
scp isc-capture.sh root@<board-ip>:/mnt/sdcard/
ssh root@<board-ip> chmod +x /mnt/sdcard/isc-capture.sh
```

Or run from temporary storage:

```bash
scp isc-capture.sh root@<board-ip>:/tmp/
ssh root@<board-ip> "chmod +x /tmp/isc-capture.sh"
```

## Usage

```
isc-capture.sh [OPTIONS]

OPTIONS:
  -n N        Number of runs [1]
  -f FMTS     Formats: RGB565,YUYV,... [all]
  -s SIZES    Resolutions: 640x480,... [all]
  -o DIR      Output directory [/data/isc_captures]
  -r DEST     Remote: [user@]host[:path]
  -p 0-4      Test pattern [0=off]
  -k N        Keep last N tests
  -m FMT      Media bus format [SRGGB10_1X10]
  -q          Quick test (RGB565,YUYV at 640x480)
  -D          Show hardware diagnostics
  -R          Remote-only (delete local, requires -r)
  -l          List supported formats
  -h          Help

ENVIRONMENT:
  N, FORMATS, RESOLUTIONS, STORAGE, REMOTE, PATTERN, SKIP, TIMEOUT, KEEP,
  MBUS_FMT, MEDIA_DEV, VIDEO_DEV, SENSOR
```

## Quick Start

Fast validation:
```bash
./isc-capture.sh -q -o /mnt/sdcard/captures
```

Full validation sweep:
```bash
./isc-capture.sh -n 3 -o /mnt/sdcard/captures
```

Hardware diagnostics:
```bash
./isc-capture.sh -D
```

## Sensor Support

Default sensor: IMX219 with Bayer format SRGGB10_1X10

Note: Resolution map (640x480 through 3264x2464) is optimized for IMX219.
Other sensors may support different resolutions. The -m option changes only
the media bus format, not available resolutions. Platform detection (SAMA5D2,
SAMA7G5, SAM9X75) automatically limits maximum resolution based on SoC
capabilities.

For other sensors, override media bus format:

```bash
# OV5640
./isc-capture.sh -q -m UYVY8_2X8 -o /mnt/sdcard/captures

# OV7740
./isc-capture.sh -q -m YUYV8_2X8 -o /mnt/sdcard/captures

# IMX274
./isc-capture.sh -q -m SRGGB12_1X12 -o /mnt/sdcard/captures
```

Or set via environment:
```bash
export MBUS_FMT=UYVY8_2X8
./isc-capture.sh -q -o /mnt/sdcard/captures
```

To find sensor's media bus format:
```bash
media-ctl -d /dev/media0 -p | grep -A5 "entity.*<sensor>"
v4l2-ctl -d /dev/v4l-subdev0 --list-subdev-mbus-codes
```

## Storage Management

Important: Default storage location (/data/isc_captures) may be on rootfs. Use external storage on space-constrained boards:

External storage:
```bash
./isc-capture.sh -q -o /mnt/sdcard/captures
```

Remote-only (zero local storage):
```bash
./isc-capture.sh -q -r user@192.168.1.100 -R
```

Auto-cleanup old tests:
```bash
./isc-capture.sh -n 10 -k 5 -o /mnt/sdcard/captures
```

## Examples

### Quick Smoke Test

```bash
./isc-capture.sh -q -o /mnt/sdcard/captures
```

Tests RGB565 and YUYV at 640x480. Takes approximately 8 seconds.
Use for post-boot sanity check or quick validation after code changes.

### Full Format/Resolution Sweep

```bash
./isc-capture.sh -n 3 -o /mnt/sdcard/captures
```

Tests 8 formats × 5 resolutions = 40 captures per run.
Repeats 3 times for reliability. Total: 120 captures (~15-20 MB).

### Remote Copy

```bash
./isc-capture.sh -n 3 -r user@192.168.1.100 -o /mnt/sdcard/captures
```

Captures on board and auto-copies to remote host. Keeps both local and remote copies.

### Remote-Only Mode

```bash
./isc-capture.sh -n 10 -r user@192.168.1.100 -R
```

Uses /tmp for temporary staging, copies to remote immediately, deletes local copy after successful transfer. Zero permanent storage on board.

### Specific Format/Resolution

```bash
./isc-capture.sh -f RGB565,YUYV -s 1920x1080 -o /mnt/sdcard/captures
```

Focus on specific use case for debugging or quick iteration.

### Sensor Test Pattern

```bash
./isc-capture.sh -p 1 -f RGB565 -s 640x480 -o /mnt/sdcard/captures
```

Enables sensor color bars test pattern. Validates ISC pipeline without real sensor input.
Useful for board bring-up and ISC driver debugging.

### Long-Running Automation

```bash
./isc-capture.sh -n 1 -k 10 -o /mnt/sdcard/captures
```

Automatically deletes oldest tests, keeps only last 10 runs. Prevents unbounded storage growth.

### Without Network

```bash
./isc-capture.sh -q -o /mnt/sdcard/captures
./isc-capture.sh -n 3 -o /mnt/sdcard/captures
./isc-capture.sh -D
```

All core features work without network connectivity. Remote copy (-r) is optional.

## Output Structure

```
/mnt/sdcard/captures/
├── test1_12345/
│   ├── s_640x480_RGB565_test1_12345.png
│   ├── s_640x480_YUYV_test1_12345.png
│   ├── l_1920x1080_RGB565_test1_12345.png
│   └── test_info.txt
├── test2_12345/
└── test3_12345/
```

Filename convention: <size>_<resolution>_<format>_test<N>_<PID>.png

Size prefixes:
- s = small (640x480)
- m = medium (1640x1232)
- l = large (1920x1080)
- xl = extra-large (2560x1920)
- xxl = double-extra-large (3264×2464)

Test metadata (test_info.txt):
```
Test: test1_12345
Date: 2026-04-22 14:32:10
Pass: 40
Fail: 0
Sensor: imx219 0-0010
Kernel: 6.18.6
```

## Supported Formats

| V4L2 Code | User Format | Description |
|-----------|-------------|-------------|
| RGBP | RGB565 | 16-bit RGB packed |
| YUYV | YUYV | 4:2:2 YUV packed |
| UYVY | UYVY | 4:2:2 YUV packed (U first) |
| VYUY | VYUY | 4:2:2 YUV packed (V first) |
| AR24 | ABGR32 | 32-bit ARGB |
| Y16 | Y16 | 16-bit grayscale |
| GREY | GREY | 8-bit grayscale |
| YU12 | YUV420P | 4:2:0 YUV planar |

## Supported Resolutions

| Resolution | Use Case |
|------------|----------|
| 640×480 | Low-res testing, quick validation |
| 1640×1232 | Panoramic aspect ratio |
| 1920×1080 | Full HD |
| 2560×1920 | High resolution (platform dependent) |
| 3264×2464 | Maximum resolution (platform dependent) |

Maximum resolution is auto-detected from SoC device tree:
- SAM9X75: 2560×1920
- SAMA7G5: 3264×2464

## Exit Codes

| Code | Meaning |
|------|---------|
| 0 | Success - all captures passed |
| 1 | Hardware error - device not found |
| 2 | Argument error - invalid options |
| 3 | Capture failure - one or more captures failed |
| 4 | Storage error - cannot create directory |
| 5 | Network error - remote copy failed |

Use in scripts:
```bash
if ./isc-capture.sh -q; then
    echo "Camera OK"
else
    echo "Camera FAILED (exit code: $?)"
    ./isc-capture.sh -D > diagnostic.log
fi
```

## Troubleshooting

### /dev/video0 not found

ISC driver not loaded. Check:
```bash
./isc-capture.sh -D
dmesg | grep -i isc
```

### Sensor not found

Sensor driver not probed or I2C communication failure. Check:
```bash
./isc-capture.sh -D
dmesg | grep -i imx219
i2cdetect -y 0
```

### Capture timeout

Sensor not streaming or pipeline setup failure. Check:
```bash
media-ctl -d /dev/media0 -p
v4l2-ctl -d /dev/video0 --stream-mmap --stream-count=1
dmesg | tail -50
```

### Capture failed or empty files

Format incompatibility or hardware issue. Check:
```bash
./isc-capture.sh -f RGB565 -s 640x480
v4l2-ctl -d /dev/video0 --list-formats-ext
./isc-capture.sh -p 1 -f RGB565 -s 640x480
```

### Cannot reach remote host

Network issue or SSH keys not configured. Check:
```bash
ssh user@192.168.1.100 echo ok
ssh-keygen
ssh-copy-id user@192.168.1.100
ping 192.168.1.100
```

### Already running (locked)

Another instance running or stale lock. Check:
```bash
ps aux | grep isc-capture
rm -rf /var/lock/isc-capture.lock
```

### Script fills rootfs

Using default storage on small rootfs. Use:
```bash
./isc-capture.sh -o /mnt/sdcard/captures
./isc-capture.sh -r user@host -R
./isc-capture.sh -k 5
```

## Hardware Detection

Script automatically detects:
- Sensor device (/dev/v4l-subdev* with test_pattern control)
- Sensor entity name (from media topology)
- Platform (SAMA5D2/SAMA7G5/SAM9X75 from device tree)
- Kernel version (determines scaler entity name)
- CSI bridges (dw-csi, csi2dc if present)

Platform-specific resolution limits:
- SAMA5D2: 1920x1080 max
- SAM9X75: 2560x1920 max
- SAMA7G5: 3264x2464 max

View detection results:
```bash
./isc-capture.sh -D
```

## CI/CD Integration

Post-boot validation script:
```bash
#!/bin/sh
if /mnt/sdcard/isc-capture.sh -q -o /tmp/camera_test; then
    echo "Camera initialization OK"
else
    echo "Camera initialization FAILED"
    /mnt/sdcard/isc-capture.sh -D > /tmp/camera_diag.log
    exit 1
fi
```

GitLab CI pipeline:
```yaml
camera_validation:
  stage: test
  script:
    - ssh root@${BOARD_IP} /mnt/sdcard/isc-capture.sh -q -o /tmp/test
    - scp root@${BOARD_IP}:/tmp/test/test1_*/test_info.txt ./results/
  artifacts:
    paths:
      - results/
```

Nightly regression test:
```bash
#!/bin/sh
# Cron: 0 2 * * *

if /mnt/sdcard/isc-capture.sh -n 5 -r buildserver -R; then
    echo "$(date): Camera test PASSED"
else
    echo "$(date): Camera test FAILED"
    /mnt/sdcard/isc-capture.sh -D | mail -s "Camera Failure" team@example.com
fi
```

## Performance

| Test Mode | Formats | Resolutions | Time | Storage |
|-----------|---------|-------------|------|---------|
| Quick (-q) | 2 | 1 | ~8 sec | ~2 MB |
| Single run | 8 | 5 | ~60 sec | ~8 MB |
| 3 runs (-n 3) | 8 | 5 | ~3 min | ~24 MB |
| 10 runs (-n 10) | 8 | 5 | ~10 min | ~80 MB |

Times vary with sensor, skip frames, and board performance.

## FAQ

Q: Does this work without ethernet/network?
A: Yes. Network is only needed for remote copy (-r option). All core functionality works offline.

Q: Can I test a custom format/resolution?
A: Currently limited to predefined formats/resolutions. Custom sizes require script modification.

Q: How do I add support for a new sensor?
A: Find sensor's media bus format with 'media-ctl -p' or 'v4l2-ctl --list-subdev-mbus-codes', then use -m option. Example: ./isc-capture.sh -q -m UYVY8_2X8

Q: Can I run multiple instances simultaneously?
A: No. Script uses locking to prevent concurrent access to video devices.

Q: What if I interrupt the script (Ctrl+C)?
A: Cleanup trap resets sensor test pattern, stops streaming, and removes lock file. Safe to interrupt.

Q: Can I use this with libcamera running?
A: No. libcamera and direct V4L2 access are mutually exclusive. Stop libcamera before running this script.

Q: Where are test results stored by default?
A: /data/isc_captures - use -o /mnt/sdcard/captures on space-constrained boards.

Q: How do I delete old test results?
A: Use -k N to auto-delete old tests, or manually: rm -rf /mnt/sdcard/captures/test*

Q: Which sensors are supported?
A: Any sensor supported by ISC driver. Default is IMX219. For others, specify media bus format with -m option.

## License

Copyright (c) 2026 Microchip Technology Inc.
Licensed under MIT License - see LICENSES directory in repository.

## Contributing

To contribute improvements or report issues, submit pull requests to:
https://github.com/linux4sam/video-capture-at91
