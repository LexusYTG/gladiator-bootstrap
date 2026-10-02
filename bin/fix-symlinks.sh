#!/data/data/com.glads1/files/usr/bin/bash
PREFIX="${PREFIX:-/data/data/com.glads1/files/usr}"
cd "$PREFIX/lib" 2>/dev/null || exit 0

for f in lib*.so.*.*; do
    [ -f "$f" ] || continue
    # libX.so.A.B.C -> soname libX.so.A
    soname=$(echo "$f" | sed -E 's/^(.*\.so\.[0-9]+)\..*$/\1/')
    # libX.so.A.B.C -> base libX.so
    base=$(echo "$f" | sed -E 's/^(.*\.so)\..*$/\1/')
    [ -z "$soname" ] && continue
    [ -z "$base" ] && continue
    [ -e "$soname" ] || ln -sf "$f" "$soname"
    [ -e "$base" ] || ln -sf "$f" "$base"
done
