<!-- SPDX-License-Identifier: Apache-2.0 -->

# Sandbox Mechanics

FindingNemos delegates untrusted code execution to external runtimes (primarily Docker or Podman) to ensure memory isolation and filesystem boundaries.

## Sandbox Discovery
On startup, FindingNemos explicitly tests for available runtimes:
- Checks `docker info`.
- Checks `podman info`.
- Checks cgroups v2 availability.

If a runtime is not found, the sandbox capability is marked `unavailable`. FindingNemos will refuse to run untrusted agent actions outside of a sandboxed boundary.

## Resource Limits
When spawning a sandbox, FindingNemos configures hard limits on:
- CPU
- Memory
- Network Egress (by default, none, unless the policy explicitly allows a route)
- PIDs

## OpenShell Compat Layer
If requested, FindingNemos can emulate or integrate with NVIDIA OpenShell sandboxes. It does this by reading the OpenShell API contract and formatting execution commands identically, serving as a drop-in deterministic supervisor for an OpenShell lab.
