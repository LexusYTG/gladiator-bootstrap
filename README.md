# Gladiator Bootstrap

**The starter kit that Gladiator unpacks on first launch.**

It bundles a lightly modified Termux base, the Linux container tooling, the Sesar desktop, and the GPU bridges (Scutum for OpenGL ES, Spatha for Vulkan), so the app has everything it needs to start a desktop session.

> This bootstrap is **not used on its own**. The Gladiator APK consumes it. For the full project, see [gladiator](https://github.com/LexusYTG/gladiator).

---

## Where it fits

[Gladiator](https://github.com/LexusYTG/gladiator) is an Android app that packs a complete Linux desktop: an X11 session with JWM and its own desktop environment, running in an Ubuntu container on top of embedded Termux and proot-distro.

On first launch, the app unpacks this bootstrap into its private storage (`/data/data/com.glads1/files/usr/`). That is what turns an empty app into a working Linux environment.

## What's inside

The package is `bootstrap-aarch64.zip` (about 90 MB). It contains:

**Termux base**
The standard Termux tools (shell, package manager, `proot`, `proot-distro`) with their libraries and config.

**Gladiator's own pieces**
- `scutumd` is the OpenGL ES bridge, Android side
- `spathad` is the Vulkan bridge, Android side
- `libcrashisolate.so` keeps a GPU driver crash from taking the bridge down
- Session scripts that start and orchestrate everything: `session-bootstrap.sh`, `session-start.sh`, `ubuntu-init.sh`

**Files for the Linux container** (in `share/spatha/`)
- An installer that puts the GPU bridges into the container (`scutum-guard.sh`, driven by `manifest.txt`; safe to re-run)
- `gl-run`, a launcher that picks the right graphics path for each app
- The container-side Scutum libraries (`libEGL.so`, `libGLESv2.so`)
- The container-side Spatha driver (`libspatha-icd.so`, `spatha_icd.json`)
- `libGL.so.1`, which is gl4es, translating classic OpenGL into OpenGL ES

**Desktop and base system**
- `share/sesar/sesar-shell`, the Sesar desktop
- `share/ubuntu-rootfs.tar.gz`, the base Ubuntu 24.04 LTS system
- `share/LICENSES/`, licenses for every component
- `SYMLINKS.txt`, the symbolic links to create after unpacking

## What changed from stock Termux

Only the session scripts were rewritten (`session-bootstrap.sh`, `session-start.sh`, `ubuntu-init.sh`), so that they start the container, the Sesar session, and the Scutum and Spatha daemons together. `proot` and `proot-distro` are unchanged. Everything else is added alongside; the rest of Termux is stock.

## Components

| Component | Source |
|---|---|---|
| Scutum | [LexusYTG/Scutum](https://github.com/LexusYTG/Scutum) |
| Spatha | [LexusYTG/Spatha](https://github.com/LexusYTG/Spatha) |
| Sesar | [LexusYTG/Sesar](https://github.com/LexusYTG/Sesar) |
| gl4es | Sebastien Chevalier |
| Termux base | Termux project |

Full details are in `share/LICENSES/ATTRIBUTION.txt`.

## Legal

All license texts and attributions are in `share/LICENSES/`. Start with `ATTRIBUTION.txt`.
