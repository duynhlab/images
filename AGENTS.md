# AGENTS.md

Repository facts for agents working in `duynhlab/images`.

- **What lives here:** platform-built images that are not application
  services. One directory per image under `images/<image>/`, and every
  per-image fact is in its `image.yaml`.
- **Never** add image-specific logic to the `Makefile` or the workflows.
  Adding an image is adding a directory (README § Add an image).
- **Build only through `make`.** `build`, `digest`, `load` and `lint` all take
  `IMAGE=`.
  - BuildKit is pinned by digest and time is stripped.
  - A digest change without an input change is a bug, not noise.
- **Release:** tag `<image>/vX.Y.Z` on `main`; `release.yml` pushes, verifies the
  registry digest, signs, attests and creates the GitHub Release. Never push
  images by hand.
- **The signer identity is a contract.** Consumers verify against
  `.github/workflows/release.yml@refs/tags/<image>/v…`. Renaming or moving that
  workflow, or changing the tag pattern, breaks every consumer's verification.
- **New package:** GHCR creates it private. The owner makes it public in the
  UI once, and that cannot be undone.
- **Commits:** conventional; no attribution trailers; subject ≤50 chars; body
  wrapped at 72. Branch, then PR; never push to `main`.
- **Actions** are pinned by full SHA, with the version in a comment.
