#!/bin/bash
# spatha-guard.sh — idempotente. Corre DENTRO del container al inicio de la sesion.
# Copia los shims Vulkan/GLES/GL a /usr/lib/aarch64-linux-gnu/ y el JSON al ICD dir.
# Se invoca desde session-bootstrap.sh en cada arranque, así una reinstalación
# del paquete mesa-vulkan-drivers no rompe Spatha.

set +e
SRC=/host-spatha
[ ! -d "$SRC" ] && { echo "[spatha-guard] no existe $SRC"; exit 0; }

LIBDIR=/usr/lib/aarch64-linux-gnu
ICDDIR=/usr/share/vulkan/icd.d

# shim Vulkan ICD
if [ -f "$SRC/libspatha-icd.so" ]; then
    cmp -s "$SRC/libspatha-icd.so" "$LIBDIR/libspatha-icd.so" || {
        cp -f "$SRC/libspatha-icd.so" "$LIBDIR/libspatha-icd.so"
        chmod 0755 "$LIBDIR/libspatha-icd.so"
        echo "[spatha-guard] libspatha-icd.so actualizado"
    }
fi

# shim EGL/GLES (Scutum)
if [ -f "$SRC/libEGL.so" ]; then
    cmp -s "$SRC/libEGL.so" "$LIBDIR/libEGL.so" || {
        cp -f "$SRC/libEGL.so" "$LIBDIR/libEGL.so"
        chmod 0755 "$LIBDIR/libEGL.so"
        echo "[spatha-guard] libEGL.so actualizado"
    }
    # libGLESv2.so es symlink
    if [ ! -L "$LIBDIR/libGLESv2.so" ]; then
        rm -f "$LIBDIR/libGLESv2.so" "$LIBDIR/libGLESv2.so.2"
        ln -sf libEGL.so "$LIBDIR/libGLESv2.so"
        ln -sf libGLESv2.so "$LIBDIR/libGLESv2.so.2"
        echo "[spatha-guard] libGLESv2.so -> libEGL.so (symlink)"
    fi
fi

# gl4es (libGL)
if [ -f "$SRC/libGL.so.1" ]; then
    cmp -s "$SRC/libGL.so.1" "$LIBDIR/libGL.so.1" || {
        cp -f "$SRC/libGL.so.1" "$LIBDIR/libGL.so.1"
        chmod 0755 "$LIBDIR/libGL.so.1"
        echo "[spatha-guard] libGL.so.1 actualizado"
    }
fi

# JSON del ICD Vulkan
if [ -f "$SRC/spatha_icd.json" ]; then
    mkdir -p "$ICDDIR"
    cp -f "$SRC/spatha_icd.json" "$ICDDIR/spatha_icd.json"
fi

# Lorica GL 3.1 core (opcional, LIBGL_GL=31)
if [ -f /host-lorica/libGL.so.1 ]; then
    mkdir -p /root/Lorica
    cp -f /host-lorica/libGL.so.1 /root/Lorica/libGL.so.1
    chmod 0755 /root/Lorica/libGL.so.1
fi

echo "[spatha-guard] OK"
