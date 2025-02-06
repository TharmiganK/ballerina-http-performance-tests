#!/bin/bash

set -e

# Directories
BACKEND_DIR="netty-http-transport-sample"
BALLERINA_DIR="ballerina/passthrough"

BALLERINA_PROJECTS=${BALLERINA_PROJECTS:-("h1-h1" "h1c-h1c" "h1-h2" "h2-h1" "h1c-h2c" "h2c-h1c" "h2c-h2c" "h2-h2")}

# Build backend
echo "Building backend..."
(cd "$BACKEND_DIR" && mvn clean install)

# Build Ballerina services
for project in "${BALLERINA_PROJECTS[@]}"; do
    echo "Building Ballerina service: $project"
    (cd "$BALLERINA_DIR/$project" && bal build)
done
