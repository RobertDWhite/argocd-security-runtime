# Argo CD runtime rebuild

This derived image uses pinned Argo CD v3.5.6 source and rebuilds Git LFS 3.8.1, Kustomize 5.8.3, Helm 4.3.1 and KSOPS 4.5.1 using Go 1.27.3. The KSOPS source is pinned by full commit. Go module checksums verify downloaded module source. OS packages are updated during build; published images must be consumed by immutable digest.

The upstream application binary already uses Go 1.26.10. Updating and rebuilding downloaded helpers addresses embedded toolchain and helper security findings. Rendering compatibility must be tested before deployment. Git LFS 3.8.1 includes fixes for CVE-2026-69260, CVE-2026-69261, CVE-2026-105802 and CVE-2026-105803. The image includes KSOPS directly; deployments must remove any old init-container mount that would overwrite it.

CI builds amd64 and arm64 images. Candidate scans, representative Helm/Kustomize/KSOPS rendering, Git operations, authentication and live reconciliation are required before deployment. Rebuilding the toolchain does not claim that all dependency findings are resolved. Source versions and their licenses remain those of their upstream projects.

Sources: [Argo CD](https://github.com/argoproj/argo-cd/tree/v3.5.6), [Git LFS](https://github.com/git-lfs/git-lfs/tree/v3.8.1), [Kustomize](https://github.com/kubernetes-sigs/kustomize/tree/kustomize/v5.8.3), [Helm](https://github.com/helm/helm/tree/v4.3.1), [KSOPS](https://github.com/viaduct-ai/kustomize-sops/tree/d9442dc3153d9c16e517a68ce8926c9507386429).


## Dependency remediation

The next candidate also rebuilds Canonical Pebble v1.33.2, replacing the inherited binary. Argo uses tini as its entrypoint; retaining a patched Pebble avoids relying on absence of current use as remediation. Git LFS, KSOPS and Pebble use checked-in module locks with x/net0.60.0 (and its required x/crypto0.57.0 / x/text0.42.0 where applicable); KSOPS uses gRPC1.83.2. Module source is verified through Go checksum verification. Build scripts test native binaries before cross-compilation, with isolated GPG fixture keys for KSOPS.

The main Argo binary is rebuilt with compress1.18.7 and x/net0.60.0 to address its two high dependency findings. Its UI is built unchanged from the same pinned source/lockfile. The version identifies downstream dependency changes through its dirty source state and downstream-dependency-patches extra build information. The OCI size-limit test derives the generated manifest digest rather than hard-coding bytes produced by the old compressor; its exact rejection assertion remains intact. Transport/OCI/archive tests run during the build. This is a downstream build, not an upstream release or a claim that the full upstream contribution pipeline passed. Fresh image scans, authentication, reconciliation and production gates remain mandatory.
