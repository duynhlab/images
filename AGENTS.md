# Instructions for AI Agents

The following guidelines apply to all files in this repository.

## Repository Overview

This repository contains platform-built OCI images. Each image is independently versioned, documented, and released with its own contract.

## Images

All images live under `images/<image>/`. Each image directory is self-contained and should keep its own `image.yaml`, `Dockerfile`, `README.md`, `CHANGELOG.md`, and any build files.

## Feature Implementation Workflow

Most agent tasks in this repository are image changes. For these tasks:

1. Identify the affected image under `images/<image>/` and keep changes scoped to that image.
2. Read the relevant `image.yaml`, `Dockerfile`, `README.md`, `CHANGELOG.md`, and build files before editing.
3. Implement the change in the smallest possible scope, preserving the existing image contract and conventions.
4. Keep build logic and release logic out of the root `Makefile` and workflow files unless the task explicitly requires repository-wide changes.
5. Validate with the relevant repository commands, normally `make lint` and `make digest IMAGE=<image>`.
6. If the image is intended to be reproducible, build it twice and only set `reproducible: true` after both digests match.

Ask the user for clarification only when the intended image, behavior, or compatibility impact cannot be inferred from the request and local context.

## Build and PR workflow

- Add an image by creating a new folder under `images/<image>/`; do not add image-specific logic into the root `Makefile` or workflow files.
- Build only through `make`; `build`, `digest`, `load`, and `lint` are invoked as `make ... IMAGE=<image>`.
- BuildKit is pinned by digest and build timestamps are stripped. A digest change without an input change is a bug, not noise.
- Pull requests lint every `image.yaml` and build each changed image twice; the resulting digests must match before setting `reproducible: true`.

## Release workflow

- Release from `main` with tag `<image>/vX.Y.Z`. The workflow builds, verifies, signs, and attests the image before publishing the GitHub Release.
- Never push images by hand.
- The signer identity is part of the release contract. Do not rename or move the workflow or change the tag pattern.
- GHCR packages are private by default. The owner must make each package public once in the GitHub UI; this cannot be undone.

## Repository conventions

- Pin Actions by full SHA and include the version in a comment.
- Use conventional commits; keep subject lines to 50 characters and wrap bodies at 72.
- Work on a branch and open a PR; never push directly to `main`.
- Keep each image self-contained and versioned independently.
- Maintain the release metadata in the image's `CHANGELOG.md` and tag pattern.
