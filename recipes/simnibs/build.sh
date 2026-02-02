#!/bin/bash
set -ex

# Set version for setuptools_scm
export SETUPTOOLS_SCM_PRETEND_VERSION="${PKG_VERSION}"

# Ensure Conda Prefix is set (setup.py checks this)
export CONDA_PREFIX="${PREFIX}"

# Debug compilation failure
# Run build_ext explicitly to see errors.
echo "Running setup.py build_ext..."
$PYTHON setup.py build_ext --inplace -v > build_log.txt 2>&1 || {
    echo "BUILD FAILED. LOG CONTENT:"
    cat build_log.txt
    exit 1
}

# Install using pip
$PYTHON -m pip install . -vv --no-deps
