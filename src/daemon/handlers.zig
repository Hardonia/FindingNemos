// SPDX-License-Identifier: Apache-2.0
// FindingNemos — daemon request handlers

const protocol = @import("protocol.zig");

/// Dispatch a protocol request to the appropriate handler.
pub fn dispatch(req: protocol.Request) protocol.Response {
    if (eql(req.command, "health")) return handleHealth();
    if (eql(req.command, "status")) return handleStatus();

    return .{ .status = "error", .error_msg = "unknown command" };
}

fn handleHealth() protocol.Response {
    return .{ .status = "ok", .data = "healthy" };
}

fn handleStatus() protocol.Response {
    return .{ .status = "ok", .data = "running" };
}

fn eql(a: []const u8, b: []const u8) bool {
    const std = @import("std");
    return std.mem.eql(u8, a, b);
}
