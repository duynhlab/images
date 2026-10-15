# Repository guide

Repository facts for agents working in `duynhlab/images`.

This repository contains platform-built OCI images that are not application
services; each image is independently versioned and described in its own
directory.

## Layout

Each image is self-contained; its `image.yaml` is the contract for its name,
description, platforms, reproducibility and consumers.

```text
images/<image>/       image.yaml, Dockerfile, README.md, CHANGELOG.md, build files
Makefile              shared build, digest, load and lint targets
scripts/              changed-images.sh for the PR build matrix
.github/workflows/    PR checks, release flow and shared build workflow
```

## Build and PR workflow

- Add an image by adding a directory; do not add image-specific logic to the
  `Makefile` or workflows. See README § Add an image.
- Build only through `make`; `build`, `digest`, `load` and `lint` take
  `IMAGE=<image>`.
- BuildKit is pinned by digest and build time is stripped. A digest change
  without an input change is a bug, not noise.
- Pull requests lint every `image.yaml` and build each changed image twice;
  the resulting digests must match before setting `reproducible: true`.

## Release workflow

- Release from `main` with tag `<image>/vX.Y.Z`. `release.yml` builds and pushes
  the image, verifies the registry digest, signs and attests it, then creates
  the GitHub Release. Never push images by hand.
- The signer identity is a contract: consumers verify against
  `.github/workflows/release.yml@refs/tags/<image>/v…`. Do not rename or move
  that workflow or change the tag pattern.
- GHCR creates new packages as private. The owner must make each package public
  once in the UI; this cannot be undone.

## Repository conventions

- Pin Actions by full SHA and include the version in a comment.
- Use conventional commits without attribution trailers; keep subjects to 50
  characters and wrap bodies at 72. Work on a branch and open a PR; never push
  to `main`.
