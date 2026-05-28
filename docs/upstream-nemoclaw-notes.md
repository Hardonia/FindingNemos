<!-- SPDX-License-Identifier: Apache-2.0 -->

# Upstream NemoClaw Notes

FindingNemos originated as a fork of the NVIDIA NemoClaw project (Apache 2.0). However, it is an independent, Zig-first project.

## Retained Architectural Inspiration
- The concept of a governed, sandboxed local AI agent execution environment.
- The separation of the control plane and the sandboxed worker execution.
- Egress network policy controls.

## Intentional Deviations
- **Zig First**: FindingNemos replaces the upstream Node.js/TypeScript core with Zig to ensure deterministic memory management, easy cross-platform binaries, and minimal runtime footprint.
- **No Theatre**: We explicitly reject faking capabilities. Upstream features that simulate GPU support, OpenShell parity, or production readiness have been stripped out. 
- **Proofpack Export**: FindingNemos introduces the concept of an irrefutable, redacted Proofpack to serve as a verifiable audit log.

## License and Attribution
FindingNemos retains the Apache 2.0 license. Where upstream files are preserved or heavily adapted, the original NVIDIA copyright notices are retained in accordance with the Apache 2.0 license obligations.
