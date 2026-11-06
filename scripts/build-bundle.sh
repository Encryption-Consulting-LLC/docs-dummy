#!/usr/bin/env bash
set -euo pipefail

release_id="${1:?release id is required}"
repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
build_dir="$repo_root/build"
bundle="$build_dir/docs-dummy-${release_id}.tar.gz"

rm -rf "$build_dir"
mkdir -p "$build_dir"
tar -C "$repo_root/site" -czf "$bundle" .

printf '%s\n' "$bundle"
