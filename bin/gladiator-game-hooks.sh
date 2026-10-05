#!/bin/bash
# Aplica wrappers de audio/lanzamiento a los juegos que existan en el container.
# Idempotente: se puede correr N veces sin efectos secundarios.
# Se invoca desde session-bootstrap.sh en cada arranque de sesion.

install -d /usr/local/bin

# --- SuperTux 2 ---
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
    for F in /usr/share/applications/supertux2.desktop \
             /usr/share/applications/org.supertuxproject.supertux2.desktop; do
        [ -f "$F" ] || continue
        [ -f "$F.bak" ] || cp "$F" "$F.bak"
        sed -i 's|^Exec=.*|Exec=/usr/local/bin/supertux2-audio.sh|' "$F"
    done
fi

# --- SuperTuxKart ---
if [ -x /usr/games/supertuxkart ]; then
    cat > /usr/local/bin/supertuxkart-audio.sh << 'WRAP'
#!/bin/bash
export PULSE_SERVER=unix:/host-tmp/pulse.sock
export ALSOFT_DRIVERS=pulse
LOG=/host-tmp/stkart.log
echo "=== launch $(date) ===" > $LOG
exec /usr/games/supertuxkart >> $LOG 2>&1
WRAP
    chmod 755 /usr/local/bin/supertuxkart-audio.sh
    for F in /usr/share/applications/supertuxkart.desktop \
             /usr/share/applications/net.supertuxkart.SuperTuxKart.desktop; do
        [ -f "$F" ] || continue
        [ -f "$F.bak" ] || cp "$F" "$F.bak"
        sed -i 's|^Exec=.*|Exec=/usr/local/bin/supertuxkart-audio.sh|' "$F"
    done
fi

# --- Red Eclipse ---
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
    for F in /usr/share/applications/redeclipse.desktop \
             /usr/share/applications/net.redeclipse.RedEclipse.desktop; do
        [ -f "$F" ] || continue
        [ -f "$F.bak" ] || cp "$F" "$F.bak"
        sed -i 's|^Exec=.*|Exec=/usr/local/bin/redeclipse-gl.sh|' "$F"
    done
fi
