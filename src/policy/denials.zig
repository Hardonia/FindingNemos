// SPDX-License-Identifier: Apache-2.0
const std = @import("std");

pub fn isDenied(host: []const u8, denylist: [][]const u8) bool {
    for (denylist) |denied| {
        if (std.mem.eql(u8, host, denied)) return true;
    }
    return false;
}
