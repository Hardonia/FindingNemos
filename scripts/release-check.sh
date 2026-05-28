#!/usr/bin/env bash
set -e

echo "Running release safety checks..."

# Check formatting
zig fmt --check .

# Run tests
zig build test

# Run smoke test
./scripts/smoke.sh

# Look for secrets
if command -v gitleaks &> /dev/null; then
    gitleaks detect -v
else
    echo "gitleaks not installed, skipping secret scan."
fi

echo "Release checks passed."
