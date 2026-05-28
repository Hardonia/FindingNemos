// SPDX-License-Identifier: Apache-2.0
// FindingNemos — CLI entry point
//
// The findingnemos binary. Parses arguments, dispatches to commands,
// and exits with a deterministic exit code.

const std = @import("std");
const cli = @import("cli/cli.zig");
const commands = @import("cli/commands.zig");

pub fn main(init: std.process.Init) !u8 {
    const allocator = init.arena.allocator();

    var args_list = std.ArrayList([:0]const u8).empty;
    var arg_it = init.args.iterate();
    while (arg_it.next()) |arg| {
        // arg from iterate() might be []const u8 or [:0]const u8.
        // Assuming it's [:0]const u8 for now.
        try args_list.append(allocator, arg);
    }

    const args = args_list.items;

    const parsed = cli.parse(args);
    return commands.dispatch(parsed);
}
