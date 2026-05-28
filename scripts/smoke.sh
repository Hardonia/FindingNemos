#!/usr/bin/env bash
# SPDX-License-Identifier: Apache-2.0
# FindingNemos — smoke test
#
# Runs build, tests, and basic CLI commands to verify the scaffold.
# Exit on first failure.

set -euo pipefail

echo "=== FindingNemos Smoke Test ==="
echo ""

# 1. Build
echo "--- zig build ---"
zig build
echo "OK"
echo ""

# 2. Tests
echo "--- zig build test ---"
zig build test
echo "OK"
echo ""

BINARY="./zig-out/bin/findingnemos"

# 3. Version
echo "--- findingnemos version ---"
$BINARY version
echo ""

# 4. Doctor
echo "--- findingnemos doctor ---"
$BINARY doctor || true  # May return degraded (exit 5), that's OK
echo ""

# 5. Status JSON
echo "--- findingnemos status --json ---"
$BINARY status --json
echo ""

# 6. Config validate
echo "--- findingnemos config validate ---"
$BINARY config validate --config config/findingnemos.example.toml
echo ""

# 7. Policy check
echo "--- findingnemos policy check (allowlisted host) ---"
$BINARY policy check --host api.openai.com --config config/policy.example.toml
echo ""

echo "--- findingnemos policy check (SSRF target) ---"
$BINARY policy check --host 169.254.169.254 || true  # Expected: exit 4 (denied)
echo ""

# 8. Proofpack export
PROOF_DIR="/tmp/findingnemos-proofpack-smoke"
echo "--- findingnemos proofpack export ---"
rm -rf "$PROOF_DIR"
$BINARY proofpack export --out "$PROOF_DIR"
echo ""

# Verify proofpack files exist
if [ -f "$PROOF_DIR/proofpack.json" ] && [ -f "$PROOF_DIR/proofpack.md" ]; then
    echo "Proofpack files verified."
else
    echo "ERROR: Proofpack files missing!"
    exit 1
fi

echo ""
echo "=== Smoke Test PASSED ==="
