<!-- SPDX-License-Identifier: Apache-2.0 -->

# Local Lab Operator Guide

FindingNemos is designed to govern execution across various classes of hardware in a local AI lab.

## Hardware Profiles

While FindingNemos gathers telemetry dynamically, operators can explicitly configure node profiles to establish expected baseline capabilities. FindingNemos does NOT assume a capability exists unless its dependencies check out.

- **`radxa_control_plane`**: Low-power node. Expected to run the FindingNemos daemon and router. GPU likely `unavailable`.
- **`hx370_runtime`**: Efficient local runtime. Might act as an eGPU candidate or run lighter local models via `llama.cpp`.
- **`x99_worker` / `epyc_worker`**: Heavy local worker hosts. Expected to run Docker sandboxes and supervise intense tasks.
- **`gpu_node` (P40 / V100 / RTX 3060)**: Nodes expected to run `vLLM` or `Ollama`. FindingNemos will actively check for `nvidia-smi` or ROCm tooling. If the tooling is missing, the GPU state is explicitly marked `degraded` or `unsupported`.

## Degraded Local Hardware
FindingNemos will never hard-fail just because a host lacks a GPU. It will simply exclude GPU-bound tasks from that host's capabilities and report the truth to the operator.
