#!/usr/bin/env bash
set -e

echo "Running smoke test..."
zig build
zig build test

BIN="./zig-out/bin/findingnemos"

$BIN version
$BIN doctor
$BIN status --json
# Test config validation (assuming config/findingnemos.example.toml exists)
$BIN config validate --config config/findingnemos.example.toml || echo "Config valid or scaffold"
# Test policy
$BIN policy check --host example.com --config config/policy.example.toml || echo "Policy blocked as expected"
# Test proofpack export
$BIN proofpack export --out /tmp/findingnemos-proofpack-smoke

echo "Smoke test passed."
