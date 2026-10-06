#!/data/data/com.glads1/files/usr/bin/bash
pa_pids() { /system/bin/ps -A -o PID,NAME 2>/dev/null | awk '$2=="pulseaudio"{print $1}'; }
_PF="${PREFIX:-/data/data/com.glads1/files/usr}"
if [ "$(pa_pids | grep -c .)" = "1" ] && [ -S "$_PF/tmp/host-tmp/pulse.sock" ] && [ -S "$_PF/tmp/host-tmp/orator-pa.sock" ]; then
    echo "pulseaudio ya vivo, reuso pid=$(pa_pids | head -1)"; exit 0
fi
# start-audio-chain.sh — arranca UN solo PulseAudio en el host.
# Este script es el UNICO lugar que arranca pulse. session-bootstrap.sh
# NO debe arrancar pulse por su cuenta.

set +e

if [ -z "$SELF_REEXEC" ]; then
    PREFIX="${PREFIX:-/data/data/com.glads1/files/usr}"
    export LD_LIBRARY_PATH="$PREFIX/lib/pulseaudio/modules:$PREFIX/lib/pulseaudio:$PREFIX/lib"
    export PREFIX
    export SELF_REEXEC=1
    exec "$PREFIX/bin/bash" "$0" "$@"
fi

PREFIX="${PREFIX:-/data/data/com.glads1/files/usr}"
RUNTIME="$PREFIX/etc/pulse/gladiator.runtime.pa"
LOG="$PREFIX/var/log/pulseaudio.log"

export LD_LIBRARY_PATH="$PREFIX/lib/pulseaudio/modules:$PREFIX/lib/pulseaudio:$PREFIX/lib"
export PULSE_RUNTIME_PATH="$PREFIX/tmp/pulse-runtime"
export TMPDIR="$PREFIX/tmp"

mkdir -p "$PULSE_RUNTIME_PATH"
chmod 700 "$PULSE_RUNTIME_PATH"

# Matar TODOS los pulseaudio vivos (con reintentos hasta que mueran todos)
for i in 1 2 3 4 5 6 7 8 9 10; do
    [ -n "$(pa_pids)" ] || break
    for _p in $(pa_pids); do kill -9 "$_p" 2>/dev/null; done
    sleep 0.3
done

# Limpiar pid y sockets stale
rm -f "$PULSE_RUNTIME_PATH/pid"
rm -f "$PREFIX/tmp/host-tmp/pulse.sock" "$PREFIX/tmp/host-tmp/orator-pa.sock"
rm -rf "$PULSE_RUNTIME_PATH"/*
chmod 700 "$PULSE_RUNTIME_PATH"

# Arrancar uno solo
setsid "$PREFIX/bin/pulseaudio" --daemonize=no --exit-idle-time=-1 -n \
    --disable-shm=1 \
    -F "$RUNTIME" \
    >> "$LOG" 2>&1 &

# Esperar el socket
for i in $(seq 1 30); do
    [ -S "$PREFIX/tmp/host-tmp/pulse.sock" ] && [ -S "$PREFIX/tmp/host-tmp/orator-pa.sock" ] && break
    sleep 0.2
done

PULSE_PID=$(pa_pids | head -1)
if [ -S "$PREFIX/tmp/host-tmp/pulse.sock" ] && [ -n "$PULSE_PID" ]; then
    echo "pulseaudio OK pid=$PULSE_PID" >> "$LOG"
else
    echo "pulseaudio FALLO (pid=$PULSE_PID)" >> "$LOG"
fi
