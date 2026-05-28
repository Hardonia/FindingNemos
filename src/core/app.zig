// SPDX-License-Identifier: Apache-2.0
// FindingNemos — application-level context
//
// App struct carries the allocator, config path, and runtime references
// threaded through CLI commands and daemon handlers.

const std = @import("std");
const paths = @import("paths.zig");

pub const version = "0.1.0";
pub const name = "findingnemos";
pub const description = "Zig-first local AI substrate for governed agent execution";

pub const App = struct {
    allocator: std.mem.Allocator,
    config_path: ?[]const u8 = null,
    json_output: bool = false,

    pub fn init(allocator: std.mem.Allocator) App {
        return .{ .allocator = allocator };
    }
};
