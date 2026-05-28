// SPDX-License-Identifier: Apache-2.0
// FindingNemos — inference provider abstraction
//
// Defines the provider state model and health-check interface.
// Actual network calls are stub implementations for Phase 1 —
// they check config presence and endpoint format but do not make
// real HTTP requests unless explicitly invoked via CLI commands.

const std = @import("std");
const state = @import("../core/state.zig");

pub const ProviderKind = enum {
    ollama,
    llamacpp,
    vllm,
    openai_compatible,
    disabled,

    pub fn label(self: ProviderKind) []const u8 {
        return @tagName(self);
    }
};

pub const ProviderInfo = struct {
    kind: ProviderKind,
    name: []const u8,
    endpoint: ?[]const u8 = null,
    state: state.ProviderState = .unavailable,
    health_path: []const u8 = "/health",
    models_path: []const u8 = "/v1/models",
    max_context: ?u32 = null,
    priority: u8 = 100,
    cost_hint: CostHint = .unknown,

    pub const CostHint = enum { free, cheap, moderate, expensive, unknown };
};

/// Check if a provider endpoint is configured (non-null, non-empty).
pub fn isConfigured(info: ProviderInfo) bool {
    if (info.kind == .disabled) return false;
    const ep = info.endpoint orelse return false;
    return ep.len > 0;
}

/// Determine provider state from configuration alone (no network).
/// Real health probing is deferred to CLI commands that explicitly request it.
pub fn assessConfig(info: *ProviderInfo) void {
    if (info.kind == .disabled) {
        info.state = .unavailable;
        return;
    }
    if (!isConfigured(info.*)) {
        info.state = .unavailable;
        return;
    }
    // Endpoint is configured but we haven't probed yet
    info.state = .configured;
}

/// Build a ProviderInfo for Ollama from config values.
pub fn ollamaProvider(endpoint: ?[]const u8) ProviderInfo {
    return .{
        .kind = .ollama,
        .name = "ollama",
        .endpoint = endpoint,
        .health_path = "/api/tags",
        .models_path = "/api/tags",
        .cost_hint = .free,
        .priority = 10,
    };
}

/// Build a ProviderInfo for llama.cpp from config values.
pub fn llamacppProvider(endpoint: ?[]const u8) ProviderInfo {
    return .{
        .kind = .llamacpp,
        .name = "llama.cpp",
        .endpoint = endpoint,
        .health_path = "/health",
        .models_path = "/v1/models",
        .cost_hint = .free,
        .priority = 20,
    };
}

/// Build a ProviderInfo for vLLM from config values.
pub fn vllmProvider(endpoint: ?[]const u8) ProviderInfo {
    return .{
        .kind = .vllm,
        .name = "vllm",
        .endpoint = endpoint,
        .health_path = "/health",
        .models_path = "/v1/models",
        .cost_hint = .free,
        .priority = 30,
    };
}

/// Build a ProviderInfo for OpenAI-compatible endpoint from config values.
pub fn openaiProvider(endpoint: ?[]const u8) ProviderInfo {
    return .{
        .kind = .openai_compatible,
        .name = "openai-compatible",
        .endpoint = endpoint,
        .health_path = "/v1/models",
        .models_path = "/v1/models",
        .cost_hint = .moderate,
        .priority = 100,
    };
}

// ---------------------------------------------------------------------------
test "isConfigured checks endpoint" {
    const p1 = ollamaProvider("http://localhost:11434");
    try std.testing.expect(isConfigured(p1));

    const p2 = ollamaProvider(null);
    try std.testing.expect(!isConfigured(p2));
}

test "assessConfig sets state correctly" {
    var p = ollamaProvider("http://localhost:11434");
    assessConfig(&p);
    try std.testing.expectEqual(state.ProviderState.configured, p.state);

    var p2 = ollamaProvider(null);
    assessConfig(&p2);
    try std.testing.expectEqual(state.ProviderState.unavailable, p2.state);
}

test "disabled provider is unavailable" {
    var p = ProviderInfo{
        .kind = .disabled,
        .name = "disabled",
    };
    assessConfig(&p);
    try std.testing.expectEqual(state.ProviderState.unavailable, p.state);
}
