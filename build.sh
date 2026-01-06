#!/bin/bash
set -e

# Build the release binary
swift build -c release

# Find the built binary
BINARY_PATH=$(swift build -c release --show-bin-path)/contactbook

# Sign the binary with entitlements using Apple Development certificate
echo "Signing binary with entitlements..."
# Try to use Apple Development certificate if available, otherwise fall back to adhoc
SIGNING_IDENTITY=$(security find-identity -v -p codesigning 2>/dev/null | grep "Apple Development" | grep -v "CSSMERR_TP_CERT_REVOKED" | head -1 | awk '{print $2}')

if [ -n "$SIGNING_IDENTITY" ]; then
    echo "Using signing identity hash: $SIGNING_IDENTITY"
    codesign --force --sign "$SIGNING_IDENTITY" --entitlements Contactbook.entitlements --options runtime "$BINARY_PATH"
else
    echo "No Apple Development certificate found, using adhoc signing..."
    codesign --force --sign - --entitlements Contactbook.entitlements --options runtime "$BINARY_PATH"
    echo "Note: Adhoc-signed binaries may require manual permission grant in System Settings"
fi

# Remove quarantine attribute to allow execution (development only)
echo "Removing quarantine attribute..."
xattr -d com.apple.quarantine "$BINARY_PATH" 2>/dev/null || true

echo "Build complete. Binary at: $BINARY_PATH"
echo "To install: cp $BINARY_PATH /usr/local/bin/contactbook"
