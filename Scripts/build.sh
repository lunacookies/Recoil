#!/bin/sh

set -e

clang-format -i Source/*.m Source/*.h Source/*.metal

rm -rf "Build"

mkdir -p "Build/Recoil.app/Contents/MacOS"
mkdir -p "Build/Recoil.app/Contents/Resources"

cp "Data/Recoil-Info.plist" "Build/Recoil.app/Contents/Info.plist"
plutil -convert binary1 "Build/Recoil.app/Contents/Info.plist"

clang \
	-o "Build/Recoil.app/Contents/MacOS/Recoil" \
	-I Source \
	-fmodules -fobjc-arc \
	-g3 \
	-fsanitize=undefined \
	-W \
	-Wall \
	-Wextra \
	-Wpedantic \
	-Wconversion \
	-Wimplicit-fallthrough \
	-Wmissing-prototypes \
	-Wshadow \
	-Wstrict-prototypes \
	"Source/EntryPoint.m"

xcrun metal \
	-o "Build/Recoil.app/Contents/Resources/default.metallib" \
	-gline-tables-only -frecord-sources \
	"Source/Shaders.metal"

cp "Data/Recoil.entitlements" "Build/Recoil.entitlements"
/usr/libexec/PlistBuddy -c 'Add :com.apple.security.get-task-allow bool YES' \
	"Build/Recoil.entitlements"
codesign \
	--sign - \
	--entitlements "Build/Recoil.entitlements" \
	--options runtime "Build/Recoil.app/Contents/MacOS/Recoil"
