# Roadmap

## Versioning

FindingNemos follows semantic versioning. Phase 1 is `0.1.x`.

## Phase 1: Foundation (0.1.x) — CURRENT

- [x] Zig build scaffold
- [x] CLI binary with 15 commands
- [x] TOML config parser and validator
- [x] Egress policy engine (allowlist/denylist/SSRF)
- [x] Deterministic model router
- [x] Provider abstractions (Ollama, llama.cpp, vLLM, OpenAI-compatible)
- [x] Process supervisor skeleton
- [x] Proofpack evidence collection and export
- [x] Health check aggregation
- [x] Credential redaction
- [x] Docs, CI, smoke tests

## Phase 2: Runtime (0.2.x)

- [ ] HTTP daemon (replace JSON-over-stdin)
- [ ] Real process spawning via daemon
- [ ] Docker container creation and management
- [ ] Provider health probes (actual HTTP GET)
- [ ] Worker stdout/stderr capture to log files
- [ ] Startup timeout enforcement
- [ ] Resource limit configuration
- [ ] Config hot-reload
- [ ] State persistence to disk
- [ ] Model route tracing with provider response times

## Phase 3: Hardening (0.3.x)

- [ ] OpenShell integration and verification
- [ ] Container security hardening (seccomp, capabilities)
- [ ] GPU telemetry (nvidia-smi, ROCm)
- [ ] Memory telemetry (OS-specific probes)
- [ ] Network namespace isolation
- [ ] TLS for daemon communication
- [ ] Audit log persistence
- [ ] Policy enforcement at network level
- [ ] Proofpack digital signatures

## Phase 4: Operations (0.4.x)

- [ ] Web UI for operator dashboard
- [ ] Remote deployment automation
- [ ] Multi-machine coordination
- [ ] Channel integrations (Telegram, Discord, Slack)
- [ ] Backup and restore
- [ ] Upgrade orchestration

## Not Planned

These are explicitly out of scope for FindingNemos:

- Model training or fine-tuning
- Dataset management
- RAG pipelines (application-layer concern)
- Prompt engineering tools
- Cloud hosting service
- Billing or monetization features

## Target Hardware

FindingNemos is designed for local AI labs running on:

- AMD HX370 / Ryzen workstations
- Intel X99 / HEDT platforms
- AMD EPYC servers
- Radxa and ARM SBCs
- Consumer GPU boxes (NVIDIA, AMD)
- Headless Linux servers
- Windows WSL2

The key constraint is that FindingNemos should work on modest hardware. GPU is optional. Docker is optional. The CLI and policy engine work everywhere Zig compiles.
