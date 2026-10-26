FROM --platform=$BUILDPLATFORM golang:1.27.3@sha256:f20d83a83e18dbd2a4714b8ffd4b30b287b6243962dd75608e86abcc63ba4efc AS tools
ARG TARGETOS TARGETARCH
ENV GOTOOLCHAIN=local CGO_ENABLED=0
COPY --chmod=0755 build-tool.sh /usr/local/bin/build-tool
COPY --chmod=0755 build-patched.sh /usr/local/bin/build-patched
COPY locks /locks
RUN apt-get update && apt-get install --no-install-recommends -y gnupg && rm -rf /var/lib/apt/lists/*
RUN --mount=type=cache,target=/go/pkg/mod --mount=type=cache,target=/root/.cache/go-build \
    go install sigs.k8s.io/kustomize/kustomize/v5@v5.8.3 && cp /go/bin/kustomize /usr/local/bin/kustomize
RUN --mount=type=cache,target=/go/pkg/mod --mount=type=cache,target=/root/.cache/go-build \
    build-patched git-lfs github.com/git-lfs/git-lfs/v3 v3.8.1 .
RUN --mount=type=cache,target=/go/pkg/mod --mount=type=cache,target=/root/.cache/go-build \
    GOOS=$TARGETOS GOARCH=$TARGETARCH build-tool kustomize -trimpath -ldflags="-s -w -X sigs.k8s.io/kustomize/api/provenance.version=v5.8.3" sigs.k8s.io/kustomize/kustomize/v5@v5.8.3
RUN --mount=type=cache,target=/go/pkg/mod --mount=type=cache,target=/root/.cache/go-build \
    GOOS=$TARGETOS GOARCH=$TARGETARCH build-tool helm -trimpath -ldflags="-s -w -X helm.sh/helm/v4/internal/version.version=v4.3.1" helm.sh/helm/v4/cmd/helm@v4.3.1
RUN --mount=type=cache,target=/go/pkg/mod --mount=type=cache,target=/root/.cache/go-build \
    build-patched ksops github.com/viaduct-ai/kustomize-sops v0.0.0-20260413051436-d9442dc3153d .
RUN --mount=type=cache,target=/go/pkg/mod --mount=type=cache,target=/root/.cache/go-build \
    build-patched pebble github.com/canonical/pebble v1.33.2 ./cmd/pebble
RUN for binary in /out/pebble /out/git-lfs /out/kustomize /out/helm /out/ksops; do go version -m "$binary" | head -1 | grep 'go1.27.3'; done

FROM quay.io/argoproj/argocd:v3.5.6@sha256:8e5cc5bb008df8a09dba439462e58c94c55b7735888d3ebde0c25fc05e4e5335
USER root
RUN apt-get update && apt-get dist-upgrade -y && rm -rf /var/lib/apt/lists/*
COPY --from=tools /out/git-lfs /out/kustomize /out/helm /out/ksops /usr/local/bin/
COPY --from=tools /out/pebble /usr/bin/pebble
LABEL org.opencontainers.image.source="https://github.com/RobertDWhite/argocd-security-runtime"
USER 999
