#!/bin/bash

# Define source and destination
BUILD_DIR="src-engine/build"

(cd BUILD_DIR && make -j$(nproc))

