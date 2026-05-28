# Security Policy

## Supported Versions

Currently, FindingNemos is in its initial scaffold phase and is not production-ready.

| Version | Supported          |
| ------- | ------------------ |
| 0.1.x   | :white_check_mark: |
| < 0.1.0 | :x:                |

## Reporting a Vulnerability

Please report security vulnerabilities by creating an issue labeled `security` or reaching out to the maintainers directly if a private disclosure method is established.

## Security Model
FindingNemos enforces an explicit "Operator Truth" model. It will never silently leak raw API keys into logs or proofpacks. Egress network policy requests are strictly denied by default. Server-Side Request Forgery (SSRF) checks are always enabled for outbound API connections.
