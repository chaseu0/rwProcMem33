# Pixel5 Redfin Managed Modules

This workflow builds the two kernel modules in this repository against the Pixel 5 (`redfin`) Android 12 redbull kernel branch on GitHub Actions.

## Workflow

Workflow file:

```text
.github/workflows/pixel5-redfin-modules.yml
```

Supported module targets:

- `all`
- `rwProcMem`
- `hwBreakpoint`

Default kernel branch:

```text
android-msm-redbull-4.19-android12
```

## Control script

```bash
tools/gha_redbull_module_manager.sh build all master
tools/gha_redbull_module_manager.sh build rwProcMem master
tools/gha_redbull_module_manager.sh build hwBreakpoint master
```

## What the artifacts contain

The workflow uploads:

- compiled `.ko` files
- `modinfo` output for each module
- `file` output for each module
- the kernel `boot.img`, `vendor_boot.img`, `dtbo.img`, `Image.lz4`, `vmlinux`, and `System.map` when available
- file manifests

## Important limitation

Official Android docs note that Pixel 5 and earlier devices require module updates together with platform-side vendor artifacts. That means:

- this workflow is enough to compile matching `.ko` files and supporting kernel artifacts
- it is not yet a complete flashable integration pipeline for Pixel 5
- for a rooted device with matching kernel config and version, the built `.ko` files are suitable for `insmod`-style testing
- for a persistent bootable integration, the next stage is packaging the modules into the correct vendor/boot artifact flow
