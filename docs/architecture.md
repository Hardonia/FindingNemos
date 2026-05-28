# FindingNemos Architecture

## Overview

FindingNemos is structured as a modular Zig system with clear boundaries between components. Each module has a single responsibility and communicates through well-defined types.

## Module Map

```
src/
├── main.zig                    CLI entry point
├── cli/
│   ├── cli.zig                 Argument parser
│   └── commands.zig            Command dispatch and implementations
├── core/
│   ├── app.zig                 Application context (allocator, config path)
│   ├── errors.zig              Unified error set with exit code mapping
│   ├── result.zig              Generic Result(T) type
│   ├── state.zig               State enums (Worker, Sandbox, Provider, Policy)
│   ├── ids.zig                 Sortable ID generation
│   ├── time.zig                Timestamp utilities with ISO-8601 formatting
│   ├── paths.zig               Platform-aware path resolution
│   └── json.zig                Bounded-buffer JSON writer
├── config/
│   ├── config.zig              Top-level config loader
│   ├── toml.zig                Minimal TOML parser
│   ├── schema.zig              Typed config struct with safe defaults
│   └── validation.zig          Multi-error validator
├── daemon/
│   ├── daemon.zig              Module root
│   ├── server.zig              Server config and planned endpoints
│   ├── protocol.zig            Request/Response types
│   ├── handlers.zig            Request dispatch
│   └── health.zig              Component health aggregation
├── supervisor/
│   ├── process.zig             Process handle with pid/lifecycle tracking
│   ├── worker.zig              Worker wrapper with restart metadata
│   ├── registry.zig            Fixed-capacity worker registry
│   ├── lifecycle.zig           State transition validation
│   ├── restart_policy.zig      Restart policies (disabled/manual/on_failure)
│   └── logs.zig                Log path construction
├── sandbox/
│   ├── sandbox.zig             Module root
│   ├── docker.zig              Docker availability detection
│   ├── openshell_compat.zig    OpenShell compatibility layer
│   ├── policy.zig              Sandbox-specific policy wrapper
│   ├── filesystem.zig          Filesystem isolation types
│   └── network.zig             Network isolation types
├── inference/
│   ├── provider.zig            Provider abstraction and factories
│   ├── router.zig              Deterministic model router
│   ├── model_pool.zig          Fixed-size provider collection
│   ├── local_ollama.zig        Ollama factory
│   ├── local_llamacpp.zig      llama.cpp factory
│   ├── local_vllm.zig          vLLM factory
│   ├── openai_compatible.zig   OpenAI-compatible factory
│   └── credentials.zig         Secret redaction and key detection
├── policy/
│   ├── policy.zig              Module root
│   ├── egress.zig              Egress policy engine
│   ├── ssrf.zig                SSRF validation
│   ├── allowlist.zig           Allowlist parsing
│   └── denials.zig             Denial records
├── telemetry/
│   ├── telemetry.zig           Module root
│   ├── system.zig              System snapshot (CPU, memory)
│   ├── gpu.zig                 GPU detection (stub)
│   ├── memory.zig              Memory probing (stub)
│   └── events.zig              Telemetry event types
└── proof/
    ├── proofpack.zig           Proofpack generation and serialization
    ├── evidence.zig            Evidence record types
    ├── audit_log.zig           Audit log entries
    └── export.zig              Export format types
```

## Data Flow

```
User CLI Input
    │
    ▼
cli.zig (parse args)
    │
    ▼
commands.zig (dispatch)
    │
    ├──▶ config/ (load + validate TOML)
    ├──▶ policy/ (check egress rules)
    ├──▶ inference/ (assess providers, route)
    ├──▶ supervisor/ (manage workers)
    ├──▶ daemon/ (health checks)
    ├──▶ telemetry/ (system snapshot)
    └──▶ proof/ (collect evidence, export)
    │
    ▼
stdout (human or JSON output)
    │
    ▼
exit code (0-10)
```

## Key Design Decisions

### No Global Mutable State

All state is passed explicitly through function parameters or struct fields. The `App` struct carries the allocator and config path through the command dispatch chain.

### Bounded Buffers

The JSON writer, ID generator, and path utilities use fixed-size stack buffers. No hidden heap allocation in hot paths.

### Fail Closed

The TOML parser rejects any input it cannot understand. The policy engine denies by default. Unknown states are reported as `unknown`, not assumed healthy.

### Composable Modules

Each module is independently testable. The CLI commands compose modules to implement behavior. No circular dependencies between modules.
