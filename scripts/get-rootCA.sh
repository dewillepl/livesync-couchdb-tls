#!/bin/bash
# rootCA export

container="$1"
mkdir -p CA

docker cp "$container":/certs/rootCA_Win.crt     "CA/${container}-rootCA_Win.crt"
docker cp "$container":/certs/rootCA_Apple.der   "CA/${container}-rootCA_Apple.der"
docker cp "$container":/certs/rootCA_Android.crt "CA/${container}-rootCA_Android.crt"

/usr/bin/tar czf "CA/${container}-rootCA.tar.gz" \
    -C CA \
    "${container}-rootCA_Win.crt" \
    "${container}-rootCA_Apple.der" \
    "${container}-rootCA_Android.crt"

