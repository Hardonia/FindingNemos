<!-- SPDX-License-Identifier: Apache-2.0 -->

# Agent Instructions — FindingNemos

## Project Identity

FindingNemos is a Zig-first local AI substrate for governed agent execution. It is derived from NVIDIA NemoClaw (Apache 2.0) but is an independent project with its own identity, codebase, and direction.

## Core Doctrine

1. **Reality mode.** No theatre. No fake capability claims. Every feature is implemented, degraded, or explicitly unavailable.
2. **Zig-first.** Core runtime, CLI, daemon, config validation, process supervision, and control plane are written in Zig.
3. **Explicit verification.** Every claim must be backed by real state, real process checks, or explicit unsupported status.
4. **Security invariants.** No secret leakage. No raw API keys in logs, proofpacks, config, status, or test fixtures.
5. **Deterministic degraded states.** Missing dependencies report `unknown` or `unavailable`, never faked as `available`.
6. **Always update docs/tests with behavior changes.** No undocumented behavior.
7. **No fake autonomy.** Do not claim AI capabilities that aren't implemented.

## Architecture

| Path | Language | Purpose |
|------|----------|---------|
| `src/main.zig` | Zig | CLI entry point |
| `src/cli/` | Zig | Argument parsing, command dispatch |
| `src/core/` | Zig | Errors, state, IDs, time, paths, JSON writer |
| `src/config/` | Zig | TOML parsing, schema, validation |
| `src/daemon/` | Zig | Local daemon protocol and health |
| `src/supervisor/` | Zig | Process lifecycle management |
| `src/sandbox/` | Zig | Container detection, OpenShell compat |
| `src/inference/` | Zig | Provider abstraction, deterministic router |
| `src/policy/` | Zig | Egress policy, SSRF validation |
| `src/telemetry/` | Zig | System metrics, GPU detection |
| `src/proof/` | Zig | Proofpack generation and export |
| `config/` | TOML | Example configuration files |
| `docs/` | Markdown | Architecture, threat model, operator docs |
| `scripts/` | Bash | Build helpers, smoke tests |

## Quick Reference

| Task | Command |
|------|---------|
| Build | `zig build` |
| Test | `zig build test` |
| Format check | `zig build fmt` |
| Run CLI | `./zig-out/bin/findingnemos` |
| Smoke test | `./scripts/smoke.sh` |

## Code Conventions

### Zig

- Use explicit allocators everywhere
- No global mutable state unless justified and documented
- Avoid hidden heap allocation in hot paths
- Every module should have inline `test` blocks
- Use bounded buffers where reasonable
- Config parsing must fail closed
- Prefer small composable modules over giant files
- Add comments only where they clarify invariants or safety boundaries

### Security

- Secret values must be redacted in all output
- Never store raw API keys — reference env var names only
- Egress policy defaults to deny
- SSRF validation is always on by default
- Unknown dependency state is `unknown`, never `available`

### Exit Codes

- 0: success
- 1: operational failure
- 2: invalid user input/config
- 3: dependency unavailable
- 4: policy denied
- 5: degraded/partial state
- 10: internal invariant violation

### SPDX Headers

Every source file must include:

```zig
// SPDX-License-Identifier: Apache-2.0
```

## Testing

- Inline tests in each module (run via `zig build test`)
- Integration tests in `src/tests/`
- Smoke test script: `scripts/smoke.sh`
- CI runs: format check, build, test, smoke

## Making Changes

1. Ensure `zig build` succeeds
2. Ensure `zig build test` passes
3. Run `scripts/smoke.sh` for end-to-end validation
4. Update docs for any user-facing changes
5. Update CHANGELOG.md
6. Never commit raw secrets or API keys
