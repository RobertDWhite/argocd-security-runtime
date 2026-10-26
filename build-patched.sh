#!/bin/sh
set -eu
name="$1"; module="$2"; version="$3"; package="$4"
go mod download "$module@$version"
source="$(go env GOMODCACHE)/$module@$version"
work="/tmp/patched-$name"
mkdir -p "$work"
cp -a "$source/." "$work/"
chmod -R u+w "$work"
cp "/locks/$name/go.mod" "/locks/$name/go.sum" "$work/"
cd "$work"
go mod download
go mod verify
# Tests execute natively; only the final build uses the target architecture.
export GIT_CONFIG_COUNT=1 GIT_CONFIG_KEY_0=init.defaultBranch GIT_CONFIG_VALUE_0=master
if [ "$name" = ksops ]; then
    export GNUPGHOME="$work/test-gnupg" KUSTOMIZE_PLUGIN_HOME="$work/test-plugins"
    mkdir -m 700 "$GNUPGHOME"
    mkdir -p "$KUSTOMIZE_PLUGIN_HOME/viaduct.ai/v1/ksops" "$KUSTOMIZE_PLUGIN_HOME/viaduct.ai/v1/ksops-exec"
    go build -mod=readonly -o /usr/local/bin/ksops .
    cp /usr/local/bin/ksops "$KUSTOMIZE_PLUGIN_HOME/viaduct.ai/v1/ksops/ksops"
    cp /usr/local/bin/ksops "$KUSTOMIZE_PLUGIN_HOME/viaduct.ai/v1/ksops-exec/ksops-exec"
    gpg --batch --import test/key.asc
    go test -mod=readonly -count=1 ./...
elif [ "$name" = pebble ]; then
    go test -mod=readonly -count=1 ./cmd/...
else
    go test -mod=readonly -count=1 ./...
fi
mkdir -p /out
GOOS="$TARGETOS" GOARCH="$TARGETARCH" go build -mod=readonly -trimpath -ldflags="-s -w" -o "/out/$name" "$package"
