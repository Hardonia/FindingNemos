<!-- SPDX-License-Identifier: Apache-2.0 -->

# FindingNemos Roadmap

FindingNemos is currently in its initial scaffolding phase. The roadmap represents the path to transforming the runtime into a fully realized, Zig-first local AI substrate.

## Phase 1: Identity and Foundation (Current)
- Establish the `founding/zig-first-substrate` branch.
- Define the project identity, separating it from upstream NemoClaw.
- Define the core operator model, security doctrine, and degraded states.
- Set up the initial documentation and CI/CD pipelines.

## Phase 2: Contracts, Config, and State
- Implement the TOML configuration parser.
- Define strict config validation with fail-closed mechanics.
- Implement the deterministic state engine and JSON output writer.
- Redact secrets from all outputs.

## Phase 3: Security, Policy, and Proofpacks
- Build the egress policy engine (allowlists, denylists).
- Implement SSRF protections for hosted providers.
- Develop the proofpack generator for irrefutable audit logging.

## Phase 4: Daemon and Worker Runtime
- Build the local daemon (HTTP or JSON-over-stdin).
- Implement the worker supervisor and lifecycle management.
- Develop CLI commands for interacting with the daemon and managing workers.

## Phase 5: Routing and Telemetry
- Implement deterministic provider routing (Ollama, llama.cpp, vLLM).
- Build the host telemetry gathering systems (CPU, RAM, GPU).
- Ensure graceful degradation of missing dependencies.

## Phase 6: Local Lab Hardware Adapters
- Implement profiles for specific hardware topologies (Radxa control plane, HX370 runtime, X99 worker, generic nodes).
- Expand hardware discovery capabilities.
