#!/bin/sh

XCODEBUILD_PATH="/Applications/Xcode.app/Contents/Developer/usr/bin"
XCODEBUILD=$XCODEBUILD_PATH/xcodebuild

$XCODEBUILD -project Echo.xcodeproj -target "Echo" -sdk "iphonesimulator" -arch "x86_64" -configuration "Debug" clean build CODE_SIGN_IDENTITY="" CODE_SIGNING_REQUIRED=NO ONLY_ACTIVE_ARCH=NO VALID_ARCHS="i386 x86_64" | xcpretty
