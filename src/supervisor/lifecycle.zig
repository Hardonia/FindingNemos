// SPDX-License-Identifier: Apache-2.0
const std = @import("std");
const worker = @import("worker.zig");
const process = @import("process.zig");
const state = @import("../core/state.zig");

pub fn startWorker(name: []const u8, cmd: []const u8) !worker.Worker {
    const pid = try process.spawnWorkerProcess(cmd);
    return worker.Worker{
        .name = name,
        .pid = pid,
        .state = .starting,
    };
}

pub fn stopWorker(name: []const u8) !void {
    _ = name;
    // Scaffold implementation
}
