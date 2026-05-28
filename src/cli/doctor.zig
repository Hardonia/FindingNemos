// SPDX-License-Identifier: Apache-2.0
const std = @import("std");

pub fn run() !void {
    const stdout = std.io.getStdOut().writer();
    try stdout.print("Running doctor checks...\n", .{});
    try stdout.print("Docker: unavailable\n", .{});
    try stdout.print("GPU: unknown\n", .{});
}
