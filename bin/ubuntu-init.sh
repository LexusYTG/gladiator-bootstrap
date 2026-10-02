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

progress 90 "Copiando sesar-shell…"
[ -f /tmp/sesar-shell ] || { printf 'ERROR|%s\n' "sesar-shell no llego al container" >> "$PROGRESS"; exit 1; }
cp /tmp/sesar-shell /root/sesar-shell
chmod 755 /root/sesar-shell

progress 92 "Limpiando…"
apt clean
rm -rf /var/lib/apt/lists/* /tmp/sesar-shell

progress 95 "Entorno listo"
touch "$MARKER"
