// SPDX-License-Identifier: Apache-2.0
// FindingNemos — restart policy

const std = @import("std");

pub const RestartPolicy = enum {
    disabled,
    manual,
    on_failure,

    pub fn label(self: RestartPolicy) []const u8 {
        return @tagName(self);
    }

    /// Should the supervisor restart based on this policy and the exit code?
    pub fn shouldRestart(self: RestartPolicy, exit_code: ?u8) bool {
        return switch (self) {
            .disabled => false,
            .manual => false,
            .on_failure => if (exit_code) |code| code != 0 else true,
        };
    }
};

// ---------------------------------------------------------------------------
test "disabled never restarts" {
    try std.testing.expect(!RestartPolicy.disabled.shouldRestart(1));
    try std.testing.expect(!RestartPolicy.disabled.shouldRestart(0));
}

test "manual never restarts" {
    try std.testing.expect(!RestartPolicy.manual.shouldRestart(1));
}

test "on_failure restarts on non-zero" {
    try std.testing.expect(RestartPolicy.on_failure.shouldRestart(1));
    try std.testing.expect(!RestartPolicy.on_failure.shouldRestart(0));
    try std.testing.expect(RestartPolicy.on_failure.shouldRestart(null));
}
