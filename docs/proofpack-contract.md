<!-- SPDX-License-Identifier: Apache-2.0 -->

# FindingNemos Proofpack Contract

A Proofpack is a deterministic, point-in-time export of the FindingNemos substrate state, policy decisions, and audit trail. It is designed to provide operators with irrefutable evidence of what occurred during an agent's execution window.

## Required Contents

Every Proofpack must contain:
1. **FindingNemos Version**: The version of the runtime that generated the pack.
2. **Runtime Timestamp**: The exact time of generation.
3. **Config Validation Summary**: A snapshot of the active (and redacted) configuration used during execution.
4. **Dependency Checks**: An explicit listing of all hardware and software dependencies and their states (`available`, `degraded`, `unavailable`).
5. **Worker States**: The final known states of all supervised worker processes.
6. **Provider States**: The health and status of all configured model providers.
7. **Policy Decisions**: A log of all egress requests made, and whether they were allowed or denied.
8. **Route Traces**: (If applicable) The paths taken by prompts to various providers.
9. **Redaction Guarantee**: All raw secrets must be scrubbed (`[REDACTED]`).

## Formats

Proofpacks are generated in two formats:
- `proofpack.json`: Machine-readable artifact.
- `proofpack.md`: Human-readable summary for operator review.

## Command

```bash
findingnemos proofpack export --out <path>
```
