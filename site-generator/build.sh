#!/usr/bin/env bash

# Build the site using antora.
#
# Prerequisites:
#  0. `make setup` has been run to install Yarn dependencies
#  1. The current working directory is the directory containing this script.
#  2. BUNDLE_PATH is an absolute path pointing to the Antora UI bundle.
#  3. CONTENT_REPO is a Git repository containing the (patched) docs contents in its `main` branch.
#  4. OUTPUT_PATH is an absolute path pointing to the build output directory (the actual output will be
#     stored in build/site/). The directory should be empty. If it does not exist, it will be created
#     automatically.

set -e

die() {
	echo >&2 "$@"
	exit 1
}

NODE_PATH="$(pwd)/node_modules"

[[ -f package.json && -f yarn.lock && -d "$NODE_PATH" ]] || die "This must be run from within the project directory"

[[ -n "$BUNDLE_PATH" ]] || die "No bundle path specified"
[[ -n "$CONTENT_REPO" ]] || die "No content repo specified"
[[ -n "$OUTPUT_PATH" ]] || die "No output path specified"

mkdir -p "$OUTPUT_PATH"
playbook_yml="${OUTPUT_PATH}/playbook.yml"
cat >"$playbook_yml" <<EOF
site:
  title: RHACS documentation
  start_page: rhacs::index.adoc
content:
  sources:
  - url: $CONTENT_REPO
    branches: main
    start_path: docs
ui:
  bundle:
    url: $BUNDLE_PATH
EOF

export PATH="$(yarn bin):$PATH"

echo "Playbook is at $playbook_yml"
DOCSEARCH_ENABLED=true DOCSEARCH_ENGINE=lunr NODE_PATH="$NODE_PATH" antora --generator antora-site-generator-lunr "$playbook_yml"

echo "Checking for unresolved links ..."
if grep -r -E 'class="[^"]*\bunresolved\b' "${OUTPUT_PATH}/build/site/" >&2; then
  echo >&2 "Unresolved links found!"
  exit 1
fi
echo "No unresolved links found"
