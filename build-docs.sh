#!/usr/bin/env bash

# Scripts for building RHACS embedded documentation.
# Prerequisites:
#  0. `make prepare` has been run in this directory to create the bundle and install dependencies
#  1. `DOCS_INPUT` points to the RHACS docs directory.
#  2. `DOCS_OUTPUT` points to the directory where the output should be stored (index.html being stored
#     directly at the root). This directory should be empty. If it does not exist, it will be created
#     automatically.

set -e

info() {
  echo >&2 "$@"
}

die() {
  echo >&2 "$@"
  exit 1
}

[[ -n "$DOCS_INPUT" ]] || die "DOCS_INPUT not set"
[[ -n "$DOCS_OUTPUT" ]] || die "DOCS_OUTPUT not set"
mkdir -p "$DOCS_OUTPUT" || die "Output directory $DOCS_OUTPUT could not be created"

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

bundle_file="$SCRIPT_DIR/antora-bundle/build/ui-bundle.zip"

[[ -f "$bundle_file" ]] || die "${bundle_file} not found. Please run 'make prepare' in the directory containing this script."

info "Creating patched version of docs from ${DOCS_INPUT}"
patched_docs_dir="$(mktemp -d)"
DOCS_PATH="$DOCS_INPUT" PATCHED_DOCS_PATH="$patched_docs_dir" "${SCRIPT_DIR}/patch-docs/patch-docs.sh"

info "Building site"
output_tmp="$(mktemp -d)"

export BUNDLE_PATH="$bundle_file" CONTENT_REPO="$patched_docs_dir" OUTPUT_PATH="$output_tmp"
(
  cd "${SCRIPT_DIR}/site-generator" || exit 1
  ./build.sh
)

rm -rf "$patched_docs_dir"

cp -a "${output_tmp}/build/site"/* "${DOCS_OUTPUT}"

rm -rf "$output_tmp"
