#!/bin/bash
# Build minimal GSL library for speaker package
# Only builds the modules we need: specfunc, cdf, poly, err, sys

set -e

GSL_DIR="gsl-2.8"
BUILD_DIR="gsl_build"

cd "$(dirname "$0")"

echo "Building minimal GSL library..."

# Create build directory
mkdir -p "$BUILD_DIR"

# Configure GSL with minimal options
cd "$GSL_DIR"

if [ ! -f Makefile ]; then
    echo "Configuring GSL..."
    ./configure --prefix="$(pwd)/../$BUILD_DIR" \
                --disable-shared \
                --enable-static \
                CFLAGS="-O2 -fPIC"
fi

# Build only the modules we need
echo "Building required GSL modules..."
make -C specfunc
make -C cdf  
make -C poly
make -C complex
make -C randist
make -C rng
make -C err
make -C sys
make -C ieee-utils
make -C utils
make -C cblas

# Create combined library
cd ..
echo "Creating libgsl.a..."
ar crs libgsl.a \
    "$GSL_DIR"/specfunc/*.o \
    "$GSL_DIR"/cdf/*.o \
    "$GSL_DIR"/poly/*.o \
    "$GSL_DIR"/complex/*.o \
    "$GSL_DIR"/randist/*.o \
    "$GSL_DIR"/rng/*.o \
    "$GSL_DIR"/err/*.o \
    "$GSL_DIR"/sys/*.o \
    "$GSL_DIR"/ieee-utils/*.o \
    "$GSL_DIR"/utils/*.o \
    "$GSL_DIR"/cblas/*.o

echo "GSL library built successfully: $(pwd)/libgsl.a"
ls -lh libgsl.a
