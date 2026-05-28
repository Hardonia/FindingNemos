// SPDX-License-Identifier: Apache-2.0
const std = @import("std");

pub fn runDaemon() !void {
    // Daemon loop scaffold.
    // In the future, this might run an HTTP server or a JSON-over-stdin protocol.
    const stdout = std.io.getStdOut().writer();
    try stdout.print("Daemon started. Protocol: JSON-over-stdin (HTTP planned for future)\n", .{});
}
