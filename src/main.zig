// SPDX-License-Identifier: Apache-2.0
const std = @import("std");
const cli = @import("cli/cli.zig");
const version = @import("cli/version.zig");
const doctor = @import("cli/doctor.zig");
const status = @import("cli/status.zig");
const daemon = @import("daemon/daemon.zig");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const cmd = try cli.parseArgs(allocator);

    switch (cmd) {
        .version => try version.run(),
        .doctor => try doctor.run(),
        .status => try status.run(false), // would parse --json flag
        .daemon_run => try daemon.runDaemon(),
        else => {
            const stdout = std.io.getStdOut().writer();
            try stdout.print("Command not implemented yet in scaffold.\n", .{});
        },
    }
}

test {
    std.testing.refAllDecls(@This());
}
