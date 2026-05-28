# Verification Guide

## Build Verification

```bash
# Check Zig version
zig version

# Build the CLI
zig build

# Verify binary exists
ls -la zig-out/bin/findingnemos

# Check formatting
zig build fmt
```

## Test Verification

```bash
# Run all unit tests
zig build test
```

## Smoke Test

```bash
# Run the full smoke test suite
./scripts/smoke.sh
```

The smoke script runs:
1. `zig build` — compile
2. `zig build test` — unit tests
3. `findingnemos version` — version output
4. `findingnemos doctor` — dependency check
5. `findingnemos status --json` — structured status
6. `findingnemos config validate` — config validation
7. `findingnemos policy check` — policy engine
8. `findingnemos proofpack export` — evidence export

## Manual Verification

### Config Validation

```bash
./zig-out/bin/findingnemos config validate --config config/findingnemos.example.toml
# Expected: "Config valid: config/findingnemos.example.toml"
```

### Policy Check

```bash
# Public host (should be denied by default policy)
./zig-out/bin/findingnemos policy check --host example.com
# Expected: [DENY] example.com — default policy: deny

# With allowlist config
./zig-out/bin/findingnemos policy check --host api.openai.com --config config/policy.example.toml
# Expected: [ALLOW] api.openai.com — host is on the allowlist

# SSRF target
./zig-out/bin/findingnemos policy check --host 169.254.169.254
# Expected: [DENY] 169.254.169.254 — SSRF: dangerous host pattern blocked
```

### Proofpack Export

```bash
./zig-out/bin/findingnemos proofpack export --out /tmp/fn-proof
# Expected: proofpack.json and proofpack.md created

cat /tmp/fn-proof/proofpack.json | python3 -m json.tool
# Expected: valid JSON with version, events, etc.
```

### JSON Mode

```bash
./zig-out/bin/findingnemos status --json | python3 -m json.tool
# Expected: structured JSON with version, dependencies, system info
```
