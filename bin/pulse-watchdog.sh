#!/data/data/com.glads1/files/usr/bin/bash
# pulse-watchdog.sh — mantiene UN solo pulseaudio vivo. Un solo watchdog (lock).
set +e
PREFIX="${PREFIX:-/data/data/com.glads1/files/usr}"
LOG="$PREFIX/var/log/pulse-watchdog.log"
LOCK="$PREFIX/tmp/pulse-watchdog.lock"
SOCK="$PREFIX/tmp/host-tmp/pulse.sock"
PIDF="$PREFIX/tmp/pulse-runtime/pid"

pa_list() { /system/bin/ps -A -o PID,NAME 2>/dev/null | awk '$2=="pulseaudio"{print $1}'; }
pa_count() { pa_list | grep -c .; }

if ! mkdir "$LOCK" 2>/dev/null; then
    old=$(cat "$LOCK/pid" 2>/dev/null)
    if [ -n "$old" ] && [ -r "/proc/$old/cmdline" ] && grep -q pulse-watchdog "/proc/$old/cmdline" 2>/dev/null; then
        exit 0
    fi
    rm -rf "$LOCK"
    mkdir "$LOCK" 2>/dev/null || exit 0
fi
echo $$ > "$LOCK/pid"
trap 'rm -rf "$LOCK"' EXIT

echo "[$(date)] watchdog arrancado pid=$$" >> "$LOG"

while true; do
    sleep 5
    N=$(pa_count)

    if [ "$N" -gt 1 ]; then
        sleep 2
        PIDS=$(pa_list)
        N=$(echo "$PIDS" | grep -c .)
        if [ "$N" -gt 1 ]; then
            keeper=$(cat "$PIDF" 2>/dev/null)
            echo "$PIDS" | grep -qx "$keeper" || keeper=$(echo "$PIDS" | sort -n | tail -1)
            echo "[$(date)] $N pulseaudio, conservo $keeper" >> "$LOG"
            for p in $PIDS; do
                [ "$p" = "$keeper" ] || kill -9 "$p" 2>/dev/null
            done
            continue
        fi
    fi

    if [ "$N" = "1" ]; then
        [ -S "$SOCK" ] && continue
        sleep 3
        [ -S "$SOCK" ] && continue
        echo "[$(date)] pulse vivo sin socket, reinicio" >> "$LOG"
        for p in $(pa_list); do kill -9 "$p" 2>/dev/null; done
        sleep 1
        N=0
    fi

    if [ "$N" = "0" ]; then
        sleep 6
        [ "$(pa_count)" = "0" ] || continue
        echo "[$(date)] pulse caido, relanzando" >> "$LOG"
        rm -f "$PIDF" "$SOCK" "$PREFIX/tmp/host-tmp/orator-pa.sock"
        "$PREFIX/bin/start-audio-chain.sh" >> "$LOG" 2>&1
        sleep 3
    fi
done
