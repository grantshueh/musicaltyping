#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")"

APP="build/Musical Typing.app"
rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"

swiftc -O app/main.swift -o "$APP/Contents/MacOS/MusicalTyping"
cp app/Info.plist "$APP/Contents/Info.plist"
cp index.html "$APP/Contents/Resources/index.html"
codesign --force -s - "$APP"

echo "Built: $APP"
