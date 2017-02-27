#!/bin/sh
# This script runs scan-build to perform a static code analysis
# https://clang-analyzer.llvm.org/scan-build.html
#
# The actual compilers have to be set in the CCC prefix env. variables. e.g:
# export CCC_CC=clang-3.8
# export CCC_CXX=clang++3.8

BUILD_DIR=./build.analyze
REPORT_DIR=report            # relative to BUILD_DIR
BUILD_WRAPPER="${SCANBUILD_BIN}";
ANALYZE_OPTS="-o $REPORT_DIR -analyze-headers -plist-html"


# try to find build wrapper
if [ "$BUILD_WRAPPER" = "" ]; then
  BUILD_WRAPPER="scan-build"
fi

which $BUILD_WRAPPER ||
  (echo "This build requires $BUILD_WRAPPER. Set env. var SCANBUILD_BIN" \
   & exit 1);

FORCE_BUILD=false
if [ "$1" = "-f" ]; then
  FORCE_BUILD=true
fi

await_confirm() {
  if ! $FORCE_BUILD; then
    echo ""
    echo "   To build and analyze using these settings, hit ENTER"
    read confirm
  fi
}

exit_message() {
  echo "--------------------------------------------------------"
  echo "Done. To install DASH, run    make install    in $BUILD_DIR"
}

if [ "${PAPI_HOME}" = "" ]; then
  PAPI_HOME=$PAPI_BASE
fi

# To specify a build configuration for a specific system, use:
#
#                    -DENVIRONMENT_TYPE=<type> \
#
# For available types, see the files in folder ./config.
# To specify a custom build configuration, use:
#
#                    -DENVIRONMENT_CONFIG_PATH=<path to cmake file> \
#

# To use an existing installation of gtest instead of downloading the sources
# from the google test subversion repository, use:
#
#                    -DGTEST_LIBRARY_PATH=${HOME}/gtest \
#                    -DGTEST_INCLUDE_PATH=${HOME}/gtest/include \
#

# To build with MKL support, set environment variables MKLROOT and INTELROOT.
#

# To enable IPM runtime support, use:
#
#                    -DIPM_PREFIX=<IPM install path> \

# For likwid support, ensure that the likwid development headers are
# installed.

# Configure with default release build settings:
mkdir -p $BUILD_DIR/$REPORT_DIR
rm -Rf $BUILD_DIR/*
(cd $BUILD_DIR && $BUILD_WRAPPER $ANALYZE_OPTS \
                  cmake -DCMAKE_BUILD_TYPE=Release \
                        -DENVIRONMENT_TYPE=default \
                        -DENABLE_COMPTIME_RED=OFF \
                        \
                        -DDART_IF_VERSION=3.2 \
                        -DINSTALL_PREFIX=$HOME/opt/dash-0.3.0/ \
                        -DDART_IMPLEMENTATIONS=mpi \
                        -DENABLE_THREADSUPPORT=ON \
                        -DENABLE_DEV_COMPILER_WARNINGS=OFF \
                        -DENABLE_EXT_COMPILER_WARNINGS=OFF \
                        -DENABLE_LT_OPTIMIZATION=OFF \
                        -DENABLE_ASSERTIONS=ON \
                        \
                        -DENABLE_SHARED_WINDOWS=ON \
                        -DENABLE_UNIFIED_MEMORY_MODEL=ON \
                        -DENABLE_DEFAULT_INDEX_TYPE_LONG=ON \
                        \
                        -DENABLE_LOGGING=OFF \
                        -DENABLE_TRACE_LOGGING=OFF \
                        -DENABLE_DART_LOGGING=OFF \
                        \
                        -DENABLE_LIBNUMA=ON \
                        -DENABLE_LIKWID=OFF \
                        -DENABLE_HWLOC=ON \
                        -DENABLE_PAPI=ON \
                        -DENABLE_MKL=OFF \
                        -DENABLE_BLAS=ON \
                        -DENABLE_LAPACK=ON \
                        -DENABLE_SCALAPACK=ON \
                        -DENABLE_PLASMA=ON \
                        -DENABLE_HDF5=ON \
                        \
                        -DBUILD_EXAMPLES=ON \
                        -DBUILD_TESTS=ON \
                        -DBUILD_DOCS=ON \
                        \
                        -DIPM_PREFIX=${IPM_HOME} \
                        -DPAPI_PREFIX=${PAPI_HOME} \
                        \
                        -DCMAKE_EXPORT_COMPILE_COMMANDS=ON \
                        ../ && \
 await_confirm && \
 $BUILD_WRAPPER $ANALYZE_OPTS make -j 4) && \
 (cp $BUILD_DIR/compile_commands.json .) && \
exit_message

