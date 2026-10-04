#!/bin/bash
set -e
PROGRESS="${PD_PROGRESS_FILE:-/dev/null}"
progress() { printf 'PROGRESS|%s|%s\n' "$1" "$2" >> "$PROGRESS"; }

MARKER="$HOME/.sesar-ready"
[ -f "$MARKER" ] && { progress 95 "ya inicializado"; exit 0; }

progress 76 "apt update…"
apt update -qq

progress 80 "Instalando jwm y xterm…"
if ! DEBIAN_FRONTEND=noninteractive apt install -y --no-install-recommends \
        jwm xterm fonts-dejavu-core ca-certificates 2>/tmp/apt-err.log; then
    ERR=$(tail -3 /tmp/apt-err.log | tr "\n" " " | head -c 200)
    printf "ERROR|apt install fallo: %s\n" "$ERR" >> "$PROGRESS"
    exit 1
fi

progress 85 "Instalando Scutum + Spatha + gl4es…"
[ -d /host-spatha ] || { printf 'ERROR|%s\n' "/host-spatha no montado" >> "$PROGRESS"; exit 1; }

mkdir -p /usr/lib/aarch64-linux-gnu /usr/share/vulkan/icd.d

# Scutum reemplaza Mesa
install -m 0755 /host-spatha/libEGL.so     /usr/lib/aarch64-linux-gnu/
install -m 0755 /host-spatha/libGLESv2.so  /usr/lib/aarch64-linux-gnu/

# gl4es
install -m 0755 /host-spatha/libGL.so.1    /usr/lib/aarch64-linux-gnu/

# Spatha ICD
install -m 0755 /host-spatha/libspatha-icd.so /usr/lib/aarch64-linux-gnu/
install -m 0644 /host-spatha/spatha_icd.json  /usr/share/vulkan/icd.d/

progress 88 "Instalando scutum-guard…"
[ -f /host-spatha/scutum-guard.sh ] && install -m 0755 /host-spatha/scutum-guard.sh /usr/local/bin/scutum-guard.sh
[ -f /host-spatha/gl-run ] && install -m 0755 /host-spatha/gl-run /usr/local/bin/gl-run

progress 90 "Copiando sesar-shell…"
[ -f /tmp/sesar-shell ] || { printf 'ERROR|%s\n' "sesar-shell no llego" >> "$PROGRESS"; exit 1; }
install -m 0755 /tmp/sesar-shell /root/sesar-shell

progress 92 "Limpiando…"
apt clean
rm -rf /var/lib/apt/lists/* /tmp/sesar-shell

progress 95 "Entorno listo"
touch "$MARKER"
