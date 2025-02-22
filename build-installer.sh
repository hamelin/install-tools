#!/bin/bash
set -e
target=redhat/ubi8
image=timc-installer

docker pull "$target"
docker build --build-arg target="$target" --build-arg uid=$(id -u) --tag "$image" .
docker run -ti --rm \
    --mount type=bind,src=./src,dst=/src \
    --mount type=bind,src=./out,dst=/out \
    "$image"
docker run -ti --rm \
    --mount type=bind,src=./src,dst=/src,ro \
    --mount type=bind,src=./out,dst=/out,ro \
    --network none \
    "$image" \
    /src/test.sh /out/timc-installer-2025.02.sh
