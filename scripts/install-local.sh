#!/usr/bin/env bash
set -e

# Basic script to build and install locally (usually to ~/.local/bin)
INSTALL_DIR="${HOME}/.local/bin"

echo "Building FindingNemos..."
zig build -Doptimize=ReleaseSafe

echo "Installing to $INSTALL_DIR..."
mkdir -p "$INSTALL_DIR"
cp ./zig-out/bin/findingnemos "$INSTALL_DIR/"

echo "Installed successfully."
