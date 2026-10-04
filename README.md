# Gladiator Bootstrap

Bootstrap completo del entorno Gladiator: Termux base modificado + proot-distro + rootfs Ubuntu + escritorio Sesar + integracion con Scutum (GLES) y Spatha (Vulkan).

## Que es Gladiator

Aplicacion Android (APK) que empaqueta un entorno Linux completo con escritorio grafico, corriendo sobre Termux embebido y proot-distro. El usuario abre el APK y tiene una sesion X11 con JWM y un entorno de escritorio propio.

## Que contiene este bootstrap

`bootstrap-aarch64.zip` (90 MB) — arbol completo de `$PREFIX` que se extrae al sandbox del APK en el primer arranque:

- **bin/**: Termux base (bash, apt, proot, proot-distro, etc.) mas los daemons bionic de Gladiator:
  - `spathad` — daemon de Spatha (Vulkan, host)
  - `scutumd` — daemon de Scutum (GLES/EGL, host)
  - `libcrashisolate.so` — aislador de SIGSEGV para scutumd
  - `session-bootstrap.sh`, `session-start.sh` — orquestacion de la sesion
  - `ubuntu-init.sh` — instalacion del container
- **lib/**, **include/**, **libexec/**, **etc/**, **var/**: librerias y datos base de Termux.
- **share/spatha/**: guion de instalacion del shim dentro del container:
  - `scutum-guard.sh` — instalador idempotente (manifest-driven)
  - `manifest.txt` — declaracion de archivos a instalar y symlinks
  - `gl-run` — wrapper de lanzamiento (detecta GLX vs EGL/GLES)
  - `libEGL.so`, `libGLESv2.so` — shim glibc de Scutum
  - `libspatha-icd.so`, `spatha_icd.json` — ICD stub de Spatha
  - `libGL.so.1` — gl4es (traductor GL -> GLES)
- **share/sesar/sesar-shell**: binario del entorno de escritorio Sesar.
- **share/ubuntu-rootfs.tar.gz**: rootfs base de Ubuntu 24.04 LTS.
- **share/LICENSES/**: licencias de todos los componentes.
- **SYMLINKS.txt**: symlinks Unix que deben crearse tras la extraccion.

## Que modifica del Termux base

- `bin/session-bootstrap.sh`, `bin/session-start.sh`, `bin/ubuntu-init.sh` — reescritos para orquestar proot-distro + sesion Sesar + daemons Scutum/Spatha.
- `bin/proot`, `bin/proot-distro` — sin cambios (base Termux).
- Se agregan binarios y scripts de integracion (ver arriba).
- **No** se modifica la base de Termux salvo los scripts de orquestacion. El resto es Termux stock.

## Componentes propios

Todo el stack Gladiator es original:

- **Scutum** — https://github.com/LexusYTG/Scutum (MIT)
- **Spatha** — https://github.com/LexusYTG/Spatha (MIT)
- **Sesar** — https://github.com/LexusYTG/Sesar (MIT)
- **Gladiator** (APK + scripts) — https://github.com/LexusYTG/gladiator (MIT)

## Licencias

Los binarios base de Termux vienen con sus propias licencias en `share/LICENSES/`. Los componentes propios (Scutum, Spatha, Sesar, scripts de Gladiator) son MIT. GL4ES es MIT (Sebastien Chevalier). Ver `share/LICENSES/ATTRIBUTION.txt` para el detalle completo.

## Uso

Este bootstrap **no se usa suelto**. Lo consume el APK de Gladiator: `BootstrapInstaller.java` extrae el zip al sandbox del paquete (`/data/data/com.glads1/files/usr/`) en el primer arranque.

Para ver el proyecto completo: https://github.com/LexusYTG/gladiator
