#!/usr/bin/env bash
# Local verification: regenerate project, then build + test + static-analyze (no signing).
# Mirrors the README "Verification" section. Requires XcodeGen + Xcode.
set -euo pipefail

cd "$(dirname "$0")/.."

DEST='platform=macOS,arch=arm64'
COMMON=(-project Polaroid.xcodeproj -scheme Polaroid -destination "$DEST" CODE_SIGNING_ALLOWED=NO)

echo "==> xcodegen generate"
xcodegen generate

echo "==> test (Debug)"
xcodebuild "${COMMON[@]}" -configuration Debug test

echo "==> build (Release)"
xcodebuild "${COMMON[@]}" -configuration Release build

echo "==> analyze (Release)"
xcodebuild "${COMMON[@]}" -configuration Release analyze

echo "==> regenerate App Store screenshots"
swift AppStore/generate_screenshots.swift

echo "OK: build + tests + analysis passed."
