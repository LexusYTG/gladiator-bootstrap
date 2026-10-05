#!/data/data/com.glads1/files/usr/bin/bash
PREFIX="${PREFIX:-/data/data/com.glads1/files/usr}"
HOST_TMP="$PREFIX/tmp/host-tmp"
SOCK="$HOST_TMP/orator-pa.sock"
LOG="$PREFIX/var/log/oratord.log"

for i in $(seq 1 20); do
    [ -S "$SOCK" ] && break
    sleep 0.5
done

if [ ! -S "$SOCK" ]; then
    echo "orator-pa.sock no aparecio" >> "$LOG"
    exit 0
fi

for OLD in $(pgrep -x oratord 2>/dev/null); do
    if ! grep -qa "$SOCK" /proc/$OLD/cmdline 2>/dev/null; then
        kill -9 "$OLD" 2>/dev/null
    fi
done

if ! pgrep -x oratord >/dev/null 2>&1; then
    ORATOR_VERBOSE=1 setsid "$PREFIX/bin/oratord" "$SOCK" \
        >> "$LOG" 2>&1 < /dev/null &
    sleep 1
fi

if pgrep -x oratord >/dev/null 2>&1; then
    echo "oratord OK pid=$(pgrep -x oratord | head -1)" >> "$LOG"
else
    echo "oratord no arranco" >> "$LOG"
fi
