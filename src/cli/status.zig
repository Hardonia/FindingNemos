// SPDX-License-Identifier: Apache-2.0
const std = @import("std");

pub fn run(json: bool) !void {
    const stdout = std.io.getStdOut().writer();
    if (json) {
        try stdout.print("{{\"status\": \"degraded\", \"reason\": \"scaffold\"}}\n", .{});
    } else {
        try stdout.print("Status: degraded (scaffold)\n", .{});
    }
}
