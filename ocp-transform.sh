#!/usr/local/bin/bash

set -e

usage() { echo "Usage: $0 [-d <output directory>] [-b <branch>]" 1>&2; exit 1; }

info() {
  echo >&1 "$@"
}

highlight() {
  echo -e "\033[0;34m $@ \033[0m" >&1
}

die() {
  echo >&2 "$@"
  exit 1
}

while getopts ":d:b:" flag;
do
    case "${flag}" in
        d)
          output_dir=${OPTARG}
          ;;
        b)
          branch=${OPTARG}
          ;;
        *)
          usage
          ;;
    esac
done

if [[ -z "$output_dir" || -z "$branch" ]]; then
  usage
fi

fullpath_patched_docs="$(realpath "$output_dir")"

highlight "Branch: $branch";

mkdir -p "$output_dir" || die "Output directory $output_dir could not be created"
highlight "Patch docs path: $fullpath_patched_docs"

info "Creating temp directory..."
temp_docs_dir="$(mktemp -d)"

highlight "Temp docs directory: $temp_docs_dir"
info "switching to patched docs dir..."
cd "$temp_docs_dir"

info "Cloning openshift-docs repo..."
git clone --depth 1 --branch "$branch" git@github.com:openshift/openshift-docs.git

info "Switching to openshift-docs repo..."
cd openshift-docs

info "Removing symlinks..."
find . -type l -delete

# info "Removing all files except adoc and yml..."
# find . -type f -not -name '*.adoc' -not -name '*.yml' -delete

info "Removing empty directories..."
find . -type d -empty -delete

cd "$fullpath_patched_docs" || die "Could not change directory"

find "$temp_docs_dir/openshift-docs" -type d -mindepth 1 -maxdepth 1 | while IFS='' read -r dir || [[ -n "$dir" ]]; do
  name="$(basename "$dir")"
  if [[ "$name" =~ ^[._] ]]; then
    continue
  fi
  target_dir=""
  case "$name" in
  scripts)
    ;;
  modules)
    target_dir=./docs/modules/ROOT/partials/
    ;;
  images)
    target_dir=./docs/modules/ROOT/images/
    ;;
  files)
    target_dir=./docs/modules/ROOT/_files/
    ;;
  *)
    target_dir="./docs/modules/ROOT/pages/${name}/"
    ;;
  esac
  [[ -n "$target_dir" ]] || continue
  info "Copying $dir/* to $target_dir ..."
  mkdir -p "$target_dir"
  cp -rf "$dir"/* "$target_dir"
done

info "Deleting temp directory..."
rm -rf "$temp_docs_dir"

highlight "✓ COMPLETE"