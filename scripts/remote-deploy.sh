#!/usr/bin/env bash
set -euo pipefail

deploy_path="${1:?deploy path is required}"
release_id="${2:?release id is required}"
bundle="${3:?bundle path is required}"
release_dir="$deploy_path/releases/$release_id"
current_link="$deploy_path/current"
next_link="$deploy_path/current.next"

mkdir -p "$deploy_path/releases" "$release_dir"
tar -xzf "$bundle" -C "$release_dir"

previous_target=""
if [[ -L "$current_link" ]]; then
  previous_target="$(readlink "$current_link")"
fi

ln -sfn "$release_dir" "$next_link"
mv -Tf "$next_link" "$current_link"

if ! curl --fail --silent --show-error --max-time 10 http://127.0.0.1/health >/dev/null; then
  if [[ -n "$previous_target" ]]; then
    ln -sfn "$previous_target" "$next_link"
    mv -Tf "$next_link" "$current_link"
  else
    rm -f "$current_link"
  fi
  rm -rf "$release_dir"
  printf '%s\n' 'Health check failed; previous release restored.' >&2
  exit 1
fi

# Keep the current release plus the four most recent older releases.
mapfile -t old_releases < <(
  find "$deploy_path/releases" -mindepth 1 -maxdepth 1 -type d -printf '%T@ %p\n' |
    sort -nr | tail -n +6 | cut -d' ' -f2-
)
if ((${#old_releases[@]})); then
  rm -rf -- "${old_releases[@]}"
fi

rm -f "$bundle"
printf 'Deployed release %s successfully.\n' "$release_id"
