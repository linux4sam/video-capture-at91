#!/bin/sh
# =============================================================================
# isc-capture.sh - ISC Camera Capture Tool
# =============================================================================
# Automated camera capture for Microchip ISC-based platforms
# Supports: SAMA5D2, SAMA7G5, SAM9X75, and future ISC-equipped boards
#
# Exit codes: 0=success 1=hardware 2=args 3=capture-fail 4=storage 5=network
# =============================================================================

set -e  # Exit on error (except where explicitly handled)

# =============================================================================
# DEFAULTS (override via environment or args)
# =============================================================================
: ${N:=1}                           # Test runs
: ${FORMATS:=all}                   # Formats to test
: ${RESOLUTIONS:=all}               # Resolutions to test
: ${STORAGE:=/data/isc_captures}    # Output directory
: ${REMOTE:=}                       # Remote SCP destination
: ${PATTERN:=0}                     # Test pattern (0-4)
: ${SKIP:=20}                       # Skip frames
: ${TIMEOUT:=30}                    # Capture timeout
: ${KEEP:=0}                        # Keep last N tests
: ${MEDIA_DEV:=/dev/media0}
: ${VIDEO_DEV:=/dev/video0}
: ${SENSOR:=}                       # Auto-detect if empty
: ${MBUS_FMT:=SRGGB10_1X10}         # Default: IMX219 Bayer format

LOCKFILE=/var/lock/isc-capture.lock
LOG=/tmp/isc_$$.log
QUICK_MODE=0
DIAGNOSE_MODE=0
REMOTE_ONLY=0
LIST_FORMATS=0

# =============================================================================
# CORE FUNCTIONS
# =============================================================================

die() { echo "ERROR: $*" >&2; exit "${2:-1}"; }
log() { echo "[$(date +%H:%M:%S)] $*"; }

cleanup() {
    # Restore test pattern only if SENSOR_DEV is set and device exists
    if [ -n "$SENSOR_DEV" ] && [ -c "$SENSOR_DEV" ]; then
        v4l2-ctl -d "$SENSOR_DEV" --set-ctrl test_pattern=0 2>/dev/null || true
    fi
    rm -f "$LOG"
    # Clean up lock (both flock and mkdir variants)
    if [ -d "$LOCKFILE" ]; then
        rmdir "$LOCKFILE" 2>/dev/null || true
    else
        rm -f "$LOCKFILE" 2>/dev/null || true
    fi
}

usage() {
    cat <<EOF
Usage: $(basename "$0") [OPTIONS]

OPTIONS:
  -n N        Number of runs [1]
  -f FMTS     Formats: RGB565,YUYV,... [all]
  -s SIZES    Resolutions: 640x480,... [all]
  -o DIR      Output directory [/data/isc_captures]
  -r DEST     Remote: [user@]host[:path]
  -p 0-4      Test pattern [0=off]
  -k N        Keep last N tests
  -m FMT      Media bus format [SRGGB10_1X10]
  -q          Quick test (RGB565,YUYV at 640x480 only)
  -D          Show hardware diagnostics and exit
  -R          Copy to remote only, delete local (requires -r)
  -l          List supported formats and resolutions
  -h          Help

ENVIRONMENT:
  N, FORMATS, RESOLUTIONS, STORAGE, REMOTE, PATTERN, SKIP, TIMEOUT, KEEP,
  MBUS_FMT, MEDIA_DEV, VIDEO_DEV, SENSOR

EXAMPLES:
  $0 -q -o /mnt/sdcard/captures
  $0 -n 3 -f RGB565,YUYV -s 1920x1080
  $0 -r user@host -R
  $0 -D
  $0 -q -m UYVY8_2X8  # For OV5640

EXIT: 0=ok 1=hw 2=args 3=fail 4=storage 5=network
EOF
    exit 2
}

list_formats() {
    cat <<EOF
========================================================================
 Supported Formats
========================================================================
V4L2 Code  User Format  Description
---------  -----------  -----------------------------------------------
RGBP       RGB565       16-bit RGB packed
YUYV       YUYV         4:2:2 YUV packed
UYVY       UYVY         4:2:2 YUV packed (U first)
VYUY       VYUY         4:2:2 YUV packed (V first)
AR24       ABGR32       32-bit ARGB
Y16        Y16          16-bit grayscale
GREY       GREY         8-bit grayscale
YU12       YUV420P      4:2:0 YUV planar

========================================================================
 Supported Resolutions
========================================================================
Resolution   Use Case
-----------  -------------------------------------------------------
640×480      Low-res testing, quick validation
1640×1232    Panoramic aspect ratio
1920×1080    Full HD (common application target)
2560×1920    High resolution (platform dependent)
3264×2464    Maximum resolution (platform dependent)

Note: Maximum resolution is auto-detected from SoC device tree.
========================================================================
EOF
    exit 0
}

diagnose() {
    echo "========================================================================="
    echo " ISC Hardware Diagnostics"
    echo "========================================================================="
    echo

    # Board info
    echo "=== Board Information ==="
    if [ -e /sys/firmware/devicetree/base/compatible ]; then
        echo "Board: $(cat /sys/firmware/devicetree/base/compatible | tr '\0' ' ')"
    fi
    echo "Kernel: $(uname -r)"
    echo "Arch: $(uname -m)"
    echo

    # Video devices
    echo "=== Video Devices ==="
    ls -l /dev/video* /dev/media* 2>/dev/null || echo "No video devices found"
    echo

    # Media topology
    echo "=== Media Topology ==="
    if [ -e "$MEDIA_DEV" ]; then
        media-ctl -d "$MEDIA_DEV" -p 2>&1 || echo "media-ctl failed"
    else
        echo "$MEDIA_DEV not found"
    fi
    echo

    # Video capabilities
    echo "=== Video Device Capabilities ==="
    if [ -e "$VIDEO_DEV" ]; then
        v4l2-ctl -d "$VIDEO_DEV" --all 2>&1 || echo "v4l2-ctl failed"
    else
        echo "$VIDEO_DEV not found"
    fi
    echo

    # Sensor subdevices
    echo "=== Sensor Subdevices ==="
    for dev in /dev/v4l-subdev*; do
        [ -e "$dev" ] || continue
        echo "Device: $dev"
        v4l2-ctl -d "$dev" --list-ctrls 2>&1 | head -20
        echo
    done

    # Recent kernel messages
    echo "=== Recent Kernel Messages (ISC/Camera) ==="
    dmesg | grep -iE "isc|imx|ov|camera|v4l2" | tail -30
    echo

    echo "========================================================================="
    exit 0
}

# Parse args using getopts (POSIX-compliant)
while getopts "n:f:s:o:r:p:k:m:qDRlh" opt; do
    case $opt in
        n) N=$OPTARG ;;
        f) FORMATS=$OPTARG ;;
        s) RESOLUTIONS=$OPTARG ;;
        o) STORAGE=$OPTARG ;;
        r) REMOTE=$OPTARG ;;
        p) PATTERN=$OPTARG ;;
        k) KEEP=$OPTARG ;;
        m) MBUS_FMT=$OPTARG ;;
        q) QUICK_MODE=1 ;;
        D) DIAGNOSE_MODE=1 ;;
        R) REMOTE_ONLY=1 ;;
        l) LIST_FORMATS=1 ;;
        h) usage ;;
        *) usage ;;
    esac
done

# Handle diagnose and list modes early
[ "$DIAGNOSE_MODE" -eq 1 ] && diagnose
[ "$LIST_FORMATS" -eq 1 ] && list_formats

# Handle quick mode
if [ "$QUICK_MODE" -eq 1 ]; then
    FORMATS="RGB565,YUYV"
    RESOLUTIONS="640x480"
fi

# Validate remote-only
if [ "$REMOTE_ONLY" -eq 1 ] && [ -z "$REMOTE" ]; then
    die "-R (remote-only) requires -r <remote-host>" 2
fi

# Validate
case $N in ''|*[!0-9]*|0) die "Invalid -n: $N" 2 ;; esac
case $PATTERN in [0-4]) ;; *) die "Invalid -p: $PATTERN (0-4)" 2 ;; esac
case $KEEP in ''|*[!0-9]*) die "Invalid -k: $KEEP" 2 ;; esac

# Check dependencies
for cmd in fswebcam v4l2-ctl media-ctl; do
    command -v $cmd >/dev/null || die "Missing: $cmd" 2
done
[ -n "$REMOTE" ] && { command -v scp >/dev/null || die "Missing: scp" 2; }

# Check hardware
[ -e "$MEDIA_DEV" ] || die "$MEDIA_DEV not found (run -D for diagnostics)" 1
[ -e "$VIDEO_DEV" ] || die "$VIDEO_DEV not found (run -D for diagnostics)" 1

# Acquire lock
if command -v flock >/dev/null 2>&1; then
    exec 200>"$LOCKFILE"
    flock -n 200 || die "Already running (locked)" 2
else
    # Fallback to mkdir (atomic on most filesystems)
    if ! mkdir "$LOCKFILE" 2>/dev/null; then
        die "Already running (locked)" 2
    fi
fi

trap cleanup EXIT INT TERM

# Create storage (unless remote-only)
if [ "$REMOTE_ONLY" -eq 0 ]; then
    mkdir -p "$STORAGE" || die "Cannot create $STORAGE" 4
else
    # Use /tmp for staging
    STORAGE=/tmp/isc_captures_$$
    mkdir -p "$STORAGE" || die "Cannot create temp $STORAGE" 4
fi


# =============================================================================
# HARDWARE DETECTION
# =============================================================================

# Find sensor
for dev in /dev/v4l-subdev*; do
    [ -e "$dev" ] || continue
    if v4l2-ctl -d "$dev" --list-ctrls 2>/dev/null | grep -q test_pattern; then
        SENSOR_DEV=$dev
        break
    fi
done
[ -z "$SENSOR_DEV" ] && {
    SENSOR_DEV=$(media-ctl -d "$MEDIA_DEV" -p 2>/dev/null | awk '
        /subtype Sensor/ {found=1; next}
        found && /device node name/ {print $NF; exit}')
}
[ -z "$SENSOR_DEV" ] && die "Sensor not found (run -D for diagnostics)" 1

# Get sensor entity name
[ -z "$SENSOR" ] && {
    SENSOR=$(media-ctl -d "$MEDIA_DEV" -p 2>/dev/null | awk -v dev="$SENSOR_DEV" '
        /^- entity/ {name=$0; sub(/^- entity [0-9]+: /,"",name); sub(/ \(.*/,"",name)}
        /device node name/ && $NF==dev {print name; exit}')
}
[ -z "$SENSOR" ] && die "Sensor entity not found (run -D for diagnostics)" 1

# Detect platform
MAX_W=9999
MAX_H=9999
if [ -e /sys/firmware/devicetree/base/compatible ]; then
    COMPAT=$(tr -d '\0' < /sys/firmware/devicetree/base/compatible)
    case $COMPAT in
        *sama5d2*) MAX_W=1920; MAX_H=1080 ;;
        *sama7g5*) MAX_W=3264; MAX_H=2464 ;;
        *sam9x7*) MAX_W=2560; MAX_H=1920 ;;
    esac
fi

# Get scaler name (kernel version dependent)
KVER=$(uname -r | sed 's/-rc.*//' | cut -d- -f1)
KMAJ=${KVER%%.*}; KMIN=${KVER#*.}; KMIN=${KMIN%%.*}
if [ "$KMAJ" -ge 6 ] && [ "$KMIN" -ge 2 ]; then
    SCALER=microchip_isc_scaler
else
    SCALER=atmel_isc_scaler
fi

# Detect CSI entities (optional)
TOPO=$(media-ctl -d "$MEDIA_DEV" -p 2>/dev/null)
CSI=$(echo "$TOPO" | awk '/^- entity/ && /dw-csi/ {sub(/^- entity [0-9]+: /,""); sub(/ \(.*/,""); print; exit}')
CSI2DC=$(echo "$TOPO" | awk '/^- entity/ && /csi2dc/ {sub(/^- entity [0-9]+: /,""); sub(/ \(.*/,""); print; exit}')

# =============================================================================
# FORMAT & RESOLUTION LISTS
# =============================================================================

# Format map: v4l2:fswebcam
ALL_FMTS="RGBP:RGB565 YUYV:YUYV UYVY:UYVY VYUY:VYUY AR24:ABGR32 Y16:Y16 GREY:GREY YU12:YUV420P"

if [ "$FORMATS" = "all" ]; then
    FMTS=$ALL_FMTS
else
    FMTS=
    for want in $(echo "$FORMATS" | tr , ' '); do
        match=
        for entry in $ALL_FMTS; do
            [ "${entry#*:}" = "$want" ] && { match=$entry; break; }
        done
        [ -z "$match" ] && die "Unknown format: $want (use -h for list)" 2
        FMTS="$FMTS $match"
    done
fi

# Resolution map: display:media_w:media_h:v4l2_w:v4l2_h:prefix
ALL_RES="640x480:640:480:640:480:s
1640x1232:1640:1232:1640:1232:m
1920x1080:1920:1080:1920:1080:l
2560x1920:2560:1920:2560:1920:xl
3264x2464:3280:2464:3264:2464:xxl"

if [ "$RESOLUTIONS" = "all" ]; then
    RES=$ALL_RES
else
    RES=
    for want in $(echo "$RESOLUTIONS" | tr , ' '); do
        match=
        for entry in $ALL_RES; do
            [ "${entry%%:*}" = "$want" ] && { match=$entry; break; }
        done
        [ -z "$match" ] && die "Unknown resolution: $want (use -h for list)" 2
        RES="$RES
$match"
    done
fi

# Apply max resolution cap
if [ "$MAX_W" -lt 9999 ]; then
    RES_FILTERED=
    for entry in $RES; do
        [ -z "$entry" ] && continue
        IFS=: read -r disp mw mh vw vh pfx <<EOF
$entry
EOF
        [ "$vw" -le "$MAX_W" ] && [ "$vh" -le "$MAX_H" ] && RES_FILTERED="$RES_FILTERED
$entry"
    done
    RES=$RES_FILTERED
fi

[ -z "$RES" ] && die "No resolutions available for this platform" 2

# =============================================================================
# SETUP & BANNER
# =============================================================================

# Set test pattern
if [ "$PATTERN" -ne 0 ]; then
    # Retry up to 3 times with delay - sensor may need time after driver probe
    # or previous stream termination before accepting test_pattern control
    i=1
    while [ "$i" -le 3 ]; do
        v4l2-ctl -d "$SENSOR_DEV" \
            --set-ctrl test_pattern="$PATTERN" >/dev/null 2>&1 && break
        [ "$i" -lt 3 ] && sleep 1
        i=$((i + 1))
    done
    [ "$i" -gt 3 ] && log "WARNING: test_pattern=$PATTERN did not apply"
fi

# Normalize remote
if [ -n "$REMOTE" ]; then
    case $REMOTE in
        *:*) ;;
        *@*) REMOTE="$REMOTE:~/isc_captures" ;;
        *) REMOTE="$(whoami)@$REMOTE:~/isc_captures" ;;
    esac
    # Preflight SSH connectivity
    HOST=${REMOTE%:*}
    if ! ssh -o BatchMode=yes -o ConnectTimeout=5 "$HOST" "echo ok" >/dev/null 2>&1; then
        die "Cannot reach $HOST - check network, SSH keys, or hostname" 5
    fi
fi

# Get next test number - use PID to avoid race between concurrent runs
# (lock prevents concurrent capture, but not concurrent directory creation)
NEXT=1
for d in "$STORAGE"/test[0-9]*_*; do
    [ -d "$d" ] || continue
    num=${d##*/test}
    num=${num%%_*}
    [ "$num" -ge "$NEXT" ] && NEXT=$((num + 1))
done

# Banner
echo "========================================================================="
echo " ISC Capture"
echo "========================================================================="
echo " Sensor   : $SENSOR"
echo " Runs     : $N (test${NEXT}_$$..test$((NEXT+N-1))_$$)"
[ "$QUICK_MODE" -eq 1 ] && echo " Mode     : Quick (RGB565,YUYV @ 640x480)"
echo " Pattern  : $PATTERN"
[ "$REMOTE_ONLY" -eq 0 ] && echo " Storage  : $STORAGE"
[ -n "$REMOTE" ] && echo " Remote   : $REMOTE"
[ "$REMOTE_ONLY" -eq 1 ] && echo " Mode     : Remote-only (no local storage)"
echo "========================================================================="
echo

# Counters
PASS=0
FAIL=0

# =============================================================================
# CAPTURE LOOP
# =============================================================================

for run in $(seq $NEXT $((NEXT + N - 1))); do
    TEST_DIR="$STORAGE/test${run}_$$"
    mkdir -p "$TEST_DIR"

    log "Run $run (test${run}_$$)"
    RUN_PASS=0
    RUN_FAIL=0

    # Process each resolution
    for res_entry in $RES; do
        [ -z "$res_entry" ] && continue

        IFS=: read -r disp mw mh vw vh pfx <<EOF
$res_entry
EOF

        echo "  [$disp]"

        # Setup pipeline (single media-ctl call)
        LINKS="\"$SENSOR\":0[fmt:$MBUS_FMT/${mw}x${mh}]"
        [ -n "$CSI" ] && LINKS="$LINKS,\"$CSI\":0[fmt:$MBUS_FMT/${mw}x${mh}]"
        [ -n "$CSI2DC" ] && LINKS="$LINKS,\"$CSI2DC\":0[fmt:$MBUS_FMT/${mw}x${mh}]"
        LINKS="$LINKS,\"$SCALER\":0[fmt:$MBUS_FMT/${mw}x${mh}]"

        if ! media-ctl -d "$MEDIA_DEV" -V "$LINKS" 2>/dev/null; then
            echo "    Pipeline setup failed"
            continue
        fi

        # Capture each format
        for fmt_entry in $FMTS; do
            v4l2fmt=${fmt_entry%:*}
            fswfmt=${fmt_entry#*:}

            out="$TEST_DIR/${pfx}_${disp}_${fswfmt}_test${run}_$$.png"

            v4l2-ctl -d "$VIDEO_DEV" \
                --set-fmt-video "width=${vw},height=${vh},pixelformat=${v4l2fmt}" \
                >/dev/null 2>&1 || true

            # Capture (skip frames based on pattern)
            skip=$SKIP
            [ "$PATTERN" -ne 0 ] && skip=2

            # Run capture with explicit timeout handling
            if timeout $TIMEOUT fswebcam -d "$VIDEO_DEV" -p "$fswfmt" \
                -r ${vw}x${vh} -S $skip "$out" >"$LOG" 2>&1; then
                # Check if file was created and has content
                if [ -s "$out" ]; then
                    size=$(stat -c%s "$out" 2>/dev/null || wc -c < "$out")
                    printf "    %-10s %-8s OK (%d bytes)\n" "$disp" "$fswfmt" "$size"
                    PASS=$((PASS + 1))
                    RUN_PASS=$((RUN_PASS + 1))
                else
                    printf "    %-10s %-8s FAIL (empty file)\n" "$disp" "$fswfmt"
                    FAIL=$((FAIL + 1))
                    RUN_FAIL=$((RUN_FAIL + 1))
                fi
            else
                exitcode=$?
                if [ $exitcode -eq 124 ]; then
                    printf "    %-10s %-8s TIMEOUT\n" "$disp" "$fswfmt"
                else
                    printf "    %-10s %-8s FAIL\n" "$disp" "$fswfmt"
                fi
                FAIL=$((FAIL + 1))
                RUN_FAIL=$((RUN_FAIL + 1))
            fi
        done
    done

    # Generate report
    cat > "$TEST_DIR/test_info.txt" <<EOF
Test: test${run}_$$
Date: $(date)
Pass: $RUN_PASS
Fail: $RUN_FAIL
Sensor: $SENSOR
Kernel: $(uname -r)
EOF

    # Remote copy
    if [ -n "$REMOTE" ]; then
        log "Copying to $REMOTE/test${run}_$$"
        HOST=${REMOTE%:*}
        RPATH=${REMOTE#*:}

        if ssh -o BatchMode=yes "$HOST" "mkdir -p $RPATH/test${run}_$$" 2>/dev/null && \
           scp -q "$TEST_DIR"/* "$REMOTE/test${run}_$$/" 2>/dev/null; then
            # Verify
            cnt_local=$(find "$TEST_DIR" -maxdepth 1 -name "*.png" | wc -l | tr -d ' ')
            cnt_remote=$(ssh -o BatchMode=yes "$HOST" \
                sh -c 'find "\$1" -maxdepth 1 -name "*.png" | wc -l' \
                -- "${RPATH}/test${run}_$$" \
                2>/dev/null | tr -d ' ') || cnt_remote=0
            : "${cnt_remote:=0}"

            if [ "$cnt_local" -eq "$cnt_remote" ]; then
                log "Remote copy verified ($cnt_local files)"
                # Delete local copy if remote-only mode
                [ "$REMOTE_ONLY" -eq 1 ] && rm -rf "$TEST_DIR"
            else
                log "WARNING: Copy incomplete (local:$cnt_local remote:$cnt_remote)"
            fi
        else
            log "WARNING: Remote copy failed"
            [ "$REMOTE_ONLY" -eq 1 ] && die "Remote copy required but failed" 5
        fi
    fi

    log "Run $run: pass=$RUN_PASS fail=$RUN_FAIL"
    echo
done

# =============================================================================
# CLEANUP & SUMMARY
# =============================================================================

# Keep last N (note: while-read runs in subshell, rm failures are not fatal)
if [ "$KEEP" -gt 0 ] && [ "$REMOTE_ONLY" -eq 0 ]; then
    count=0
    for d in "$STORAGE"/test[0-9]*_*; do
        [ -d "$d" ] && count=$((count + 1))
    done

    if [ "$count" -gt "$KEEP" ]; then
        delete=$((count - KEEP))
        log "Cleaning up $delete old tests"
        ls -dt "$STORAGE"/test[0-9]*_* 2>/dev/null | tail -n $delete | while read d; do
            rm -rf "$d"
        done
    fi
fi

# Cleanup temp storage if remote-only
if [ "$REMOTE_ONLY" -eq 1 ]; then
    rm -rf "$STORAGE" || true
fi

echo "========================================================================="
echo " Complete: $N runs"
echo " Results: pass=$PASS fail=$FAIL"
[ "$QUICK_MODE" -eq 1 ] && echo " Mode: Quick test"
echo "========================================================================="

[ "$FAIL" -gt 0 ] && exit 3
exit 0
