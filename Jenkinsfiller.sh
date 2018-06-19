#!/usr/bin/env bash
# https://disconnected.systems/blog/another-bash-strict-mode/
set -euo pipefail
trap 's=$?; echo "$0: Error on line "$LINENO": $BASH_COMMAND"; exit $s' ERR

if [ ! -f "Jenkinsfile" ]; then
  echo >&2 "No template Jenkinsfile"
  exit 1
fi

tmp="./repos"
rm -rf "$tmp"; mkdir -p "$tmp"
cd "$tmp"
for repo in "$@"; do
  dir="$(grep -Po '[\w-.]+/?$' <<< "$repo")"
  dir="${dir%/}" # Strip trailing slash
  git clone "$repo" "$dir"

  if [ -f "$dir/Jenkinsfile" ]; then
    echo >&2 "SKIPPING: $dir/Jenkinsfile exists"; continue
  fi
  if [ -f "$dir/.travis.yml" ]; then
    echo >&2 "SKIPPING: $dir/.travis.yml exists"; continue
  fi

  pushd "$dir"
  git checkout -b add-jenkinsfile
  cp ../../Jenkinsfile .
  git add Jenkinsfile
  git commit -m "Add Jenkinsfile"
  hub fork --no-remote
  git remote add gh "git@github.com:olivergondza/$dir.git"
  git push gh add-jenkinsfile
  hub pull-request -m "Add Jenkinsfile"
  popd
done