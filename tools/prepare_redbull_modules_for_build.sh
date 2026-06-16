#!/usr/bin/env bash

set -euo pipefail

if [ "$#" -ne 2 ]; then
  echo "Usage: $0 <kernel_root> <all|rwProcMem|hwBreakpoint>" >&2
  exit 2
fi

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
KERNEL_ROOT="$1"
MODULE_TARGET="$2"
STAGE_ROOT="${KERNEL_ROOT}/rwProcMem33-ext"

copy_module() {
  local src_rel="$1"
  local dst_rel="$2"

  mkdir -p "${STAGE_ROOT}/${dst_rel}"
  rsync -a --delete "${REPO_ROOT}/${src_rel}/" "${STAGE_ROOT}/${dst_rel}/"
}

case "${MODULE_TARGET}" in
  all)
    copy_module "rwProcMem33Module/rwProcMem_module" "rwProcMem33Module/rwProcMem_module"
    copy_module "hwBreakpointProcModule/hwBreakpointProc_module" "hwBreakpointProcModule/hwBreakpointProc_module"
    ;;
  rwProcMem)
    copy_module "rwProcMem33Module/rwProcMem_module" "rwProcMem33Module/rwProcMem_module"
    ;;
  hwBreakpoint)
    copy_module "hwBreakpointProcModule/hwBreakpointProc_module" "hwBreakpointProcModule/hwBreakpointProc_module"
    ;;
  *)
    echo "Unknown module target: ${MODULE_TARGET}" >&2
    exit 2
    ;;
esac

find "${STAGE_ROOT}" -maxdepth 4 -type f | sort
