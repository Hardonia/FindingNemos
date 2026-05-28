# Configuration Reference

## Config File Location

Default: `~/.findingnemos/config.toml`

Override with: `--config <path>`

## Sections

### [runtime]

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| `version` | string | `"0.1.0"` | Config format version |
| `debug` | bool | `false` | Enable debug output |
| `log_level` | string | `"info"` | Log level: debug, info, warn, error |

### [daemon]

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| `enabled` | bool | `false` | Enable the daemon |
| `bind` | string | `"127.0.0.1"` | Bind address (Phase 2 HTTP) |
| `port` | int | `9100` | Port (1-65535) |

### [sandbox]

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| `runtime` | string | `"none"` | `none`, `docker`, or `openshell` |
| `image` | string | null | Container image (when runtime != none) |

### [policy]

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| `default` | string | `"deny"` | `allow` or `deny` |
| `allowlist` | string | null | Comma-separated allowed hosts |
| `denylist` | string | null | Comma-separated denied hosts |
| `block_private` | bool | `true` | Block RFC 1918 / link-local IPs |
| `block_ssrf` | bool | `true` | Block metadata / SSRF targets |

### [models]

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| `local_first` | bool | `true` | Prefer local providers in routing |
| `ollama_endpoint` | string | null | Ollama server URL |
| `llamacpp_endpoint` | string | null | llama.cpp server URL |
| `vllm_endpoint` | string | null | vLLM server URL |
| `openai_endpoint` | string | null | OpenAI-compatible API URL |
| `openai_key_env` | string | null | Env var name containing API key |

### [telemetry]

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| `enabled` | bool | `true` | Enable telemetry collection |
| `gpu_probe` | bool | `false` | Enable GPU detection (stub) |

### [proofpack]

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| `dir` | string | null | Proofpack output directory |
| `redact_secrets` | bool | `true` | Redact secrets in proofpacks |

## Validation

Run `findingnemos config validate --config <path>` to validate a config file.

Validation checks:
- TOML syntax correctness
- Known section names (warns on unknown)
- Port range (1-65535)
- Sandbox runtime values (none/docker/openshell)
- Policy default values (allow/deny)
- Security warnings (e.g., redact_secrets=false)
