FROM --platform=$BUILDPLATFORM golang:1.26.10@sha256:5c3f3f28a273c9b61698b2d34f18375929790ab1f1d3835d032d21e2b31eae0c AS tools
ARG TARGETOS TARGETARCH
ENV GOTOOLCHAIN=local CGO_ENABLED=0 GOBIN=/out
RUN --mount=type=cache,target=/go/pkg/mod --mount=type=cache,target=/root/.cache/go-build \
    GOOS=$TARGETOS GOARCH=$TARGETARCH go install -trimpath -ldflags="-s -w" github.com/git-lfs/git-lfs/v3@v3.7.1
RUN --mount=type=cache,target=/go/pkg/mod --mount=type=cache,target=/root/.cache/go-build \
    GOOS=$TARGETOS GOARCH=$TARGETARCH go install -trimpath -ldflags="-s -w -X sigs.k8s.io/kustomize/api/provenance.version=v5.8.1" sigs.k8s.io/kustomize/kustomize/v5@v5.8.1
RUN --mount=type=cache,target=/go/pkg/mod --mount=type=cache,target=/root/.cache/go-build \
    GOOS=$TARGETOS GOARCH=$TARGETARCH go install -trimpath -ldflags="-s -w -X helm.sh/helm/v4/internal/version.version=v4.2.1" helm.sh/helm/v4/cmd/helm@v4.2.1
RUN --mount=type=cache,target=/go/pkg/mod --mount=type=cache,target=/root/.cache/go-build \
    GOOS=$TARGETOS GOARCH=$TARGETARCH go install -trimpath -ldflags="-s -w" github.com/viaduct-ai/kustomize-sops@d9442dc3153d9c16e517a68ce8926c9507386429 \
    && mv /out/kustomize-sops /out/ksops
RUN for binary in /out/git-lfs /out/kustomize /out/helm /out/ksops; do go version -m "$binary" | head -1 | grep 'go1.26.10'; done

FROM quay.io/argoproj/argocd:v3.5.6@sha256:8e5cc5bb008df8a09dba439462e58c94c55b7735888d3ebde0c25fc05e4e5335
USER root
RUN apt-get update && apt-get dist-upgrade -y && rm -rf /var/lib/apt/lists/*
COPY --from=tools /out/git-lfs /out/kustomize /out/helm /out/ksops /usr/local/bin/
LABEL org.opencontainers.image.source="https://github.com/RobertDWhite/argocd-security-runtime"
USER 999
