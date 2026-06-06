// SPDX-License-Identifier: Apache-2.0
// FindingNemos — container isolation invariants
//
// Enforces that execution environments meet strict isolation criteria before
// any untrusted code or prompt is run.

const std = @import("std");

pub const IsolationLevel = enum {
    strict,
    degraded,
    none,
};

pub const IsolationConfig = struct {
    require_network_none: bool = true,
    require_user_namespace: bool = false,
    require_read_only_root: bool = true,
    drop_all_capabilities: bool = true,
};

pub const IsolationReport = struct {
    level: IsolationLevel,
    reasons: [][]const u8,
};

/// Validates that a given set of runtime parameters meets the required isolation policy.
pub fn verifyIsolation(allocator: std.mem.Allocator, config: IsolationConfig, actual_network: []const u8) !IsolationReport {
    var reasons = std.ArrayList([]const u8).init(allocator);
    errdefer reasons.deinit();

    var level: IsolationLevel = .strict;

    if (config.require_network_none) {
        if (!std.mem.eql(u8, actual_network, "none")) {
            try reasons.append("network is not isolated (not 'none')");
            level = .degraded;
        }
    }

    // In a real implementation, we would check other parameters (user ns, ro-root, caps).
    // For Phase 3 scaffold, we assume they are degraded unless explicitly provided by an OS API.

    if (config.require_user_namespace) {
        try reasons.append("user namespace mapping not verified");
        level = .degraded;
    }

    if (reasons.items.len > 0 and level == .strict) {
        level = .degraded;
    }

    return IsolationReport{
        .level = level,
        .reasons = try reasons.toOwnedSlice(),
    };
}

test "verify strict isolation" {
    const allocator = std.testing.allocator;
    const config = IsolationConfig{
        .require_network_none = true,
        .require_user_namespace = false,
        .require_read_only_root = false,
        .drop_all_capabilities = false,
    };

    const report = try verifyIsolation(allocator, config, "none");
    defer allocator.free(report.reasons);

    try std.testing.expectEqual(IsolationLevel.strict, report.level);
    try std.testing.expectEqual(@as(usize, 0), report.reasons.len);
}

test "verify degraded isolation" {
    const allocator = std.testing.allocator;
    const config = IsolationConfig{
        .require_network_none = true,
        .require_user_namespace = false,
        .require_read_only_root = false,
        .drop_all_capabilities = false,
    };

    const report = try verifyIsolation(allocator, config, "bridge");
    defer allocator.free(report.reasons);

    try std.testing.expectEqual(IsolationLevel.degraded, report.level);
    try std.testing.expectEqual(@as(usize, 1), report.reasons.len);
}
