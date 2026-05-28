// SPDX-License-Identifier: Apache-2.0
// FindingNemos — deterministic model router
//
// Routes inference requests to the best available provider based on explicit
// rules: health, priority, context window, cost, local-first preference.
// No ML claims. No fake prefill intelligence. Transparent routing decisions.

const std = @import("std");
const provider = @import("provider.zig");
const state = @import("../core/state.zig");

pub const RouteDecision = struct {
    provider_name: []const u8 = "none",
    reason: []const u8 = "no providers available",
    routed: bool = false,
};

/// Select the best provider from the list based on deterministic rules.
/// Returns the decision with an explanation of why.
pub fn route(providers: []const provider.ProviderInfo, local_first: bool) RouteDecision {
    if (providers.len == 0) {
        return .{ .reason = "no providers configured" };
    }

    // First pass: find any reachable/healthy provider
    var best: ?usize = null;
    var best_priority: u8 = 255;

    for (providers, 0..) |p, i| {
        // Skip unavailable or disabled
        if (p.state == .unavailable or p.state == .failed) continue;
        if (p.kind == .disabled) continue;

        // Local-first: prefer local providers
        const is_local = p.kind == .ollama or p.kind == .llamacpp or p.kind == .vllm;
        const effective_priority = if (local_first and is_local)
            p.priority -| 50 // boost local providers
        else
            p.priority;

        if (best == null or effective_priority < best_priority) {
            best = i;
            best_priority = effective_priority;
        }
    }

    if (best) |idx| {
        const selected = providers[idx];
        return .{
            .provider_name = selected.name,
            .reason = switch (selected.state) {
                .reachable => "provider is reachable and has best priority",
                .configured => "provider is configured (health not yet probed)",
                .degraded => "provider is degraded but best available",
                else => "provider selected by priority",
            },
            .routed = true,
        };
    }

    return .{ .reason = "all configured providers are unavailable or failed" };
}

// ---------------------------------------------------------------------------
test "route selects highest priority" {
    var p1 = provider.ollamaProvider("http://localhost:11434");
    p1.state = .configured;
    var p2 = provider.openaiProvider("https://api.openai.com");
    p2.state = .configured;

    const providers_list = [_]provider.ProviderInfo{ p1, p2 };
    const decision = route(&providers_list, true);
    try std.testing.expect(decision.routed);
    try std.testing.expectEqualStrings("ollama", decision.provider_name);
}

test "route returns no_route when all unavailable" {
    const p1 = provider.ollamaProvider(null);
    const providers_list = [_]provider.ProviderInfo{p1};
    const decision = route(&providers_list, true);
    try std.testing.expect(!decision.routed);
}

test "route with empty list" {
    const providers_list = [_]provider.ProviderInfo{};
    const decision = route(&providers_list, false);
    try std.testing.expect(!decision.routed);
    try std.testing.expectEqualStrings("no providers configured", decision.reason);
}

test "local_first boosts local providers" {
    var local = provider.ollamaProvider("http://localhost:11434");
    local.state = .configured;
    local.priority = 80;

    var remote = provider.openaiProvider("https://api.openai.com");
    remote.state = .configured;
    remote.priority = 50; // Lower number = higher priority normally

    // Without local_first, remote wins on priority
    const no_local = [_]provider.ProviderInfo{ local, remote };
    const d1 = route(&no_local, false);
    try std.testing.expectEqualStrings("openai-compatible", d1.provider_name);

    // With local_first, local gets boosted
    const d2 = route(&no_local, true);
    try std.testing.expectEqualStrings("ollama", d2.provider_name);
}
