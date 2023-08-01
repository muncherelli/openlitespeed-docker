#!/bin/bash

# Function to display usage information
usage() {
    echo "Usage: $0 -o|--ols OPENLITESPEED_VERSION -p|--php PHP_VERSION"
    exit 1
}

# Parse command line arguments
while (( "$#" )); do
  case "$1" in
    -o|--ols)
      OPENLITESPEED_VERSION=$2
      shift 2
      ;;
    -p|--php)
      PHP_VERSION=$2
      shift 2
      ;;
    *)
      usage
      ;;
  esac
done

# Ensure OPENLITESPEED_VERSION and PHP_VERSION arguments are passed
if [ -z "$OPENLITESPEED_VERSION" ] || [ -z "$PHP_VERSION" ]; then
    usage
fi

# Docker Hub username
DOCKERHUB_USERNAME="muncherelli"

# Docker image tag
TAG="${OPENLITESPEED_VERSION}-php${PHP_VERSION}"

# Docker Hub image name
DOCKERHUB_IMAGE_NAME="$DOCKERHUB_USERNAME/openlitespeed:$TAG"

# Create a new builder instance and switch to it
echo "Creating a new builder instance..."
docker buildx create --use

# Build and push the Docker image
echo "Building and pushing Docker image..."
docker buildx build --platform linux/amd64,linux/arm64 --push -t $DOCKERHUB_IMAGE_NAME --build-arg OPENLITESPEED_VERSION=$OPENLITESPEED_VERSION --build-arg PHP_VERSION=$PHP_VERSION .

echo "Done."
