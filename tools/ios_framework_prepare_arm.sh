#!/bin/bash

set -e

ROOT=${PWD}

SCRIPT_DIR="$(dirname "$BASH_SOURCE")"
cd "$SCRIPT_DIR"
SCRIPT_DIR=${PWD}

# Set up the Node.js source root
cd ../

LIBRARY_PATH='out/Release'
TARGET_LIBRARY_PATH='tools/ios-framework/bin'
NODELIB_PROJECT_PATH='tools/ios-framework'

# Declare output files for arm64 devices
declare -a outputs_common=(
    "libada.a"
    "libbase64.a"
    "libbrotli.a"
    "libcares.a"
    "libgtest_main.a"
    "libgtest.a"
    "libhistogram.a"
    "libllhttp.a"
    "libnghttp2.a"
    "libnghttp3.a"
    "libngtcp2.a"
    "libnode.a"
    "libopenssl.a"
    "libsimdutf.a"
    "libuv.a"
    "libuvwasi.a"
    "libv8_base_without_compiler.a"
    "libv8_compiler.a"
    "libv8_initializers.a"
    "libv8_libbase.a"
    "libv8_libplatform.a"
    "libv8_snapshot.a"
    "libv8_zlib.a"
    "libzlib.a"
)

declare -a outputs_arm64_only=(
    "libbase64_neon64.a"
    "libzlib_inflate_chunk_simd.a"
)

declare -a outputs_arm64=("${outputs_common[@]}" "${outputs_arm64_only[@]}")

# Compile Node.js for iOS arm64 devices
make clean 
GYP_DEFINES="target_arch=arm64 host_os=mac target_os=ios"
export GYP_DEFINES
./configure \
  --dest-os=ios \
  --dest-cpu=arm64 \
  --with-intl=none \
  --cross-compiling \
  --enable-static \
  --openssl-no-asm \
  --v8-options=--jitless \
  --without-node-code-cache \
  --without-node-snapshot
make -j$(getconf _NPROCESSORS_ONLN) 

# Move compilation outputs to the designated directory
mkdir -p $TARGET_LIBRARY_PATH/arm64-device
for output_file in "${outputs_arm64[@]}"; do
  cp $LIBRARY_PATH/$output_file $TARGET_LIBRARY_PATH/arm64-device/
done

# Create a path for building the frameworks
rm -rf out_ios
mkdir -p out_ios
cd out_ios
FRAMEWORK_TARGET_DIR=${PWD}
cd ../

# Compile the Framework Xcode project for iOS arm64 devices
for output_file in "${outputs_arm64[@]}"; do
  rm -f $TARGET_LIBRARY_PATH/$output_file
  mv $TARGET_LIBRARY_PATH/arm64-device/$output_file $TARGET_LIBRARY_PATH/$output_file
done

xcodebuild build \
  -project $NODELIB_PROJECT_PATH/NodeMobile.xcodeproj \
  -target "NodeMobile" \
  -configuration Release \
  -arch arm64 \
  -sdk "iphoneos" \
  SYMROOT=$FRAMEWORK_TARGET_DIR/iphoneos-arm64

# Create an XCFramework
xcodebuild -create-xcframework \
  -framework $FRAMEWORK_TARGET_DIR/iphoneos-arm64/Release-iphoneos/NodeMobile.framework \
  -output $FRAMEWORK_TARGET_DIR/NodeMobile.xcframework

echo "Framework built to $FRAMEWORK_TARGET_DIR"

# Optionally, copy Node.js headers to the desired location
source $SCRIPT_DIR/copy_libnode_headers.sh ios

# Return to the original directory
cd "$ROOT"
