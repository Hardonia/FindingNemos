<!-- SPDX-License-Identifier: Apache-2.0 -->

# FindingNemos Architecture

FindingNemos is a Zig-first local AI substrate. It is designed to govern and supervise execution across a local AI lab's hardware.

## Core Principles

1. **Zig Core**: The daemon, CLI, config parser, worker supervisor, and policy checking engine are written entirely in Zig to guarantee memory safety, predictable performance, and deterministic state transitions.
2. **Explicit Operator Truth**: FindingNemos never fakes its capabilities. If a hardware component, model, or driver is unavailable, it reports the state as explicitly degraded or unsupported.
3. **Fail Closed**: Security and policy engines default to denying actions.

## Major Subsystems

### `src/cli/`
Handles user commands (`findingnemos doctor`, `findingnemos worker start`, etc.) and returns structured output (JSON when requested).

### `src/daemon/`
The local control plane that supervises worker processes, maintains persistent state, and handles API requests for agent routing and task execution.

### `src/supervisor/`
Manages the lifecycle of local workers. Captures standard output, handles restarts based on policy, and explicitly models worker state (running, degraded, failed, stopped).

### `src/inference/`
Deterministically routes model prompts based on configured priorities, context length, cost, and explicit health checks. Supports Ollama, vLLM, llama.cpp, and generic OpenAI-compatible endpoints.

### `src/policy/`
Applies egress rules and SSRF protections. Every network request made by the agent/sandbox must pass policy validation before execution.

### `src/telemetry/`
Gathers host system metrics (CPU, Memory, GPU) without assuming the presence of specific drivers or tools. Missing tools result in explicit `degraded` or `unsupported` labels.

### `src/proof/`
Exports redacted, deterministic proofpacks representing the total state of the runtime, policy decisions, and output to serve as an irrefutable audit log.
