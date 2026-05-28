// SPDX-License-Identifier: Apache-2.0
// FindingNemos — evidence collection

const std = @import("std");
const time = @import("../core/time.zig");

pub const EvidenceKind = enum {
    config_validation,
    dependency_check,
    worker_state,
    provider_state,
    policy_decision,
    route_trace,
    degraded_state,
    system_info,
};

pub const Evidence = struct {
    kind: EvidenceKind,
    component: []const u8,
    summary: []const u8,
    timestamp: i64,
    passed: bool,

    pub fn record(kind: EvidenceKind, component: []const u8, summary: []const u8, passed: bool) Evidence {
        return .{
            .kind = kind,
            .component = component,
            .summary = summary,
            .timestamp = time.epochSeconds(),
            .passed = passed,
        };
    }
};

// ---------------------------------------------------------------------------
test "evidence creation" {
    const e = Evidence.record(.config_validation, "config", "valid TOML", true);
    try std.testing.expect(e.passed);
    try std.testing.expect(e.timestamp > 0);
    try std.testing.expectEqualStrings("config", e.component);
}
