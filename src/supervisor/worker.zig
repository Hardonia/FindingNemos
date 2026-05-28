// SPDX-License-Identifier: Apache-2.0
const std = @import("std");
const state = @import("../core/state.zig");

pub const Worker = struct {
    name: []const u8,
    pid: ?std.process.Child.Id,
    state: state.WorkerState,
};
