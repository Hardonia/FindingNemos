// SPDX-License-Identifier: Apache-2.0
// FindingNemos — result type helpers
//
// Generic Result(T) for operations that can fail with an Error plus
// diagnostic context. Avoids losing error detail in long call chains.

const errors = @import("errors.zig");

/// A result carrying either a value or an error with optional context.
pub fn Result(comptime T: type) type {
    return struct {
        value: ?T = null,
        err: ?errors.Error = null,
        context: ?[]const u8 = null,

        const Self = @This();

        pub fn ok(val: T) Self {
            return .{ .value = val };
        }

        pub fn fail(e: errors.Error, ctx: ?[]const u8) Self {
            return .{ .err = e, .context = ctx };
        }

        pub fn isOk(self: Self) bool {
            return self.value != null;
        }

        pub fn unwrap(self: Self) errors.Error!T {
            if (self.value) |v| return v;
            return self.err orelse error.InvariantViolation;
        }
    };
}

// ---------------------------------------------------------------------------
const std = @import("std");

test "Result ok path" {
    const r = Result(u32).ok(42);
    try std.testing.expect(r.isOk());
    try std.testing.expectEqual(@as(u32, 42), try r.unwrap());
}

test "Result fail path" {
    const r = Result(u32).fail(error.InvalidConfig, "bad toml");
    try std.testing.expect(!r.isOk());
    try std.testing.expectEqual(r.context.?, "bad toml");
    try std.testing.expectError(error.InvalidConfig, r.unwrap());
}
