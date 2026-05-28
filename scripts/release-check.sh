#!/usr/bin/env bash
# SPDX-License-Identifier: Apache-2.0
# FindingNemos — release check

set -euo pipefail

echo "FindingNemos Release Check"
echo "=========================="
echo ""

# Build
echo "--- Build ---"
zig build
echo "OK"

# Tests
echo "--- Tests ---"
zig build test
echo "OK"

# Format
echo "--- Format Check ---"
zig build fmt
echo "OK"

# Smoke
echo "--- Smoke ---"
./scripts/smoke.sh
echo ""

echo "=== Release Check PASSED ==="
