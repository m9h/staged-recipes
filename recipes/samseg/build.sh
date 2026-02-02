#!/bin/bash
set -ex

# 1. Force system pybind11 usage by patching CMakeLists.txt
sed -i 's/set(pybind11_DIR $ENV{pybind11_DIR})//g' CMakeLists.txt
sed -i 's/if(NOT pybind11_DIR)/if(FALSE)/g' CMakeLists.txt
sed -i 's/add_subdirectory(${pybind11_DIR} pybind11)/find_package(pybind11 CONFIG REQUIRED)/g' CMakeLists.txt

# 2. FIX ROOT CMAKE Flags (Remove Werror and ObjC flags)
# The root CMakeLists.txt adds -Werror and -Wno-absolute-value (ObjC flag) for non-Apple builds.
# This causes GCC to fail because -Wno-absolute-value is not valid for C++, and -Werror makes it fatal.
sed -i 's/-Werror//g' CMakeLists.txt
sed -i 's/-Wno-absolute-value//g' CMakeLists.txt

# 3. FIX GEMS CMAKE Flags (Root Cause Fix + x86 Removal + ZLIB Fix)
# The upstream gems/CMakeLists.txt overwrites CMAKE_CXX_FLAGS, wiping out Conda includes (ZLIB failure)
# and hardcoding x86 flags (-msse2 failure).
# We replace the overwrite with an append, and remove the x86 flags.
find . -name "CMakeLists.txt" -print0 | xargs -0 sed -i 's/set(CMAKE_CXX_FLAGS "-fPIC -fpermissive -msse2 -mfpmath=sse")/set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -fPIC -fpermissive")/g'

# 4. FIX ZLIB Include (Explicit addition)
# Even with the flag fix, explicit include ensures safety.
sed -i 's/find_package(ZLIB REQUIRED)/find_package(ZLIB REQUIRED)\n  include_directories(${ZLIB_INCLUDE_DIRS})/g' gems/CMakeLists.txt

# 5. ENVIRONMENT CLEANUP
# Strip strict flags from environment just in case
export CXXFLAGS=$(python -c "print('$CXXFLAGS'.replace('-Werror', '').replace('-Wno-absolute-value', '').replace('-Wno-self-assign-field', '').replace('-Wno-inconsistent-missing-override', ''))")
export CFLAGS=$(python -c "print('$CFLAGS'.replace('-Werror', '').replace('-Wno-absolute-value', '').replace('-Wno-self-assign-field', '').replace('-Wno-inconsistent-missing-override', ''))")

echo "Cleaned CXXFLAGS: $CXXFLAGS"

# 6. VERIFICATION
echo "Verifying patches..."
if grep "msse2" gems/CMakeLists.txt; then echo "ERROR: msse2 found"; exit 1; fi
if grep "Werror" CMakeLists.txt; then echo "ERROR: Werror found"; exit 1; fi
if grep "Wno-absolute-value" CMakeLists.txt; then echo "ERROR: Wno-absolute-value found"; exit 1; fi

echo "Patches verified. Starting build..."

# 7. Install
$PYTHON setup.py install --single-version-externally-managed --record=record.txt
