#!/usr/bin/env bash

set -euo pipefail

WORKFLOW_FILE="pixel5-redfin-modules.yml"
DEFAULT_TARGET="${DEFAULT_TARGET:-all}"
DEFAULT_REF="${DEFAULT_REF:-master}"
DEFAULT_BRANCH="${DEFAULT_BRANCH:-android-msm-redbull-4.19-android12}"

require_auth() {
  if gh auth status >/dev/null 2>&1; then
    return
  fi
  echo "gh must already be logged in." >&2
  exit 2
}

repo_slug() {
  if [ -n "${GITHUB_REPO:-}" ]; then
    echo "${GITHUB_REPO}"
    return
  fi

  git remote get-url origin \
    | sed -E 's#(git@github.com:|https://github.com/)##; s#\.git$##'
}

usage() {
  cat <<'EOF'
Usage:
  tools/gha_redbull_module_manager.sh build [module_target] [module_ref] [android_branch] [download_dir]
  tools/gha_redbull_module_manager.sh watch <run_id>
  tools/gha_redbull_module_manager.sh logs <run_id>
  tools/gha_redbull_module_manager.sh download <run_id> [download_dir]
  tools/gha_redbull_module_manager.sh latest
EOF
}

dispatch_build() {
  local repo="$1"
  local module_target="${2:-$DEFAULT_TARGET}"
  local module_ref="${3:-$DEFAULT_REF}"
  local android_branch="${4:-$DEFAULT_BRANCH}"
  local start_epoch run_id=""

  start_epoch="$(date +%s)"

  gh workflow run "${WORKFLOW_FILE}" \
    --repo "${repo}" \
    --ref "${module_ref}" \
    -f module_target="${module_target}" \
    -f module_ref="${module_ref}" \
    -f android_branch="${android_branch}" \
    >/dev/null

  for _ in $(seq 1 30); do
    sleep 3
    run_id="$(
      gh run list \
        --repo "${repo}" \
        --workflow "${WORKFLOW_FILE}" \
        --branch "${module_ref}" \
        --event workflow_dispatch \
        --limit 10 \
        --json databaseId,createdAt \
        --jq ".[] | select((.createdAt | fromdateiso8601) >= ${start_epoch}) | .databaseId" \
        | head -n 1
    )"
    if [ -n "${run_id}" ]; then
      echo "${run_id}"
      return
    fi
  done

  echo "Unable to resolve the new workflow run id." >&2
  exit 3
}

main() {
  local cmd="${1:-}"
  local repo

  if [ -z "${cmd}" ]; then
    usage >&2
    exit 2
  fi

  require_auth
  repo="$(repo_slug)"

  case "${cmd}" in
    build)
      local module_target="${2:-$DEFAULT_TARGET}"
      local module_ref="${3:-$DEFAULT_REF}"
      local android_branch="${4:-$DEFAULT_BRANCH}"
      local download_dir="${5:-artifacts/redbull-modules-latest}"
      local run_id
      run_id="$(dispatch_build "${repo}" "${module_target}" "${module_ref}" "${android_branch}")"
      echo "run_id=${run_id}"
      if gh run watch "${run_id}" --repo "${repo}" --exit-status; then
        mkdir -p "${download_dir}"
        gh run download "${run_id}" --repo "${repo}" --dir "${download_dir}"
        echo "${download_dir}"
      else
        gh run view "${run_id}" --repo "${repo}" --log-failed || true
        exit 1
      fi
      ;;
    watch)
      gh run watch "${2:?run_id is required}" --repo "${repo}" --exit-status
      ;;
    logs)
      gh run view "${2:?run_id is required}" --repo "${repo}" --log-failed
      ;;
    download)
      mkdir -p "${3:-artifacts/run-${2}}"
      gh run download "${2:?run_id is required}" --repo "${repo}" --dir "${3:-artifacts/run-${2}}"
      ;;
    latest)
      gh run list --repo "${repo}" --workflow "${WORKFLOW_FILE}" --limit 1 --json databaseId --jq '.[0].databaseId'
      ;;
    *)
      usage >&2
      exit 2
      ;;
  esac
}

main "$@"
