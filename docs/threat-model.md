# Threat Model

## Scope

This threat model covers the FindingNemos runtime, including the CLI, daemon, process supervisor, inference routing, policy engine, and proofpack system. It does NOT cover threats to the host OS, hardware, or upstream model providers.

## Threat Categories

### 1. Host Compromise

**Risk:** An attacker gains access to the host machine running FindingNemos.

**Mitigations:**
- FindingNemos does not require root/admin privileges
- Worker processes run with the same privileges as the FindingNemos user
- Config files should be readable only by the operator (`chmod 600`)
- Proofpack export creates evidence of runtime state for forensic review

**Gaps (Phase 1):**
- No filesystem integrity monitoring
- No runtime attestation
- No tamper detection on config files

### 2. Sandbox Escape

**Risk:** A sandboxed agent process escapes container isolation.

**Mitigations:**
- Phase 1 does not create containers — no false sense of security
- Sandbox state honestly reports `unavailable` or `not_configured`
- Docker presence is detected but not claimed as isolation

**Gaps (Phase 1):**
- No actual sandbox creation
- No seccomp/Landlock enforcement
- No user namespace isolation
- These are Phase 2+ features

### 3. Provider Key Leakage

**Risk:** API keys are exposed in logs, config, proofpacks, or output.

**Mitigations:**
- Config stores env var names, not raw keys
- `credentials.zig` redacts all secret values in output
- `looksLikeKey()` heuristic detects common key patterns as safety net
- Proofpack export enforces `redact_secrets = true` by default

### 4. Prompt / Log Leakage

**Risk:** Sensitive prompts or model responses are logged or exported.

**Mitigations:**
- Prompts are not logged by default
- Proofpacks do not include prompt content
- Route decisions log provider name and reason, not prompt text

**Gaps:**
- Worker stdout/stderr capture may contain prompt data
- No content classification or filtering

### 5. Runaway Worker / Process

**Risk:** A supervised worker consumes excessive resources or runs indefinitely.

**Mitigations:**
- Restart policy defaults to `disabled`
- Workers tracked by pid with start/stop timestamps
- Exit codes captured and reported
- Startup timeout planned

**Gaps (Phase 1):**
- No resource limits (CPU, memory, pids)
- No automatic timeout
- No OOM killer integration

### 6. Malicious Model Endpoint

**Risk:** A configured model endpoint returns harmful content or exploits the client.

**Mitigations:**
- Egress policy controls which endpoints are reachable
- SSRF validation blocks metadata/private endpoints
- Provider health probes are read-only (GET requests)

**Gaps:**
- No response validation or sanitization
- No content safety filtering
- No TLS certificate pinning

### 7. Policy Bypass

**Risk:** An agent or operator circumvents egress policy controls.

**Mitigations:**
- Policy engine is checked before any outbound request
- SSRF blocks cannot be silently disabled (config validation warns)
- Private IP blocking is on by default
- Policy decisions are logged with reasons

**Gaps:**
- No network-level enforcement (iptables/nftables)
- Policy is application-level only in Phase 1
- DNS rebinding attacks not mitigated

### 8. Docker / OpenShell Unavailable

**Risk:** Expected container runtime is not available.

**Mitigations:**
- FindingNemos reports `unavailable`/`unknown` honestly
- CLI commands degrade gracefully instead of panicking
- No security claims are made when runtime is absent

### 9. Degraded Local Hardware

**Risk:** GPU, memory, or storage is insufficient or unavailable.

**Mitigations:**
- Telemetry reports actual CPU count
- GPU detection returns `unknown` (not faked)
- Memory probing returns `null` when unavailable
- Doctor command aggregates all component health
