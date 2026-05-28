// SPDX-License-Identifier: Apache-2.0
// FindingNemos — audit log

const time = @import("../core/time.zig");

pub const AuditEntry = struct {
    timestamp: i64,
    action: []const u8,
    actor: []const u8, // "operator", "system", "policy"
    detail: []const u8,
};

pub fn entry(action: []const u8, actor: []const u8, detail: []const u8) AuditEntry {
    return .{
        .timestamp = time.epochSeconds(),
        .action = action,
        .actor = actor,
        .detail = detail,
    };
}
