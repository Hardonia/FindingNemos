// SPDX-License-Identifier: Apache-2.0
const std = @import("std");
const worker = @import("worker.zig");

pub fn listWorkers() ![]const worker.Worker {
    // Scaffold implementation
    return &[_]worker.Worker{};
}
