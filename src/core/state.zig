// SPDX-License-Identifier: Apache-2.0
// FindingNemos — state enums and structs
//
// Deterministic state model for workers, sandboxes, providers, and policy.
// Every state is explicit — no hidden "unknown" masquerading as healthy.

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

    pub fn isTerminal(self: WorkerState) bool {
        return self == .stopped or self == .failed;
    }

    pub fn isAlive(self: WorkerState) bool {
        return self == .starting or self == .running or self == .healthy or self == .degraded;
    }

    pub fn label(self: WorkerState) []const u8 {
        return @tagName(self);
    }
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

    pub fn label(self: SandboxState) []const u8 {
        return @tagName(self);
    }
};

pub const ProviderState = enum {
    unavailable,
    configured,
    reachable,
    degraded,
    failed,

    pub fn label(self: ProviderState) []const u8 {
        return @tagName(self);
    }
};

pub const PolicyDecision = enum {
    allowed,
    denied,
    unknown,
    unsupported,

    pub fn label(self: PolicyDecision) []const u8 {
        return @tagName(self);
    }
};

pub const Availability = enum {
    available,
    unavailable,
    unknown,
    degraded,

    pub fn label(self: Availability) []const u8 {
        return @tagName(self);
    }
};

/// Runtime state snapshot persisted to ~/.findingnemos/state.json
pub const RuntimeState = struct {
    version: []const u8 = "0.1.0",
    workers: []const WorkerEntry = &.{},
    sandbox: SandboxState = .not_configured,
    docker: Availability = .unknown,
    openshell: Availability = .unknown,
    openclaw: Availability = .unknown,

    pub const WorkerEntry = struct {
        name: []const u8,
        state: WorkerState,
        pid: ?u32 = null,
        last_start_epoch: ?i64 = null,
        last_stop_epoch: ?i64 = null,
        exit_code: ?u8 = null,
    };
};

/// Degraded state record for proofpacks and operator output.
pub const DegradedState = struct {
    component: []const u8,
    reason: []const u8,
    severity: Severity,

    pub const Severity = enum { warning, critical };
};

/// Telemetry snapshot for system health reporting.
pub const TelemetrySnapshot = struct {
    timestamp_epoch: i64 = 0,
    cpu_count: ?u32 = null,
    memory_total_bytes: ?u64 = null,
    memory_available_bytes: ?u64 = null,
    gpu_available: Availability = .unknown,
    gpu_name: ?[]const u8 = null,
};

// ---------------------------------------------------------------------------
test "WorkerState transitions" {
    try std.testing.expect(WorkerState.stopped.isTerminal());
    try std.testing.expect(WorkerState.failed.isTerminal());
    try std.testing.expect(!WorkerState.running.isTerminal());
    try std.testing.expect(WorkerState.running.isAlive());
    try std.testing.expect(!WorkerState.stopped.isAlive());
}

test "state labels are non-empty" {
    try std.testing.expect(WorkerState.healthy.label().len > 0);
    try std.testing.expect(SandboxState.running.label().len > 0);
    try std.testing.expect(ProviderState.reachable.label().len > 0);
    try std.testing.expect(PolicyDecision.allowed.label().len > 0);
}
