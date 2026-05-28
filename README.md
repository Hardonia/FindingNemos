# FindingNemos

**Zig-first local AI substrate for governed agent execution.**

FindingNemos is a runtime for running, routing, supervising, and governing always-on AI agents across local machines, containers, and model backends. It is the low-level machine-control layer for local AI labs.

> **Status: Alpha scaffold (Phase 1).** This project compiles and runs basic CLI commands. It is not production-ready. See [Roadmap](#roadmap) for what's next.

## What FindingNemos Is

- A **Zig-native CLI and daemon** for managing local AI agent processes
- A **deterministic model router** connecting to Ollama, llama.cpp, vLLM, and OpenAI-compatible endpoints
- A **policy engine** with egress allowlists, denylists, SSRF protection, and private-IP blocking
- A **process supervisor** for agent worker lifecycle management
- A **proofpack system** for collecting and exporting operator evidence
- A **truthful status reporter** — every dependency is `available`, `degraded`, `unavailable`, or `unknown`

## What FindingNemos Is Not

- Not a cloud service
- Not a model training framework
- Not a web UI (planned for future phases)
- Not production-ready sandbox isolation (container hardening is Phase 2+)
- Not affiliated with NVIDIA (this project is derived from the open-source NemoClaw fork under Apache 2.0)

## Why Zig

- **Explicit memory control** — no hidden allocations, no GC pauses
- **Deterministic behavior** — same input, same output, every time
- **Small, fast binaries** — single binary deployment, no runtime dependencies
- **Cross-compilation** — build for Linux, macOS, Windows from any host
- **Safety without complexity** — bounds checking, no undefined behavior in safe code
- **Ideal for systems programming** — process supervision, daemon management, policy enforcement

## Quick Start

### Prerequisites

- [Zig 0.14+](https://ziglang.org/download/)

### Build

```bash
zig build
```

### Run

```bash
# Show version
./zig-out/bin/findingnemos version

# System health check
./zig-out/bin/findingnemos doctor

# Runtime status (JSON)
./zig-out/bin/findingnemos status --json

# Validate config
./zig-out/bin/findingnemos config validate --config config/findingnemos.example.toml

# Check egress policy
./zig-out/bin/findingnemos policy check --host api.openai.com --config config/policy.example.toml

# Export proofpack
./zig-out/bin/findingnemos proofpack export --out ./proofpacks/latest
```

### Test

```bash
zig build test
```

## CLI Reference

| Command | Description |
|---------|-------------|
| `findingnemos version` | Show version |
| `findingnemos doctor` | Check system dependencies |
| `findingnemos status [--json]` | Runtime status |
| `findingnemos init` | Initialize ~/.findingnemos/ |
| `findingnemos config validate --config <path>` | Validate config file |
| `findingnemos daemon run` | Start daemon (foreground) |
| `findingnemos daemon status` | Check daemon status |
| `findingnemos worker list` | List workers |
| `findingnemos worker start --name <n> --cmd <c>` | Start a worker |
| `findingnemos worker stop --name <n>` | Stop a worker |
| `findingnemos worker logs --name <n>` | Show worker logs |
| `findingnemos model list` | List model providers |
| `findingnemos model route --prompt-file <p>` | Route to best provider |
| `findingnemos policy check --host <h>` | Check egress policy |
| `findingnemos proofpack export --out <path>` | Export proofpack |

### Exit Codes

| Code | Meaning |
|------|---------|
| 0 | Success |
| 1 | Operational failure |
| 2 | Invalid user input |
| 3 | Dependency unavailable |
| 4 | Policy denied |
| 5 | Degraded state |
| 10 | Internal error |

## Local Model Setup

### Ollama

```toml
# config.toml
[models]
local_first = true
ollama_endpoint = "http://localhost:11434"
```

```bash
# Start Ollama, then check:
findingnemos model list
```

### llama.cpp

```toml
[models]
llamacpp_endpoint = "http://localhost:8080"
```

### vLLM

```toml
[models]
vllm_endpoint = "http://localhost:8000"
```

## Security Model

- **Deny-by-default egress policy** — all outbound connections blocked unless allowlisted
- **SSRF protection** — blocks cloud metadata endpoints, private IPs, localhost
- **No raw secrets in config** — API keys referenced by environment variable name only
- **Secret redaction** — proofpacks, logs, and status output never contain raw keys
- **Honest capability reporting** — dependencies report `available`/`unavailable`/`unknown`, never faked

See [SECURITY.md](SECURITY.md) and [docs/threat-model.md](docs/threat-model.md) for details.

## Degraded States

FindingNemos never hides missing dependencies or failed checks. Every component reports its true state:

| Component | States |
|-----------|--------|
| Worker | unknown → configured → starting → running → healthy → degraded → stopping → stopped → failed |
| Sandbox | unavailable → not_configured → configured → creating → running → degraded → stopped → failed |
| Provider | unavailable → configured → reachable → degraded → failed |
| Policy | allowed / denied / unknown / unsupported |

If Docker, OpenShell, GPU, or a model endpoint is unavailable, FindingNemos reports that honestly instead of panicking or pretending.

## Verification

```bash
# Build and test
zig build
zig build test

# Smoke test
./scripts/smoke.sh

# Format check
zig build fmt
```

## Architecture

See [docs/architecture.md](docs/architecture.md) for the full module map.

```
src/
├── main.zig          # CLI entry point
├── cli/              # Argument parsing, command dispatch
├── core/             # Errors, state, IDs, time, paths, JSON
├── config/           # TOML parsing, schema, validation
├── daemon/           # Local daemon protocol and health
├── supervisor/       # Process lifecycle management
├── sandbox/          # Container detection, OpenShell compat
├── inference/        # Provider abstraction, router
├── policy/           # Egress policy, SSRF validation
├── telemetry/        # System metrics, GPU detection
└── proof/            # Proofpack generation and export
```

## Upstream Attribution

FindingNemos is derived from [NVIDIA NemoClaw](https://github.com/NVIDIA/NemoClaw), licensed under Apache 2.0. See [NOTICE](NOTICE) for attribution details and [docs/upstream-nemoclaw-notes.md](docs/upstream-nemoclaw-notes.md) for architectural notes.

## Roadmap

See [docs/roadmap.md](docs/roadmap.md) for the full roadmap.

**Phase 1 (current):** Zig scaffold, CLI, config, policy, proofpack, supervisor skeleton, docs
**Phase 2:** HTTP daemon, real process spawning, Docker integration, provider health probes
**Phase 3:** Sandbox hardening, OpenShell integration, GPU telemetry
**Phase 4:** Web UI, remote deployment, channel integrations

## License

Apache 2.0. See [LICENSE](LICENSE).
