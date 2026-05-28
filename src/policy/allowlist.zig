// SPDX-License-Identifier: Apache-2.0
const std = @import("std");

pub fn isAllowed(host: []const u8, allowlist: [][]const u8) bool {
    for (allowlist) |allowed| {
        if (std.mem.eql(u8, host, allowed)) return true;
    }
    return false;
}
