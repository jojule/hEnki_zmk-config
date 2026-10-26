# hEnki ZMK configuration

Firmware for the hEnki split keyboard with a nice!nano v2 controller on each
half. The keymap has typing, navigation, symbols, and system layers. There is
no display or lookup layer.

Mouse behavior matches the sibling Corne configuration: cursor speed 6000
with a 500 ms acceleration period, and constant scroll speed 40. The ZMK
revision is pinned in `config/west.yml`.

## Compile locally

Prerequisites:

- Docker installed and running. The build uses an official, pinned ARM64 ZMK
  image with Zephyr SDK 0.16.9; this setup is verified on Apple Silicon.
- Internet access to download the image and firmware dependencies.
- Several GB of free disk space for the toolchain, sources, and build cache.

From this repository's root, run:

```sh
bash scripts/build-local.sh
```

The script downloads ZMK and its dependencies into `.local-build/` and builds
both targets from `build.yaml` with a clean build directory each time:

| Controller | Board | Shield |
| --- | --- | --- |
| Left / central | `nice_nano@2.0.0//zmk` | `henki_left` |
| Right / peripheral | `nice_nano@2.0.0//zmk` | `henki_right` |

All build tools run inside Docker; host installations of Python, West, and
the Zephyr SDK are unnecessary. The script uses this repository's shield
definitions and keymap and does not require the Corne repository. Later runs
reuse downloaded dependencies.

After both builds succeed, the script writes:

- `firmware/henki_left.uf2` and `firmware/henki_right.uf2`
- `firmware/SHA256SUMS` with firmware checksums
- `firmware/zmk-revision.txt` and `firmware/west-manifest.yml` with the exact
  dependency revisions
- `firmware/source-SHA256SUMS` with configuration and build-script checksums

The full build log is `.local-build/build.log`. If compilation fails, the
script exits with an error and leaves any previous firmware outputs in place;
those files are still from the previous successful build. Both `.local-build/`
and `firmware/` are ignored by Git.

To verify firmware checksums on macOS:

```sh
(cd firmware && shasum -a 256 -c SHA256SUMS)
```

Flash each UF2 to its corresponding half. A successful build verifies that
the firmware compiles; mouse feel and physical key behavior still require a
hardware check.

## Configuration files

- `config/henki.keymap`: key bindings, macros, combos, and mouse settings.
- `boards/shields/henki/`: matrix wiring and per-half configuration.
- `config/west.yml`: pinned ZMK version and dependency manifest.
- `build.yaml`: board and shield targets used by the local build and the
  standard `.github/workflows/build.yml` workflow.

## GitHub Actions

`.github/workflows/build.yml` runs the official ZMK build workflow on pushes,
pull requests, and manual runs. It uses `build.yaml` to build both halves and
uploads the resulting UF2 files in the `firmware` artifact. Download that
artifact from the completed run's summary in the repository's Actions tab.

This is the repository's only CI build workflow. Firmware is distributed as
an Actions artifact; the workflow does not create GitHub Releases.
