#!/bin/bash

# Parse command line arguments
while [[ $# -gt 0 ]]
do
key="$1"

case $key in
    --ols)
    OPENLITESPEED_VERSION="$2"
    shift # past argument
    shift # past value
    ;;
    --php)
    PHP_VERSION="$2"
    shift # past argument
    shift # past value
    ;;
    *)    # unknown option
    shift # past argument
    ;;
esac
done

# Ensure OPENLITESPEED_VERSION and PHP_VERSION arguments are passed
if [ -z "$OPENLITESPEED_VERSION" ] || [ -z "$PHP_VERSION" ]; then
    echo "Two arguments required: --ols OPENLITESPEED_VERSION and --php PHP_VERSION"
    exit 1
fi

# Docker image tag
TAG="${OPENLITESPEED_VERSION}-php${PHP_VERSION}"

# Build the Docker image
echo "Building Docker image..."
docker build -t muncherelli/openlitespeed:$TAG --build-arg OPENLITESPEED_VERSION=$OPENLITESPEED_VERSION --build-arg PHP_VERSION=$PHP_VERSION .

echo "Done."
