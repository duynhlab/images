# One build path for every image: `make <target> IMAGE=<name> [VERSION=x.y.z]`.
# Per-image facts come from images/<name>/image.yaml; nothing here is image-specific.
# CI (.github/workflows/_build.yml) calls these same targets.

REGISTRY  := ghcr.io/duynhlab/images
SOURCE    := https://github.com/duynhlab/images
# BuildKit is pinned by digest and time is stripped, so the same input gives the
# same digest on any machine and in CI.
BUILDKIT  := moby/buildkit:v0.33.0@sha256:6c2fa84a6b61ccd72899dde4239f8d5717f05f9a8ca6f3cad185fb1a95a94de3
BUILDER   := images-reproducible

IMAGE   ?=
VERSION ?= 0.0.0-dev
DIR      = images/$(IMAGE)
OUT      = .out/$(IMAGE).oci.tar
REF      = $(REGISTRY)/$(IMAGE):$(VERSION)
PLATFORMS = $(shell yq -r '.platforms | join(",")' $(DIR)/image.yaml)

.DEFAULT_GOAL := help

.PHONY: help
help: ## List targets and images
	@grep -hE '^[a-z-]+:.*## ' $(MAKEFILE_LIST) | awk -F':.*## ' '{printf "  %-10s %s\n", $$1, $$2}'
	@echo "images: $$(ls images | tr '\n' ' ')"

.PHONY: check
check:
	@[ -n "$(IMAGE)" ] || { echo "IMAGE is required (one of: $$(ls images | tr '\n' ' '))" >&2; exit 2; }
	@[ -f "$(DIR)/image.yaml" ] || { echo "$(DIR)/image.yaml not found" >&2; exit 2; }
	@[ "$$(yq -r .name $(DIR)/image.yaml)" = "$(IMAGE)" ] || { echo "$(DIR)/image.yaml: name must be $(IMAGE)" >&2; exit 2; }

.PHONY: build
build: check ## Build IMAGE reproducibly into .out/<image>.oci.tar
	@docker buildx inspect $(BUILDER) >/dev/null 2>&1 || \
	  docker buildx create --name $(BUILDER) --driver docker-container \
	    --driver-opt image=$(BUILDKIT) >/dev/null
	@mkdir -p .out
	@SOURCE_DATE_EPOCH=0 docker buildx build --builder $(BUILDER) \
	  --platform $(PLATFORMS) --provenance=false --sbom=false \
	  --annotation "index:org.opencontainers.image.source=$(SOURCE)" \
	  --annotation "index:org.opencontainers.image.version=$(VERSION)" \
	  --output type=oci,dest=$(OUT),rewrite-timestamp=true,name=$(REF) \
	  --quiet $(DIR) >/dev/null

.PHONY: digest
digest: build ## Print the reference to pin: <registry>/<image>:<version>@sha256:...
	@echo "$(REF)@$$(tar -xOf $(OUT) index.json | jq -r '.manifests[0].digest')"

.PHONY: load
load: build ## Import IMAGE into every Kind node (test before a release)
	@# Streamed over stdin: /tmp in a Kind node is a tmpfs ctr cannot see. The
	@# kubelet resolves tag@digest by its repo@digest name, so tag that name too.
	@digest=$$(tar -xOf $(OUT) index.json | jq -r '.manifests[0].digest'); \
	for n in $$(kind get nodes --name $${CLUSTER_NAME:-homelab}); do \
	  docker exec -i $$n ctr -n k8s.io images import --all-platforms - < $(OUT) >/dev/null && \
	  docker exec $$n ctr -n k8s.io images tag --force $(REF) $(REGISTRY)/$(IMAGE)@$$digest >/dev/null && \
	  echo "  loaded into $$n ($(REF)@$$digest)"; \
	done

.PHONY: lint
lint: ## Check every image.yaml carries the contract fields
	@for d in images/*/; do n=$$(basename $$d); \
	  yq -e '.name and .description and (.platforms | length > 0) and (.reproducible != null)' $$d/image.yaml >/dev/null \
	    || { echo "images/$$n/image.yaml: missing name/description/platforms/reproducible" >&2; exit 1; }; \
	  [ "$$(yq -r .name $$d/image.yaml)" = "$$n" ] || { echo "images/$$n/image.yaml: name != directory" >&2; exit 1; }; \
	  [ -f $$d/Dockerfile ] || { echo "images/$$n: no Dockerfile" >&2; exit 1; }; \
	done; echo "lint OK: $$(ls images | wc -l) image(s)"
