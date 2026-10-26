#!/bin/sh
set -eu
name="$1"
shift
go install "$@"
source_dir="$(go env GOPATH)/bin"
if [ "$GOOS/$GOARCH" != "$(go env GOHOSTOS)/$(go env GOHOSTARCH)" ]; then
    source_dir="$source_dir/${GOOS}_${GOARCH}"
fi
mkdir -p /out
cp "$source_dir/$name" "/out/$name"
