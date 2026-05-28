// SPDX-License-Identifier: Apache-2.0
const std = @import("std");

pub fn list() !void {
    const stdout = std.io.getStdOut().writer();
    try stdout.print("Workers:\n(none configured)\n", .{});
}

pub fn start(name: []const u8, cmd: []const u8) !void {
    const stdout = std.io.getStdOut().writer();
    try stdout.print("Starting worker {s} with cmd {s}...\n", .{name, cmd});
}

pub fn stop(name: []const u8) !void {
    const stdout = std.io.getStdOut().writer();
    try stdout.print("Stopping worker {s}...\n", .{name});
}

pub fn logs(name: []const u8) !void {
    const stdout = std.io.getStdOut().writer();
    try stdout.print("Logs for {s}: (unavailable)\n", .{name});
}
