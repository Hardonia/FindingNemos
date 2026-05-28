<!-- SPDX-License-Identifier: Apache-2.0 -->

# FindingNemos Threat Model

## Host Compromise
If the underlying host OS is compromised, FindingNemos provides no guarantees. The host controls the proofpacks, the configuration, and the daemon.

## Sandbox Escape
FindingNemos utilizes worker sandboxing (e.g., Docker). A sandbox escape would allow a malicious model or agent code to impact the host. FindingNemos relies on the isolation properties of the underlying container runtime and mitigates impact by running workers with minimal privileges.

## Provider Key Leakage
Keys are redacted before any state logging, output formatting, or proofpack export. If the daemon process memory is dumped by a privileged user, keys could be exposed, but they are protected from log aggregation and sandbox environments.

## Runaway Worker/Process
Supervised workers have defined resource limits and lifecycle hooks. If a worker goes runaway, the supervisor will terminate it via pid or container boundary.

## Malicious Model Endpoint
FindingNemos guards against malicious model responses (e.g., prompt injections trying to exfiltrate data) via its strict default-deny egress policy and SSRF protections for internal metadata endpoints.

## Degraded States
FindingNemos does not fail open when security controls or dependencies are missing. If a required sandbox runtime is unavailable, the daemon will not run un-sandboxed code. It will report `unavailable` and deny execution.
