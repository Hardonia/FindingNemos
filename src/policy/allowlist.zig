// SPDX-License-Identifier: Apache-2.0
// FindingNemos — policy allowlist utilities

const std = @import("std");

/// Parse a comma-separated allowlist string into an iterator.
pub fn parseList(list: []const u8) std.mem.SplitIterator(u8, .scalar) {
    return std.mem.splitScalar(u8, list, ',');
}

/// Count entries in a comma-separated list.
pub fn countEntries(list: []const u8) usize {
    var count: usize = 0;
    var iter = parseList(list);
    while (iter.next()) |entry| {
        const trimmed = std.mem.trim(u8, entry, " \t");
        if (trimmed.len > 0) count += 1;
    }
    return count;
}
