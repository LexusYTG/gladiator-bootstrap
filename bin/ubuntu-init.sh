#!/bin/bash
set -e
PROGRESS="${PD_PROGRESS_FILE:-/dev/null}"
progress() { printf 'PROGRESS|%s|%s\n' "$1" "$2" >> "$PROGRESS"; }

progress 74 "Wrappers de juegos con audio…"
install -d /usr/local/bin
if [ -x /usr/games/supertux2 ]; then
    cat > /usr/local/bin/supertux2-audio.sh << 'WRAP'
#!/bin/bash
export PULSE_SERVER=unix:/host-tmp/pulse.sock
export ALSOFT_DRIVERS=pulse
LOG=/host-tmp/stk2.log
echo "=== launch $(date) ===" > $LOG
exec /usr/games/supertux2 >> $LOG 2>&1
WRAP
    chmod 755 /usr/local/bin/supertux2-audio.sh
    F=/usr/share/applications/supertux2.desktop
    if [ -f "$F" ]; then
        [ -f "$F.bak" ] || cp "$F" "$F.bak"
        sed -i "s|^Exec=.*|Exec=/usr/local/bin/supertux2-audio.sh|" "$F"
    fi
fi
if [ -x /usr/games/redeclipse ]; then
    cat > /usr/local/bin/redeclipse-gl.sh << 'WRAP'
#!/bin/bash
export DISPLAY=:0
export XDG_RUNTIME_DIR=/tmp
export SCUTUM_SOCK=/host-tmp/scutum.sock
export SPATHA_SOCK=/host-tmp/spatha.sock
export LD_LIBRARY_PATH=/usr/lib/aarch64-linux-gnu
export LD_PRELOAD=/usr/lib/aarch64-linux-gnu/libGL.so.1
export SC_DEPTH_BITS=0
LOG=/host-tmp/redeclipse.log
echo "=== launch $(date) ===" > $LOG
cd /root
exec /usr/games/redeclipse >> $LOG 2>&1
WRAP
    chmod 755 /usr/local/bin/redeclipse-gl.sh
    F=/usr/share/applications/redeclipse.desktop
    if [ -f "$F" ]; then
        [ -f "$F.bak" ] || cp "$F" "$F.bak"
        sed -i "s|^Exec=.*|Exec=/usr/local/bin/redeclipse-gl.sh|" "$F"
    fi
fi

MARKER="$HOME/.sesar-ready"
[ -f "$MARKER" ] && { progress 95 "ya inicializado"; exit 0; }

# Auto-reparacion: si un intento anterior se interrumpio, dpkg queda
# inconsistente y todos los apt install fallan hasta correr esto.
if [ -e /var/lib/dpkg/status ]; then
    progress 75 "Reparando dpkg (si hacia falta)…"
    dpkg --configure -a >/dev/null 2>&1 || true
    DEBIAN_FRONTEND=noninteractive apt install -y --fix-broken >/dev/null 2>&1 || true
fi

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
[ -f /host-spatha/manifest.txt ] || { printf 'ERROR|%s\n' "manifest.txt no encontrado" >> "$PROGRESS"; exit 1; }
[ -f /host-spatha/scutum-guard.sh ] || { printf 'ERROR|%s\n' "scutum-guard.sh no encontrado" >> "$PROGRESS"; exit 1; }

# Instalar el guard y correrlo. El guard lee manifest.txt y hace TODO:
# copia .so, crea symlinks correctos (libGLESv2.so -> libEGL.so, etc),
# deshabilita ICDs de Mesa, escribe /etc/profile.d/.
mkdir -p /usr/local/bin
install -m 0755 /host-spatha/scutum-guard.sh /usr/local/bin/scutum-guard.sh
install -m 0755 /host-spatha/gl-run /usr/local/bin/gl-run 2>/dev/null || true
/usr/local/bin/scutum-guard.sh || { printf 'ERROR|%s\n' "scutum-guard fallo" >> "$PROGRESS"; exit 1; }

progress 90 "Copiando sesar-shell…"
[ -f /tmp/sesar-shell ] || { printf 'ERROR|%s\n' "sesar-shell no llego" >> "$PROGRESS"; exit 1; }
install -m 0755 /tmp/sesar-shell /root/sesar-shell

progress 92 "Limpiando…"
apt clean
rm -rf /var/lib/apt/lists/* /tmp/sesar-shell

progress 95 "Entorno listo"
touch "$MARKER"
