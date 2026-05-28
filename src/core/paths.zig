// SPDX-License-Identifier: Apache-2.0
// FindingNemos — path utilities
//
// Resolves default paths for config, state, logs, and proofpacks.
// Respects HOME on all platforms; does not assume XDG.

const std = @import("std");
const builtin = @import("builtin");

pub const BASE_DIR_NAME = ".findingnemos";

/// Resolve the FindingNemos home directory.
/// Returns ~/.findingnemos/ or the equivalent on the current OS.
pub fn homeDir(buf: *[std.fs.max_path_bytes]u8) ![]const u8 {
    const home = std.process.getEnvVarOwned(std.heap.page_allocator, "HOME") catch blk: {
        if (builtin.os.tag == .windows) {
            break :blk std.process.getEnvVarOwned(std.heap.page_allocator, "USERPROFILE") catch
                return error.IoError;
        }
        return error.IoError;
    };
    defer std.heap.page_allocator.free(home);

    var stream = std.io.fixedBufferStream(buf);
    const w = stream.writer();
    if (builtin.os.tag == .windows) {
        w.print("{s}\\{s}", .{ home, BASE_DIR_NAME }) catch return error.BufferOverflow;
    } else {
        w.print("{s}/{s}", .{ home, BASE_DIR_NAME }) catch return error.BufferOverflow;
    }
    return stream.getWritten();
}

/// Subpath under the findingnemos home dir.
pub fn subPath(
    home: []const u8,
    sub: []const u8,
    buf: *[std.fs.max_path_bytes]u8,
) ![]const u8 {
    var stream = std.io.fixedBufferStream(buf);
    const w = stream.writer();
    if (builtin.os.tag == .windows) {
        w.print("{s}\\{s}", .{ home, sub }) catch return error.BufferOverflow;
    } else {
        w.print("{s}/{s}", .{ home, sub }) catch return error.BufferOverflow;
    }
    return stream.getWritten();
}

/// Well-known subpaths.
pub const Subs = struct {
    pub const config = "config.toml";
    pub const state = "state.json";
    pub const logs = "logs";
    pub const proofpacks = "proofpacks";
};

// ---------------------------------------------------------------------------
test "BASE_DIR_NAME is correct" {
    try std.testing.expectEqualStrings(".findingnemos", BASE_DIR_NAME);
}

test "subPath concatenation" {
    var buf: [std.fs.max_path_bytes]u8 = undefined;
    const p = try subPath("/home/user/.findingnemos", "logs", &buf);
    try std.testing.expect(p.len > 0);
    try std.testing.expect(std.mem.endsWith(u8, p, "logs"));
}
