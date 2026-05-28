// SPDX-License-Identifier: Apache-2.0
const std = @import("std");

pub const WorkerState = enum {
    unknown,
    configured,
    starting,
    running,
    healthy,
    degraded,
    stopping,
    stopped,
    failed,
};

pub const SandboxState = enum {
    unavailable,
    not_configured,
    configured,
    creating,
    running,
    degraded,
    stopped,
    failed,
};

pub const ProviderState = enum {
    unavailable,
    configured,
    reachable,
    degraded,
    failed,
};

pub const PolicyDecisionState = enum {
    allowed,
    denied,
    unknown,
    unsupported,
};

pub const DegradedState = enum {
    healthy,
    degraded,
    unavailable,
    unsupported,
    unknown,
};

pub const RuntimeState = struct {
    sandbox: SandboxState = .not_configured,
    daemon_healthy: bool = false,
};

pub const TelemetrySnapshot = struct {
    timestamp: i64,
    cpu_usage_pct: ?f32,
    memory_usage_bytes: ?u64,
    gpu_state: DegradedState,
};

pub const PolicyDecision = struct {
    state: PolicyDecisionState,
    reason: []const u8,
};

pub const DependencyCheck = struct {
    name: []const u8,
    state: DegradedState,
    message: []const u8,
};

pub const RouteTrace = struct {
    prompt_id: []const u8,
    selected_provider: ?[]const u8,
    reason: []const u8,
};

pub const ProofEvent = struct {
    event_id: []const u8,
    timestamp: i64,
    event_type: []const u8,
    details: []const u8,
};
