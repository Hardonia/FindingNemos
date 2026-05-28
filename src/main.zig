// SPDX-License-Identifier: Apache-2.0
// FindingNemos — CLI entry point
//
// The findingnemos binary. Parses arguments, dispatches to commands,
// and exits with a deterministic exit code.

const std = @import("std");
const cli = @import("cli/cli.zig");
const commands = @import("cli/commands.zig");

pub fn main() u8 {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();

    const args = std.process.argsAlloc(arena.allocator()) catch {
        const w = std.io.getStdErr().writer();
        w.print("error: could not read arguments\n", .{}) catch {};
        return 10;
    };

    const parsed = cli.parse(args);
    return commands.dispatch(parsed);
}
