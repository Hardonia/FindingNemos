# Changelog

All notable changes to FindingNemos will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.1.0] - 2025-05-28

### Added

- Initial Zig-first scaffold
- CLI binary (`findingnemos`) with 15 commands
- TOML config parser and validator
- Egress policy engine with allowlist/denylist/SSRF protection
- Deterministic model router (priority + local-first)
- Provider abstractions: Ollama, llama.cpp, vLLM, OpenAI-compatible
- Process supervisor skeleton with lifecycle tracking
- Proofpack evidence collection and export (JSON + Markdown)
- Health check aggregation (doctor command)
- Credential redaction helpers
- OpenShell compatibility detection (honest unknown state)
- Deterministic state model for workers, sandboxes, providers
- Exit code convention (0-10)
- Config examples for all components
- CI pipeline (GitHub Actions)
- Smoke test script
- Documentation: architecture, threat model, operator model, roadmap
- Upstream NemoClaw attribution (NOTICE)

### Status

- Phase 1 scaffold — compiles and passes tests
- Not production-ready
- No real process spawning (daemon required, Phase 2)
- No container integration (Phase 2)
- No GPU probing (Phase 2)
- No HTTP daemon (Phase 2, using JSON-over-stdin protocol)
