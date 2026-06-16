# Public-Resource Build Feasibility Memo

Date: 2026-06-16
Workspace: `/Users/heima/proj/frida/rwProcMem33-fork`
Goal: Build `rwProcMem33` with public resources only, under full GitHub Actions control, without relying on local compilation.

## Search And Tool Validation

- Internet access is working.
- `gh` is authenticated and usable.
- Repository control is usable through `gh workflow run`, `gh run watch`, `gh run view`, and `gh run download`.

## Verified Local Environment

- `gh auth status` had already verified login as `chaseu0` with `repo` and `workflow` scopes.
- `chaseu0/rwProcMem33` Actions are enabled and writable from this machine.
- Local disk space is critically low on 2026-06-16:
  - `/System/Volumes/Data` available: about `328MiB`
  - This is enough for logs and small artifacts, but large workflow artifact downloads can fail locally even when the remote build succeeds.
- Existing successful public-resource builds already proved the control plane:
  - Managed NDK workflow succeeded for demo ELF targets.
  - Pixel 5 redfin module workflow run `27599000152` completed successfully on GitHub Actions.

## Key Findings

1. The GitHub Actions orchestration path is feasible and already works end to end.
2. The first redfin workflow run did build the kernel and stock vendor modules remotely.
3. The run did not produce `rwProcMem_module.ko` in the artifact set because the workflow appended `EXT_MODULES` to `build.config.redbull`, while `build_redbull-gki.sh` uses `BUILD_CONFIG="private/msm-google/build.config.redbull.vintf"`.
4. Large artifact downloads should be minimized because local free disk is currently too small for broad `.ko` bundles.

## References Checked

1. Android official: Pixel kernel build guide
   - <https://source.android.com/docs/setup/build/building-pixel-kernels>
   - Confirms the supported Pixel kernel build flow and branch/device pairing model.

2. Android official: Android kernel build how-to
   - <https://source.android.com/docs/core/architecture/kernel/howto-kernel-0>
   - Confirms kernel build environment expectations and official build workflow patterns.

3. Android kernel source: `build_redbull-gki.sh`
   - <https://android.googlesource.com/kernel/msm/+/refs/heads/android-msm-redbull-4.19-android12/build_redbull-gki.sh>
   - Confirms the script uses `BUILD_CONFIG="private/msm-google/build.config.redbull.vintf"`.

4. Android kernel source: `build_redbull.sh`
   - <https://android.googlesource.com/kernel/msm/+/refs/heads/android-msm-redbull-4.19-android12/build_redbull.sh>
   - Confirms there is also a redbull no-CFI build entrypoint, relevant to the Kanxue runtime advice.

5. GitHub Docs: manually running workflows
   - <https://docs.github.com/en/actions/how-tos/manage-workflow-runs/manually-run-a-workflow>
   - Confirms `workflow_dispatch` as the supported remote trigger path.

6. GitHub Docs: downloading workflow artifacts
   - <https://docs.github.com/en/actions/how-tos/manage-workflow-runs/download-workflow-artifacts>
   - Confirms the supported artifact retrieval path used by the managed scripts.

7. Kanxue article provided by the user
   - <https://bbs.kanxue.com/thread-278647.htm>
   - Useful as a practical field reference for redbull/Android 12 era kernel integration and the no-CFI concern.

8. Android kernel build history around `EXT_MODULES`
   - <https://android.googlesource.com/kernel/build/+/d6c72ca300928d093b7ff027b888e72e9cecaa00%5E%21/>
   - Useful background for how Android kernel build scripts treat `EXT_MODULES` in different build modes.

## Recommended Execution Chain

1. Trigger GitHub Actions remotely with `gh`.
2. Patch the workflow only after validating which `BUILD_CONFIG` is actually consumed by the selected build entry script.
3. Upload only the target `.ko` files and essential metadata, not the entire stock module universe.
4. Make the workflow fail if the requested target module is absent, instead of accepting a green run that only built stock components.

## Avoid These Errors

- Do not assume a green kernel workflow means the requested custom module was produced.
- Do not append `EXT_MODULES` to a config file unless the active build script is confirmed to use it.
- Do not rely on large local artifact downloads while the local disk remains nearly full.
- Do not switch to local compilation, because the user explicitly wants public-resource-only builds.
