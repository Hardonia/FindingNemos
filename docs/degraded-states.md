# Degraded States

## Philosophy

FindingNemos never hides missing capabilities. Every component explicitly reports its state. Unknown is a valid, honest state — it means "we haven't checked yet," not "it's probably fine."

## State Enums

### Worker States

| State | Meaning |
|-------|---------|
| `unknown` | State has not been determined |
| `configured` | Worker is defined in config but not started |
| `starting` | Worker process is being spawned |
| `running` | Worker process has been spawned (pid captured) |
| `healthy` | Worker is running and responding (future health checks) |
| `degraded` | Worker is running but not fully functional |
| `stopping` | Worker is being asked to stop |
| `stopped` | Worker has exited cleanly (exit code 0) |
| `failed` | Worker has exited with non-zero exit code |

### Sandbox States

| State | Meaning |
|-------|---------|
| `unavailable` | No container runtime detected |
| `not_configured` | Runtime exists but sandbox not configured |
| `configured` | Sandbox config present, not yet created |
| `creating` | Container is being created |
| `running` | Container is running |
| `degraded` | Container is running with issues |
| `stopped` | Container has been stopped |
| `failed` | Container creation or operation failed |

### Provider States

| State | Meaning |
|-------|---------|
| `unavailable` | No endpoint configured or provider disabled |
| `configured` | Endpoint configured, health not probed |
| `reachable` | Health probe succeeded |
| `degraded` | Endpoint responding with errors |
| `failed` | Health probe failed |

### Policy Decisions

| Decision | Meaning |
|----------|---------|
| `allowed` | Request permitted by policy |
| `denied` | Request blocked by policy |
| `unknown` | Policy could not determine (missing data) |
| `unsupported` | Check not supported for this request type |

## Degraded State Handling

When a component is degraded:

1. The state is reported honestly in `status` and `doctor` output
2. The degraded component is included in proofpack evidence
3. Commands that depend on the component return exit code 5 (degraded)
4. The operator is informed of what's degraded and why
5. Other components continue to function where possible
