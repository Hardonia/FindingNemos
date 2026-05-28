<!-- SPDX-License-Identifier: Apache-2.0 -->

# FindingNemos Configuration

FindingNemos uses TOML for its configuration to ensure human readability and strong typed validation.

## Philosophy

- **Fail Closed**: If a configuration file is missing required sections, has contradictory rules, or is syntactically invalid, FindingNemos will refuse to start.
- **Explicit Definitions**: You must explicitly define network egress rules and provider priority.
- **Redaction**: Secrets (like provider API keys) should ideally be passed via the environment, but if present in the configuration, they are redacted in all system outputs and proofpacks.

## Main Configuration (`config.toml`)

By default, the configuration is loaded from `~/.findingnemos/config.toml`.

### Example

```toml
[runtime]
debug = false

[daemon]
port = 8080

[sandbox]
provider = "docker"

[telemetry]
enabled = true

[proofpack]
export_path = "/tmp/findingnemos/proofpacks"
```

## Validation

You can validate your configuration offline using the CLI:

```bash
findingnemos config validate --config ~/.findingnemos/config.toml
```
