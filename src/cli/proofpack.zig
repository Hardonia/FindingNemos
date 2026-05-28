// SPDX-License-Identifier: Apache-2.0
const std = @import("std");

pub fn exportPack(out_path: []const u8) !void {
    const stdout = std.io.getStdOut().writer();
    try stdout.print("Exporting proofpack to {s}...\n", .{out_path});
}
