#!/usr/bin/env bash

set -euo pipefail

WORKFLOW_FILE="${WORKFLOW_FILE:-ndk-demo-build.yml}"
DEFAULT_TARGET="${DEFAULT_TARGET:-all}"
DEFAULT_REF="${DEFAULT_REF:-master}"
DEFAULT_NDK_PACKAGE="${DEFAULT_NDK_PACKAGE:-26.3.11579264}"

usage() {
  cat <<'EOF'
Usage:
  tools/gha_ndk_manager.sh build [target] [ref] [ndk_package] [download_dir]
  tools/gha_ndk_manager.sh watch <run_id>
  tools/gha_ndk_manager.sh logs <run_id>
  tools/gha_ndk_manager.sh download <run_id> [download_dir]
  tools/gha_ndk_manager.sh rerun-failed <run_id>
  tools/gha_ndk_manager.sh latest

Environment:
  GH_TOKEN       GitHub token used by gh CLI
  GITHUB_REPO    Optional override like owner/repo
  WORKFLOW_FILE  Optional workflow file name, default: ndk-demo-build.yml
EOF
}

require_gh_token() {
  if [ -n "${GH_TOKEN:-}" ]; then
    return
  fi

  if gh auth status >/dev/null 2>&1; then
    GH_TOKEN="$(gh auth token)"
    export GH_TOKEN
    return
  fi

  echo "GH_TOKEN is required, or gh must already be logged in." >&2
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

latest_run_id() {
  local repo="$1"

  gh run list \
    --repo "${repo}" \
    --workflow "${WORKFLOW_FILE}" \
    --limit 1 \
    --json databaseId \
    --jq '.[0].databaseId'
}

dispatch_build() {
  local repo="$1"
  local target="${2:-$DEFAULT_TARGET}"
  local ref="${3:-$DEFAULT_REF}"
  local ndk_package="${4:-$DEFAULT_NDK_PACKAGE}"
  local start_epoch
  local run_id=""

  start_epoch="$(date +%s)"

  gh workflow run "${WORKFLOW_FILE}" \
    --repo "${repo}" \
    --ref "${ref}" \
    -f target="${target}" \
    -f ref="${ref}" \
    -f ndk_package="${ndk_package}"

  for _ in $(seq 1 30); do
    sleep 3
    run_id="$(
      gh run list \
        --repo "${repo}" \
        --workflow "${WORKFLOW_FILE}" \
        --branch "${ref}" \
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

watch_run() {
  local repo="$1"
  local run_id="$2"

  gh run watch "${run_id}" --repo "${repo}" --exit-status
}

download_run() {
  local repo="$1"
  local run_id="$2"
  local download_dir="${3:-artifacts/run-${run_id}}"

  mkdir -p "${download_dir}"
  gh run download "${run_id}" --repo "${repo}" --dir "${download_dir}"
  echo "${download_dir}"
}

show_logs() {
  local repo="$1"
  local run_id="$2"

  gh run view "${run_id}" --repo "${repo}" --log-failed
}

rerun_failed() {
  local repo="$1"
  local run_id="$2"

  gh run rerun "${run_id}" --repo "${repo}" --failed
}

main() {
  local cmd="${1:-}"
  local repo

  if [ -z "${cmd}" ]; then
    usage >&2
    exit 2
  fi

  require_gh_token
  repo="$(repo_slug)"

  case "${cmd}" in
    build)
      local target="${2:-$DEFAULT_TARGET}"
      local ref="${3:-$DEFAULT_REF}"
      local ndk_package="${4:-$DEFAULT_NDK_PACKAGE}"
      local download_dir="${5:-artifacts/latest}"
      local run_id
      run_id="$(dispatch_build "${repo}" "${target}" "${ref}" "${ndk_package}")"
      echo "run_id=${run_id}"
      if watch_run "${repo}" "${run_id}"; then
        download_run "${repo}" "${run_id}" "${download_dir}"
      else
        show_logs "${repo}" "${run_id}" || true
        exit 1
      fi
      ;;
    watch)
      watch_run "${repo}" "${2:?run_id is required}"
      ;;
    logs)
      show_logs "${repo}" "${2:?run_id is required}"
      ;;
    download)
      download_run "${repo}" "${2:?run_id is required}" "${3:-artifacts/run-${2}}"
      ;;
    rerun-failed)
      rerun_failed "${repo}" "${2:?run_id is required}"
      ;;
    latest)
      latest_run_id "${repo}"
      ;;
    *)
      usage >&2
      exit 2
      ;;
  esac
}

main "$@"
