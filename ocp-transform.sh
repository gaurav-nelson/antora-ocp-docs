#!/usr/local/bin/bash

set -e

usage() { echo "Usage: $0 [-d <output directory>] [-b <BRANCH>]" 1>&2; exit 1; }

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

while getopts ":d:b:" FLAG;
do
    case "${FLAG}" in
        d)
          OUTPUT_DIR=${OPTARG}
          ;;
        b)
          BRANCH=${OPTARG}
          ;;
        *)
          usage
          ;;
    esac
done

if [[ -z "$OUTPUT_DIR" || -z "$BRANCH" ]]; then
  usage
fi

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

FULLPATH_PATCHED_DOCS="$(realpath "$OUTPUT_DIR")"

highlight "Branch: $BRANCH";

mkdir -p "$OUTPUT_DIR" || die "Output directory $OUTPUT_DIR could not be created"
highlight "Patch docs path: $FULLPATH_PATCHED_DOCS"

info "Creating temp directory..."
TEMP_DOCS_DIR="$(mktemp -d)"

highlight "Temp docs directory: $TEMP_DOCS_DIR"
info "switching to patched docs dir..."
cd "$TEMP_DOCS_DIR"

info "Cloning openshift-docs repo..."
git clone --depth 1 --branch "$BRANCH" git@github.com:openshift/openshift-docs.git

info "Switching to openshift-docs repo..."
cd openshift-docs

info "Removing symlinks..."
find . -type l -delete

# info "Removing all files except adoc and yml..."
# find . -type f -not -name '*.adoc' -not -name '*.yml' -delete

info "Removing empty directories..."
find . -type d -empty -delete

cd "$FULLPATH_PATCHED_DOCS" || die "Could not change directory"

find "$TEMP_DOCS_DIR/openshift-docs" -type d -mindepth 1 -maxdepth 1 | while IFS='' read -r dir || [[ -n "$dir" ]]; do
  name="$(basename "$dir")"
  if [[ "$name" =~ ^[._] ]]; then
    if [[ "$name" =~ '_attributes' ]]; then
      TARGET_DIR=./docs/modules/ROOT/partials/
      [[ -n "$TARGET_DIR" ]] || continue
      info "Copying $dir/* to $TARGET_DIR ..."
      mkdir -p "$TARGET_DIR"
      cp -rf "$dir"/* "$TARGET_DIR"
    fi
    continue
  fi
  TARGET_DIR=""
  case "$name" in
  scripts)
    ;;
  modules)
    TARGET_DIR=./docs/modules/ROOT/partials/
    ;;
  snippets)
    TARGET_DIR=./docs/modules/ROOT/partials/
    ;;
  images)
    TARGET_DIR=./docs/modules/ROOT/images/
    ;;
  files)
    TARGET_DIR=./docs/modules/ROOT/_files/
    ;;
  *)
    TARGET_DIR="./docs/modules/ROOT/pages/${name}/"
    ;;
  esac
  [[ -n "$TARGET_DIR" ]] || continue
  info "Copying $dir/* to $TARGET_DIR ..."
  mkdir -p "$TARGET_DIR"
  cp -rf "$dir"/* "$TARGET_DIR"
done

python3 -m venv "${SCRIPT_DIR}/.venv"
. "${SCRIPT_DIR}/.venv/bin/activate"
pip3 install --upgrade pip setuptools
pip3 install -r "${SCRIPT_DIR}/requirements.txt"

highlight "Fixing xrefs..."

find . -name '*.adoc' -print0 | xargs -0 "${SCRIPT_DIR}/patch-files.py"

highlight "Generating table of contents..."

"${SCRIPT_DIR}/generate-nav.py" <"$TEMP_DOCS_DIR/openshift-docs/_topic_maps/_topic_map.yml"

highlight "Setting product title and version..."

search_dir=$TEMP_DOCS_DIR/openshift-docs/_attributes
for entry in "$search_dir"/*
do
  filename=$(basename "$entry")
  echo ":product-title: OpenShift Container Platform" >> $FULLPATH_PATCHED_DOCS/docs/modules/ROOT/partials/$filename
  echo ":product-version: ${BRANCH: -4}" >> $FULLPATH_PATCHED_DOCS/docs/modules/ROOT/partials/$filename
done

highlight "Generating playbook..."
playbook_yml="${FULLPATH_PATCHED_DOCS}/playbook.yml"
cat >"$playbook_yml" <<EOF
site:
  title: OCP documentation
  start_page: container-platform::index.adoc
content:
  sources:
  - url: .
    branches: main
    start_path: docs
ui:
  bundle:
    url: https://gitlab.com/antora/antora-ui-default/-/jobs/artifacts/HEAD/raw/build/ui-bundle.zip?job=bundle-stable
EOF

info "Deleting temp directory..."
rm -rf "$TEMP_DOCS_DIR"

highlight "✓ COMPLETE"
