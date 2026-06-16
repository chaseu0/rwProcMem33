# GitHub Actions Managed Build

This repository now includes a GitHub Actions path for building the Android NDK demo executables without using the local machine.

## What it builds

The `ndk-demo-build.yml` workflow builds these NDK targets:

- `testKo`
- `testTarget`
- `testMemSearch`
- `testDumpMem`
- `testCEServer`
- `testHwBp`
- `testHwBpTarget`
- `testHwBpServer`

Each target is built from its `jni/Android.mk` and `Application.mk` using `ndk-build`.

## Required token

Use a GitHub token through the `GH_TOKEN` environment variable.

- Classic PAT:
  - `repo`
- Fine-grained PAT:
  - repository access to this repo
  - `Actions: write`
  - `Contents: write`

`Actions: write` is required for workflow dispatch and rerun operations. `Contents: write` is required if I also need to push workflow or code fixes back to the repository.

## Important GitHub behavior

The workflow file must exist on the default branch for `workflow_dispatch` to work. The workflow can build a different ref through the `ref` input, but the workflow definition itself must already be on the default branch.

## Managed control entrypoint

The control script is:

```bash
tools/gha_ndk_manager.sh
```

Common commands:

```bash
export GH_TOKEN=YOUR_TOKEN

tools/gha_ndk_manager.sh build all master
tools/gha_ndk_manager.sh build testHwBpServer master
tools/gha_ndk_manager.sh latest
tools/gha_ndk_manager.sh logs RUN_ID
tools/gha_ndk_manager.sh rerun-failed RUN_ID
tools/gha_ndk_manager.sh download RUN_ID artifacts/run-RUN_ID
```

## Artifact layout

Each workflow run uploads:

- `artifacts/logs/<target>/ndk-build.log`
- `artifacts/<target>/libs/...`
- `artifacts/<target>/obj/...`
- `artifacts/<target>/files.txt`
- `artifacts/manifest.txt`

## Recommended operating model

1. Commit this workflow to the default branch.
2. Export `GH_TOKEN`.
3. Let me trigger builds with `tools/gha_ndk_manager.sh`.
4. If a build fails, I inspect `gh run view --log-failed`, patch the repo, push, and rerun.
