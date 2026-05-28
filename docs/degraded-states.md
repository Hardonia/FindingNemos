<!-- SPDX-License-Identifier: Apache-2.0 -->

# FindingNemos Degraded States

FindingNemos relies on explicit modeling of hardware and software dependencies. When a dependency is unavailable, the subsystem relying on it enters an explicit `degraded` state rather than failing silently or pretending the capability exists.

## Core States

FindingNemos uses explicit enums to represent dependency health:
- `available` / `healthy`
- `degraded`
- `unavailable`
- `unsupported`
- `unknown`

## Common Degraded Scenarios

### GPU Telemetry Unavailable
If `nvidia-smi` or ROCm equivalent tools are missing on a node configured as a GPU worker, the node will not crash. Instead, its telemetry subsystem will report GPU state as `unavailable` or `degraded`, and the router will avoid assigning GPU-bound tasks to it if other constraints apply.

### Docker / Sandbox Unavailable
If a local worker is configured to use Docker for sandboxing, but the Docker daemon is unreachable, the sandbox state becomes `unavailable`. Policy checks will prevent tasks requiring sandboxes from running.

### Provider Unreachable
If a configured local model (e.g., Ollama at `http://localhost:11434`) is offline, the provider state becomes `degraded`. The router will bypass this provider and select the next available candidate based on configured priorities.

## Operator Output
When querying the system status via `findingnemos status --json`, all degraded states are clearly marked. Proofpacks generated during a degraded window will explicitly log which dependencies were missing to ensure the audit trail is accurate.
