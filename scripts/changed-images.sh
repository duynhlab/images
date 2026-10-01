#!/usr/bin/env bash
# Print the images a change touches, as a JSON array for a workflow matrix.
# A change to the shared build path (Makefile, scripts/, the workflows) touches
# every image, because it can change any digest.
# Usage: scripts/changed-images.sh <base-ref>
set -euo pipefail

base=${1:?usage: changed-images.sh <base-ref>}
files=$(git diff --name-only "${base}...HEAD")

all() { find images -mindepth 1 -maxdepth 1 -type d -printf '%f\n' | sort; }

if grep -qE '^(Makefile|scripts/|\.github/workflows/)' <<<"${files}"; then
  names=$(all)
else
  names=$(grep -oE '^images/[^/]+/' <<<"${files}" | cut -d/ -f2 | sort -u || true)
fi

# Keep only images that still exist (a deleted image has nothing to build).
printf '%s\n' ${names} | while read -r n; do
  [[ -n "${n}" && -f "images/${n}/image.yaml" ]] && echo "${n}"
done | jq -R . | jq -sc .
