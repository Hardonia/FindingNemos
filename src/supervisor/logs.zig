// SPDX-License-Identifier: Apache-2.0
// FindingNemos — log management for supervised workers

const std = @import("std");

/// Build a log file path for a worker. Writes into buf.
pub fn logPath(base_dir: []const u8, worker_name: []const u8, buf: *[std.fs.max_path_bytes]u8) []const u8 {
    var stream = std.io.fixedBufferStream(buf);
    const w = stream.writer();
    w.print("{s}/{s}.log", .{ base_dir, worker_name }) catch {};
    return stream.getWritten();
}
