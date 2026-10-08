#!/bin/bash
HOST_SPATHA=/host-spatha
MANIFEST="$HOST_SPATHA/manifest.txt"
log() { echo "[scutum-guard] $*"; }
[ -d "$HOST_SPATHA" ] || { log "ERROR: $HOST_SPATHA no montado"; exit 1; }
md5f() { [ -f "$1" ] && [ ! -L "$1" ] && md5sum "$1" 2>/dev/null | cut -d' ' -f1 || echo ""; }
do_file() { local src="$HOST_SPATHA/$1" dst="$2" mode="${3:-0755}"; [ -f "$src" ] || return 0; mkdir -p "$(dirname "$dst")"; local a b; a=$(md5f "$src"); b=$(md5f "$dst"); [ "$a" = "$b" ] && return 0; log "instalando $dst"; rm -f "$dst"; cp -f "$src" "$dst"; chmod "$mode" "$dst"; }
do_symlink() { local target="$1" dst="$2"; mkdir -p "$(dirname "$dst")"; if [ ! -L "$dst" ] || [ "$(readlink "$dst")" != "$target" ]; then log "symlink $dst -> $target"; rm -f "$dst"; ln -sf "$target" "$dst"; fi; }
do_disable() { [ -f "$1" ] && [ ! -f "$1.disabled" ] && { log "disable $1"; mv -f "$1" "$1.disabled"; }; }
if [ -f "$MANIFEST" ]; then
    log "manifest: $MANIFEST"
    while IFS='|' read -r tipo src dst mode; do
        [ -z "$tipo" ] && continue
        case "$tipo" in \#*) continue ;; esac
        case "$tipo" in
            file)    do_file "$src" "$dst" "$mode" ;;
            symlink) do_symlink "$src" "$dst" ;;
            disable) do_disable "$dst" ;;
        esac
    done < "$MANIFEST"
fi
mkdir -p /etc/profile.d
cat > /etc/profile.d/gladiator-gl.sh << 'ENVEOF'
# Solo paths de sockets y runtime. NO preload, NO SDL_*.
export SPATHA_SOCK=/host-tmp/spatha.sock
export SCUTUM_SOCK=/host-tmp/scutum.sock
export XDG_RUNTIME_DIR=/tmp
export VK_ICD_FILENAMES=/usr/share/vulkan/icd.d/spatha_icd.json
ENVEOF
chmod 0644 /etc/profile.d/gladiator-gl.sh
# Persistir en /etc/environment para login shells no interactivos (pam_env)
if ! grep -q '^VK_ICD_FILENAMES=' /etc/environment 2>/dev/null; then
    echo 'VK_ICD_FILENAMES=/usr/share/vulkan/icd.d/spatha_icd.json' >> /etc/environment
fi
mkdir -p /var/lib && touch /var/lib/scutum-guard.ok
log "OK"
