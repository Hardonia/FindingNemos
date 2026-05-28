# Upstream NemoClaw Notes

## Attribution

FindingNemos is derived from [NVIDIA NemoClaw](https://github.com/NVIDIA/NemoClaw), licensed under the Apache License 2.0. See the [NOTICE](../NOTICE) file for full attribution.

## What We Took From NemoClaw

### Architectural Concepts

FindingNemos preserves the following architectural ideas from NemoClaw:

1. **Governed always-on agents** — The idea that AI agents running continuously need governance controls, not just execution.

2. **Sandbox lifecycle management** — Workers have explicit states (configured → starting → running → healthy → degraded → stopped → failed).

3. **Inference routing** — Multiple model providers can be configured and the system routes to the best available.

4. **Policy-gated execution** — Egress controls, SSRF protection, and allowlists from NemoClaw's blueprint policies.

5. **Credential sanitization** — Never storing raw API keys, only referencing environment variable names.

6. **Operator evidence** — The concept of collecting runtime evidence for operator review (NemoClaw called this observability; we call it proofpacks).

### What We Changed

| NemoClaw | FindingNemos | Why |
|----------|-------------|-----|
| TypeScript + Node.js | Zig | Explicit memory control, single binary, no runtime deps |
| Blueprint YAML | TOML config | Simpler, standard, Zig-parseable |
| Commander CLI (npm) | Hand-rolled Zig CLI | No dependency chain |
| OpenShell mandatory | OpenShell optional | Works without containers |
| Docker required | Docker optional | Degrades gracefully |
| Plugin architecture | Monolithic binary | Simpler for Phase 1 |
| HTTP API | JSON-over-stdin (Phase 1) | Simpler, then upgrade |
| npm/node ecosystem | Zero dependencies | Zig stdlib only |

### What We Removed

- NVIDIA branding and product references
- Node.js / TypeScript runtime
- npm package management
- Biome/ESLint/Prettier tooling
- Vitest test framework
- Commander.js CLI framework
- Fern documentation system
- Pre-commit hooks (prek)
- Dockerfile and Docker Compose
- GitHub CODEOWNERS and PR templates (NemoClaw-specific)
- Commitlint configuration

### What We Preserved

- Apache 2.0 license (same terms)
- NOTICE file with upstream attribution
- `.agents/skills/` directory (NemoClaw agent skills, reference only)

## Compatibility Strategy

FindingNemos can coexist with NemoClaw on the same machine:

- FindingNemos uses `~/.findingnemos/` for its state
- NemoClaw uses its own paths
- No port conflicts by default (FindingNemos: 9100, NemoClaw: varies)
- OpenShell compatibility is opt-in — FindingNemos detects but doesn't assume

If you need NemoClaw's features (full OpenShell integration, OpenClaw plugins, channel messaging), use NemoClaw. FindingNemos is for operators who want Zig-native control.
