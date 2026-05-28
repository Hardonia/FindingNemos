#!/usr/bin/env bash
# SPDX-License-Identifier: Apache-2.0
# FindingNemos — local install
#
# Builds and copies the findingnemos binary to a local bin directory.

set -euo pipefail

INSTALL_DIR="${1:-$HOME/.local/bin}"

echo "Building FindingNemos..."
zig build -Doptimize=ReleaseSafe

echo "Installing to $INSTALL_DIR..."
mkdir -p "$INSTALL_DIR"
cp zig-out/bin/findingnemos "$INSTALL_DIR/findingnemos"
chmod +x "$INSTALL_DIR/findingnemos"

echo "Installed: $INSTALL_DIR/findingnemos"
echo ""
echo "Ensure $INSTALL_DIR is in your PATH."
echo "Run 'findingnemos version' to verify."
