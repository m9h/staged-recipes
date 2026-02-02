#!/bin/bash
set -ex

# The source tarball (v1.0.0) is missing CMakeLists.txt.
# We inject them from the recipe directory.
cp "$RECIPE_DIR/CMakeLists.txt" .
cp "$RECIPE_DIR/python_CMakeLists.txt" python/CMakeLists.txt

# Remove -march=native for portability (conda-forge requirement)
sed -i 's/-march=native//g' CMakeLists.txt

# Create build directory
mkdir -p build
pushd build

# Configure CMake
# Use host python to find numpy/f2py
cmake ${CMAKE_ARGS} .. \
    -DPython_EXECUTABLE="$PYTHON" \
    -DCMAKE_INSTALL_PREFIX="$PREFIX" \
    -DCMAKE_BUILD_TYPE=Release \
    -G "Unix Makefiles"

# Build (lib + extensions)
make -j${CPU_COUNT}

# Install (extensions to $PREFIX/fmm3dpy)
make install

popd

# Fixup installation
# Move binary modules from $PREFIX/fmm3dpy to $SP_DIR/fmm3dpy
mkdir -p "$SP_DIR/fmm3dpy"
if [ -d "$PREFIX/fmm3dpy" ]; then
    mv "$PREFIX/fmm3dpy/"* "$SP_DIR/fmm3dpy/"
    rmdir "$PREFIX/fmm3dpy"
else
    echo "WARNING: $PREFIX/fmm3dpy not found. Build might have failed to install extensions."
fi

# Copy pure python source files (__init__.py, fmm3d.py)
# They are located in python/fmm3dpy/ relative to recipe root/source root
cp python/fmm3dpy/*.py "$SP_DIR/fmm3dpy/"
