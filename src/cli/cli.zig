// SPDX-License-Identifier: Apache-2.0
const std = @import("std");
const commands = @import("commands.zig");

pub fn parseArgs(allocator: std.mem.Allocator) !commands.Command {
    _ = allocator;
    // Scaffold implementation
    // Normally would parse std.process.argsAlloc
    return .version;
}
