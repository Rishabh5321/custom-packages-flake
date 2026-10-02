#!/usr/bin/env bash
#
# Regenerates the package table in README.md from the packages exposed by the
# flake, using each derivation's meta.description.
#
# Usage: scripts/generate-readme-table.sh [--check]
#
#   --check  Do not write anything. Exit non-zero if README.md is out of date.
#            Intended for CI.

set -euo pipefail

START_MARKER="<!-- packages:start -->"
END_MARKER="<!-- packages:end -->"

script_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
repo_root=$(cd "${script_dir}/.." && pwd)
readme="${repo_root}/README.md"

check_only=false
if [[ "${1:-}" == "--check" ]]; then
  check_only=true
elif [[ $# -gt 0 ]]; then
  echo "usage: $(basename "$0") [--check]" >&2
  exit 2
fi

if ! grep -qF "${START_MARKER}" "${readme}"; then
  echo "error: ${START_MARKER} not found in ${readme}" >&2
  exit 1
fi

# Descriptions come from the evaluated flake, so the table can never drift from
# the actual package set.
descriptions=$(
  cd "${repo_root}"
  nix eval --json .#packages.x86_64-linux \
    --apply 'ps: builtins.mapAttrs (_: p: if p ? meta && p.meta ? description then p.meta.description else null) ps' \
    2>/dev/null
)

if [[ -z "${descriptions}" || "${descriptions}" == "null" ]]; then
  echo "error: could not evaluate package descriptions from the flake" >&2
  exit 1
fi

table=$(
  jq -r '
    to_entries
    | sort_by(.key)
    | .[]
    | "| `\(.key)` | \(.value // "") |"
  ' <<<"${descriptions}"
)

{
  printf '%s\n' "${START_MARKER}"
  printf '\n'
  printf '%s\n' '| Package | Description |'
  printf '%s\n' '|---------|-------------|'
  printf '%s\n' "${table}"
  printf '\n'
  printf '%s\n' "${END_MARKER}"
} >"${repo_root}/.readme-table.tmp"

updated=$(awk -v start="${START_MARKER}" -v end="${END_MARKER}" -v repl="${repo_root}/.readme-table.tmp" '
  $0 == start {
    while ((getline line < repl) > 0) print line
    close(repl)
    skipping = 1
    next
  }
  $0 == end { skipping = 0; next }
  !skipping { print }
' "${readme}")

if [[ "${check_only}" == true ]]; then
  rm -f "${repo_root}/.readme-table.tmp"
  if [[ "${updated}" == "$(cat "${readme}")" ]]; then
    echo "README.md package table is up to date."
  else
    echo "README.md package table is out of date. Run scripts/generate-readme-table.sh" >&2
    exit 1
  fi
else
  printf '%s\n' "${updated}" >"${readme}"
  rm -f "${repo_root}/.readme-table.tmp"
  echo "README.md package table updated."
fi
