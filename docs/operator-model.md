# Operator Model

## Overview

FindingNemos is designed for **operators** — the humans responsible for running AI agents on local infrastructure. Every decision in the system is transparent and auditable.

## Principles

1. **Operators see truth.** No hidden state. No silent failures. Every component reports its real status.
2. **Operators control policy.** Egress rules, model routing, restart policies — all operator-configured, not AI-decided.
3. **Operators own evidence.** Proofpacks collect runtime evidence that operators can export and review.
4. **Operators choose risk.** Security defaults are conservative. Operators explicitly relax controls when needed.

## Roles

| Role | Responsibility |
|------|---------------|
| Operator | Configures, deploys, monitors, and audits FindingNemos |
| Worker | A managed process (agent) supervised by FindingNemos |
| Provider | An inference backend (Ollama, llama.cpp, vLLM, OpenAI-compatible) |
| Policy | Rules governing egress, resource access, and security boundaries |

## Operator Workflows

### Initial Setup

1. Install Zig and build FindingNemos
2. Run `findingnemos init` to create `~/.findingnemos/`
3. Edit `~/.findingnemos/config.toml`
4. Run `findingnemos doctor` to verify dependencies
5. Run `findingnemos config validate` to check configuration

### Daily Operations

1. `findingnemos status` — check runtime health
2. `findingnemos model list` — verify provider availability
3. `findingnemos worker list` — check worker states
4. `findingnemos proofpack export` — snapshot evidence for audit

### Incident Response

1. `findingnemos doctor --json` — machine-readable health check
2. `findingnemos status --json` — structured status dump
3. `findingnemos proofpack export --out ./incident-$(date +%s)` — capture evidence
4. Review proofpack.json for timeline of events

## Configuration Philosophy

- **Fail closed:** Invalid config rejects the file. Unknown sections generate warnings.
- **Safe defaults:** Policy denies by default. Secrets are redacted. Restart is disabled.
- **Explicit overrides:** Operators must explicitly enable risky options (e.g., `block_ssrf = false`).
