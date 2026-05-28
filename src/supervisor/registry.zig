// SPDX-License-Identifier: Apache-2.0
// FindingNemos — worker registry
//
// Fixed-capacity registry of managed workers. No dynamic allocation.

const worker = @import("worker.zig");
const process = @import("process.zig");
const std = @import("std");

pub const MAX_WORKERS = 32;

pub const Registry = struct {
    workers: [MAX_WORKERS]?worker.Worker = .{null} ** MAX_WORKERS,
    count: usize = 0,

    pub fn add(self: *Registry, name: []const u8, command: []const u8) !usize {
        if (self.count >= MAX_WORKERS) return error.OutOfMemory;
        const idx = self.count;
        self.workers[idx] = .{
            .handle = process.create(name, command),
        };
        self.count += 1;
        return idx;
    }

    pub fn findByName(self: *const Registry, name: []const u8) ?usize {
        for (self.workers[0..self.count], 0..) |maybe_w, i| {
            if (maybe_w) |w| {
                if (std.mem.eql(u8, w.handle.name, name)) return i;
            }
        }
        return null;
    }

    pub fn get(self: *const Registry, idx: usize) ?*const worker.Worker {
        if (idx >= self.count) return null;
        if (self.workers[idx]) |*w| return w;
        return null;
    }
};
