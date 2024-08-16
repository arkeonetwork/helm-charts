#!/bin/sh

set -euo pipefail

REGISTRY="ghcr.io/arkeonetwork/helm-charts"

docker login -u "${CI_REGISTRY_USER}" -p "${CI_REGISTRY_PASSWORD}" "${CI_REGISTRY}"

find . -name version -printf '%h\n' | xargs basename -a | while read -r image; do
  version=$(cat "$image/version")

  # check to see if image version is already published
  if docker manifest inspect "$REGISTRY:${image}-${version}" > /dev/null 2>&1; then
    echo "Image ${image}:${version} already published."
  else
    echo "Building image $image:$version..."
    docker build -t "$REGISTRY:$image-$version" "$image"
    if [ "$CI_COMMIT_BRANCH" = "master" ]; then
      docker push "$REGISTRY:$image-$version"
    fi
  fi

done
