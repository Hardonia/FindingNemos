// SPDX-License-Identifier: Apache-2.0
const std = @import("std");

pub fn run() !void {
    const stdout = std.io.getStdOut().writer();
    try stdout.print("FindingNemos 0.1.0\n", .{});
}
