# Security Policy

## Reporting Vulnerabilities

If you discover a security vulnerability in FindingNemos, please report it responsibly.

**Email:** [security contact to be established]

**Do NOT:**
- Open a public GitHub issue for security vulnerabilities
- Post vulnerability details in discussions or social media before a fix is available

**Do:**
- Provide a clear description of the vulnerability
- Include steps to reproduce if possible
- Allow reasonable time for a fix before public disclosure

## Security Model

FindingNemos follows a defense-in-depth approach:

### Secrets Handling

- **Never store raw API keys in config files.** Config references environment variable names only.
- **Never log, export, or display raw secret values.** All secret output is redacted.
- **Credential redaction is enabled by default** and should not be disabled in production.
- The `looksLikeKey()` heuristic detects common key patterns (sk-*, nvapi-*, hf_*) as a safety net.

### Egress Policy

- **Deny-by-default** is the recommended and default policy.
- **SSRF protection** blocks cloud metadata endpoints (169.254.169.254), localhost, and Kubernetes internal DNS.
- **Private IP blocking** prevents requests to RFC 1918, link-local, and loopback ranges.
- Policy decisions are logged with reasons for operator auditability.

### Process Isolation

- Workers run as child processes with captured stdout/stderr.
- **Restart policy defaults to `disabled`** — no automatic restarts unless explicitly configured.
- Process supervision does not grant elevated privileges.

### Container Sandboxing

- **Phase 1 does not implement container sandboxing.** The sandbox module detects Docker/OpenShell presence but does not create containers.
- FindingNemos does not claim sandbox security unless a verified runtime is configured and probed.
- Docker presence alone does not imply security — container isolation depends on kernel capabilities, seccomp profiles, user namespaces, and runtime configuration.

### What We Do NOT Claim

- GPU scheduling security (not implemented)
- Network namespace isolation (requires container runtime)
- Landlock/seccomp enforcement (requires verified runtime delegation)
- Protection against malicious model weights
- Protection against prompt injection (application-layer concern)

## Supported Versions

| Version | Supported |
|---------|-----------|
| 0.1.x   | Development scaffold — no security guarantees |

## Security Invariants

These invariants must be maintained across all changes:

1. No raw API key values in logs, proofpacks, status output, config files, or test fixtures
2. Egress policy defaults to deny
3. SSRF validation cannot be silently disabled
4. Process supervisor does not escalate privileges
5. Proofpack export redacts all secret values by default
6. Unknown dependency state is reported as `unknown`, never faked as `available`
