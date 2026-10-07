#!/data/data/com.glads1/files/usr/bin/bash
set -e

PREFIX="${PREFIX:-/data/data/com.glads1/files/usr}"
X11_DISPLAY="${X11_DISPLAY:-:0}"
PROGRESS="$PREFIX/var/log/progress.txt"
CONTAINER_NAME="${CONTAINER_NAME:-ubuntu}"
ROOTFS="$PREFIX/var/lib/proot-distro/containers/$CONTAINER_NAME/rootfs"
HOST_TMP="$PREFIX/tmp/host-tmp"

progress() { mkdir -p "$(dirname "$PROGRESS")"; printf 'PROGRESS|%s|%s\n' "$1" "$2" >> "$PROGRESS"; }
error_exit() { printf 'ERROR|%s\n' "$1" >> "$PROGRESS"; exit 1; }

: > "$PROGRESS"
trap 'error_exit "fallo en linea $LINENO"' ERR

export TERMUX_APP__PACKAGE_NAME="com.glads1"
export TERMUX__HOME="$PREFIX/home"
export TERMUX__PREFIX="$PREFIX"
export TERMUX_VERSION="gladiator"
export PATH="$PREFIX/bin:$PREFIX/bin/applets:/usr/bin:/bin"
export PROOT_TMP_DIR="$PREFIX/tmp"
# PROOT_NO_SECCOMP desactivado (ver session-bootstrap.sh)

progress 20 "Verificando entorno…"
[ -x "$ROOTFS/root/sesar-shell" ] || error_exit "sesar-shell no esta en el container"

progress 30 "Copiando libs Mali…"
mkdir -p "$ROOTFS/opt/mali"
cp -a "$PREFIX/lib/mali/." "$ROOTFS/opt/mali/"

progress 45 "Verificando servidor X…"
if ! pgrep -f 'termux-x11' >/dev/null 2>&1; then
    termux-x11 "$X11_DISPLAY" >/dev/null 2>&1 &
    sleep 1
fi

progress 50 "Arrancando daemons…"
mkdir -p "$PREFIX/var/log" "$HOST_TMP"

if ! pgrep -f spathad >/dev/null 2>&1; then
    rm -f "$HOST_TMP/spatha.sock"
    LD_LIBRARY_PATH="/system/lib64:/vendor/lib64:/system/lib64/hw:/vendor/lib64/hw" \
    SPATHA_SOCK="$HOST_TMP/spatha.sock" SPATHA_DEBUG=1 \
        setsid "$PREFIX/bin/spathad" >> "$PREFIX/var/log/spathad.log" 2>&1 &
    for i in $(seq 1 10); do [ -S "$HOST_TMP/spatha.sock" ] && break; sleep 1; done
fi
[ -S "$HOST_TMP/spatha.sock" ] || error_exit "spathad no levanto el socket"

if ! pgrep -f scutumd >/dev/null 2>&1; then
    rm -f "$HOST_TMP/scutum.sock"
    LD_LIBRARY_PATH="/system/lib64:/vendor/lib64:/system/lib64/hw:/vendor/lib64/hw" \
    SCUTUM_LIBDIR=/system/lib64 \
    SCUTUM_SOCK="$HOST_TMP/scutum.sock" \
    LD_PRELOAD="$PREFIX/bin/libcrashisolate.so" \
        setsid "$PREFIX/bin/scutumd" >> "$PREFIX/var/log/scutumd.log" 2>&1 &
    for i in $(seq 1 10); do [ -S "$HOST_TMP/scutum.sock" ] && break; sleep 1; done
fi
[ -S "$HOST_TMP/scutum.sock" ] || error_exit "scutumd no levanto el socket"

progress 56 "Arrancando PulseAudio…"
mkdir -p "$HOST_TMP" "$PREFIX/tmp/pulse-runtime" "$PREFIX/etc/pulse"
chmod 700 "$PREFIX/tmp/pulse-runtime"
if ! pgrep -f pulseaudio >/dev/null 2>&1; then
    rm -f "$HOST_TMP/pulse.sock"
    MODS="$PREFIX/lib/pulseaudio/modules"
    sed -e "s|@MODS@|$MODS|g" -e "s|@HOST_TMP@|$HOST_TMP|g" \
        "$PREFIX/etc/pulse/gladiator.pa" > "$PREFIX/etc/pulse/gladiator.runtime.pa"
    TMPDIR="$PREFIX/tmp" \
    PULSE_RUNTIME_PATH="$PREFIX/tmp/pulse-runtime" \
    LD_LIBRARY_PATH="$MODS:$PREFIX/lib/pulseaudio:$PREFIX/lib" \
        setsid "$PREFIX/bin/pulseaudio" --daemonize=no --exit-idle-time=-1 -n \
            --disable-shm=1 \
            -F "$PREFIX/etc/pulse/gladiator.runtime.pa" \
            >> "$PREFIX/var/log/pulseaudio.log" 2>&1 &
    for i in $(seq 1 15); do [ -S "$HOST_TMP/pulse.sock" ] && break; sleep 1; done
fi
[ -S "$HOST_TMP/pulse.sock" ] && echo "pulseaudio OK" || echo "pulseaudio no levanto socket (no es fatal)"

progress 60 "Lanzando escritorio…"
printf 'DONE\n' >> "$PROGRESS"

exec "$PREFIX/bin/proot-distro" login "$CONTAINER_NAME" \
    --bind "$PREFIX/tmp/.X11-unix:/tmp/.X11-unix" \
    --bind "$PREFIX/lib/mali:/opt/mali" \
    --bind "$PREFIX/share/spatha:/host-spatha" \
    --bind "$PREFIX/share/lorica:/host-lorica" \
    --bind "$HOST_TMP:/host-tmp" \
    -- /bin/bash -c '
        export DISPLAY='"$X11_DISPLAY"'
        export LD_LIBRARY_PATH=/opt/mali:$LD_LIBRARY_PATH
        export SPATHA_SOCK=/host-tmp/spatha.sock
        export SCUTUM_SOCK=/host-tmp/scutum.sock
        export PULSE_SERVER=unix:/host-tmp/pulse.sock
        [ -x /usr/local/bin/scutum-guard.sh ] || install -m 0755 /host-spatha/scutum-guard.sh /usr/local/bin/scutum-guard.sh 2>/dev/null
        /usr/local/bin/scutum-guard.sh 2>/dev/null || true
        cd /root
        exec ./sesar-shell session
    '
