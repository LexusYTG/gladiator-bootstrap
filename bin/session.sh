#!/data/data/com.glads1/files/usr/bin/bash
PREFIX="${PREFIX:-/data/data/com.glads1/files/usr}"
CONTAINER_NAME="${CONTAINER_NAME:-ubuntu}"
MARKER="$PREFIX/var/lib/proot-distro/containers/$CONTAINER_NAME/rootfs/root/.sesar-ready"

if [ -f "$MARKER" ]; then
    exec "$PREFIX/bin/session-start.sh"
else
    exec "$PREFIX/bin/session-bootstrap.sh"
fi
