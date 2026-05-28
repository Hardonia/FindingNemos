<!-- SPDX-License-Identifier: Apache-2.0 -->

# FindingNemos

FindingNemos is a Zig-first local AI substrate for governing, routing, supervising, and proving always-on agent/runtime activity across local machines, containers, local models, and OpenAI-compatible providers.

It serves as the low-level machine-control layer for a local AI lab.

## What FindingNemos Is
- An independent Zig-first project for local AI execution and governance.
- A deterministic runtime layer for operator-truth.
- A mechanism to govern local model inference routing.
- A supervisor for local worker processes.
- A system to generate redacted, deterministic proofpacks of agent behavior.

## What FindingNemos Is Not
- NOT a NemoClaw rebrand. This is a separate, independent project.
- NOT a fake production sandbox.
- NOT a hosted SaaS control plane.
- NOT an ML router with fake intelligence.
- NOT a replacement for Docker/OpenShell (unless explicitly implemented).
- NOT a system that hides degraded states.

## Why Zig?
Zig provides explicit allocators, memory safety without hidden control flow, deterministic state transitions, and the ability to easily build cross-platform self-contained binaries. This ensures we can trust the runtime at the bottom of the stack to report operator truth.

## Current Scaffold Status
The project is currently in the initial scaffolding phase. The core layout is defined, and implementation of the policy engine, proofpack generator, daemon supervisor, and telemetry layers are underway. Do not use in production until verification proves it is ready.

## Installation and Build

### Prerequisites
- Zig (stable)

### Build
```bash
zig build
```

### Test
```bash
zig build test
```

## CLI Examples
FindingNemos provides a CLI for managing the substrate:

```bash
findingnemos --help
findingnemos version
findingnemos doctor
findingnemos status --json
findingnemos init
findingnemos config validate --config ~/.findingnemos/config.toml
findingnemos policy check --host api.example.com
findingnemos proofpack export --out ./proofpack-data
```

## Local Model Examples
FindingNemos routes prompts to providers deterministically without fake GPU requirements or undocumented magic.

```bash
findingnemos model list
findingnemos model route --prompt-file ./prompt.txt
```

Example local model backends supported (when configured):
- Local Ollama
- llama.cpp
- vLLM
- Remote/Local OpenAI-compatible endpoints

## Security Model
- **Fail Closed**: Config and security ambiguity result in denied actions.
- **Redaction by Default**: Secrets (like API keys) are never logged, tracked in state, or exported in proofpacks.
- **Egress Policy**: Explicit allowlist or denylist required. SSRF patterns for hosted-provider requests are blocked by default.
- **Deterministic States**: We never fake available states. If something is missing, it is reported as `degraded`, `unavailable`, or `unsupported`.

## Degraded States
FindingNemos is designed to tell the operator the truth about their hardware and environment. If a dependency (like Docker or a GPU driver) is missing, the system enters an explicit `degraded` state rather than failing silently or pretending the capability exists.

## Verification Commands
To verify the integrity and behavior of FindingNemos, use the included verification scripts:

```bash
# Full local smoke test
./scripts/smoke.sh

# Release verification checks
./scripts/release-check.sh
```

## Roadmap
- [x] Initial Identity & Repo Doctrine
- [ ] Core Contracts, Config, and State validation
- [ ] Egress Policy, SSRF prevention, and Proofpack security
- [ ] Local Daemon, Worker Supervisor, and Runtime Shell
- [ ] Inference Provider checking and routing
- [ ] Hardware/Local Lab telemetry adapters
- [ ] CI Verification and Release mechanics
