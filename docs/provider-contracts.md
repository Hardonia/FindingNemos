<!-- SPDX-License-Identifier: Apache-2.0 -->

# Provider Contracts

FindingNemos implements explicit health and routing contracts for model providers. It does not fake intelligence or pretend to know how to route to a model that is unavailable.

## Health Checks
Each provider type must implement a deterministic health check:
- **Ollama**: Queries `/api/tags`.
- **vLLM / OpenAI-Compatible**: Queries `/v1/models`.
- **llama.cpp**: Queries the configured health endpoint.

If an endpoint fails to respond or returns an error, the provider's state becomes `degraded` and the router will avoid assigning tasks to it.

## The Router
The router relies strictly on:
1. Provider health.
2. Configured static priority.
3. Explicit `enabled: true/false` flags.

There is no "magic" ML routing. The router emits a `RouteTrace` indicating exactly why a provider was chosen (or why a prompt was rejected if `no_route_available`).
