<!-- SPDX-License-Identifier: Apache-2.0 -->

# FindingNemos Operator Model

FindingNemos is built around the concept of "Operator Truth". The operator of the system—the human or control-plane orchestrating the local AI lab—must be able to implicitly trust the runtime layer to report its state accurately.

## No Theatre
FindingNemos will not pretend to have a capability it lacks. If an operator requests GPU telemetry and the local node does not have `nvidia-smi` or equivalent tooling, FindingNemos will report the state as `degraded` or `unsupported`. It will never silently fail or fake success.

## Explicit Validation
All configuration paths must fail closed. If the configuration is malformed, missing, or contradictory, the daemon will refuse to start and will emit a deterministic error code.

## The Proofpack
All interactions—policy checks, routing decisions, and state transitions—can be exported as a "Proofpack". A Proofpack is a deterministic, redacted bundle (JSON and Markdown) that serves as an irrefutable audit log of what happened during an execution window.

## Local First
Operators are expected to run FindingNemos across their hardware (e.g., Radxa control plane, HX370 runtime, X99 worker). Configuration assumes local models are prioritized and the egress policy defaults to denying outbound network requests.
