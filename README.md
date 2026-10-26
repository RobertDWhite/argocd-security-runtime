# Argo CD runtime rebuild

This derived image retains the pinned official Argo CD v3.5.6 application binary and rebuilds Git LFS 3.7.1, Kustomize 5.8.1, Helm 4.2.1 and KSOPS 4.5.1 using Go 1.26.10. The KSOPS source is pinned by full commit. Go module checksums verify downloaded module source. OS packages are updated during build; published images must be consumed by immutable digest.

The upstream application binary already uses Go 1.26.10. Rebuilding downloaded helpers closes older embedded toolchain findings without changing the application's API or behavior. The image includes KSOPS directly; deployments must remove any old init-container mount that would overwrite it.

CI builds amd64 and arm64 images. Candidate scans, representative Helm/Kustomize/KSOPS rendering, Git operations, authentication and live reconciliation are required before deployment. Rebuilding the toolchain does not claim that all dependency findings are resolved. Source versions and their licenses remain those of their upstream projects.

Sources: [Argo CD](https://github.com/argoproj/argo-cd/tree/v3.5.6), [Git LFS](https://github.com/git-lfs/git-lfs/tree/v3.7.1), [Kustomize](https://github.com/kubernetes-sigs/kustomize/tree/kustomize/v5.8.1), [Helm](https://github.com/helm/helm/tree/v4.2.1), [KSOPS](https://github.com/viaduct-ai/kustomize-sops/tree/d9442dc3153d9c16e517a68ce8926c9507386429).
