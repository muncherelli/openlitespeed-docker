#!/bin/bash

REPO_OWNER="muncherelli"

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

# Docker image tag
TAG="${OPENLITESPEED_VERSION}-php${PHP_VERSION}"

# Build the Docker image
echo "Building Docker image..."
if docker build --no-cache -t ${REPO_OWNER}/openlitespeed:$TAG --build-arg OPENLITESPEED_VERSION=$OPENLITESPEED_VERSION --build-arg PHP_VERSION=$PHP_VERSION . ; then
    echo "Docker image built successfully."
else
    echo "Failed to build Docker image."
    exit 1
fi
