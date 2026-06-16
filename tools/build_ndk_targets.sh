#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ARTIFACTS_DIR="${ARTIFACTS_DIR:-${ROOT_DIR}/artifacts}"
LOGS_DIR="${ARTIFACTS_DIR}/logs"
JOBS="${JOBS:-4}"
NDK_BUILD_BIN="${NDK_BUILD_BIN:-ndk-build}"

usage() {
  cat <<'EOF'
Usage: tools/build_ndk_targets.sh <target|all>

Targets:
  all
  testKo
  testTarget
  testMemSearch
  testDumpMem
  testCEServer
  testHwBp
  testHwBpTarget
  testHwBpServer
EOF
}

resolve_target_dirs() {
  case "${1}" in
    all)
      cat <<'EOF'
rwProcMem33Module/testKo/jni
rwProcMem33Module/testTarget/jni
rwProcMem33Module/testMemSearch/jni
rwProcMem33Module/testDumpMem/jni
rwProcMem33Module/testCEServer/jni
hwBreakpointProcModule/testHwBp/jni
hwBreakpointProcModule/testHwBpTarget/jni
hwBreakpointProcModule/testHwBpServer/jni
EOF
      ;;
    testKo) echo "rwProcMem33Module/testKo/jni" ;;
    testTarget) echo "rwProcMem33Module/testTarget/jni" ;;
    testMemSearch) echo "rwProcMem33Module/testMemSearch/jni" ;;
    testDumpMem) echo "rwProcMem33Module/testDumpMem/jni" ;;
    testCEServer) echo "rwProcMem33Module/testCEServer/jni" ;;
    testHwBp) echo "hwBreakpointProcModule/testHwBp/jni" ;;
    testHwBpTarget) echo "hwBreakpointProcModule/testHwBpTarget/jni" ;;
    testHwBpServer) echo "hwBreakpointProcModule/testHwBpServer/jni" ;;
    *)
      echo "Unknown target: ${1}" >&2
      usage >&2
      exit 2
      ;;
  esac
}

build_one() {
  local rel_jni_dir="$1"
  local jni_dir="${ROOT_DIR}/${rel_jni_dir}"
  local project_dir
  local target_name
  local target_artifacts_dir
  local status_file

  project_dir="$(cd "${jni_dir}/.." && pwd)"
  target_name="$(basename "${project_dir}")"
  target_artifacts_dir="${ARTIFACTS_DIR}/${target_name}"
  status_file="${target_artifacts_dir}/status.txt"

  mkdir -p "${target_artifacts_dir}" "${LOGS_DIR}/${target_name}"

  echo "target=${target_name}" | tee "${status_file}"
  echo "jni_dir=${rel_jni_dir}" | tee -a "${status_file}"
  echo "ndk_build_bin=${NDK_BUILD_BIN}" | tee -a "${status_file}"

  (
    cd "${jni_dir}"
    "${NDK_BUILD_BIN}" -j"${JOBS}" V=1 APP_SHORT_COMMANDS=true
  ) 2>&1 | tee "${LOGS_DIR}/${target_name}/ndk-build.log"

  if [ -d "${project_dir}/libs" ]; then
    mkdir -p "${target_artifacts_dir}/libs"
    cp -R "${project_dir}/libs/." "${target_artifacts_dir}/libs/"
  fi

  if [ -d "${project_dir}/obj" ]; then
    mkdir -p "${target_artifacts_dir}/obj"
    cp -R "${project_dir}/obj/." "${target_artifacts_dir}/obj/"
  fi

  find "${target_artifacts_dir}" -type f | sort > "${target_artifacts_dir}/files.txt"
}

main() {
  local selected_target="${1:-}"
  local resolved_targets

  if [ -z "${selected_target}" ]; then
    usage >&2
    exit 2
  fi

  resolved_targets="$(resolve_target_dirs "${selected_target}")"

  command -v "${NDK_BUILD_BIN}" >/dev/null 2>&1 || {
    echo "ndk-build binary not found: ${NDK_BUILD_BIN}" >&2
    exit 3
  }

  rm -rf "${ARTIFACTS_DIR}"
  mkdir -p "${ARTIFACTS_DIR}" "${LOGS_DIR}"

  while IFS= read -r rel_jni_dir; do
    [ -n "${rel_jni_dir}" ] || continue
    build_one "${rel_jni_dir}"
  done <<< "${resolved_targets}"

  find "${ARTIFACTS_DIR}" -maxdepth 3 -type f | sort > "${ARTIFACTS_DIR}/manifest.txt"
}

main "$@"
