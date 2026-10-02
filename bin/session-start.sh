#!/data/data/com.glads1/files/usr/bin/bash
set -e

PREFIX="${PREFIX:-/data/data/com.glads1/files/usr}"
X11_DISPLAY="${X11_DISPLAY:-:0}"
PROGRESS="$PREFIX/var/log/progress.txt"
CONTAINER_NAME="${CONTAINER_NAME:-ubuntu}"
ROOTFS="$PREFIX/var/lib/proot-distro/containers/$CONTAINER_NAME/rootfs"

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
export PROOT_NO_SECCOMP=1

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

progress 60 "Lanzando escritorio…"
printf 'DONE\n' >> "$PROGRESS"

exec "$PREFIX/bin/proot-distro" login "$CONTAINER_NAME" \
    -- /bin/bash -c '
        export DISPLAY='"$X11_DISPLAY"'
        export LD_LIBRARY_PATH=/opt/mali:$LD_LIBRARY_PATH
        export VK_ICD_FILENAMES=/etc/vulkan/icd.d/mali.json
        cd /root
        exec ./sesar-shell session
    '
