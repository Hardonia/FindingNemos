// SPDX-License-Identifier: Apache-2.0
const std = @import("std");

pub fn isLocalhost(host: []const u8) bool {
    return std.mem.eql(u8, host, "localhost") or std.mem.eql(u8, host, "127.0.0.1") or std.mem.eql(u8, host, "::1");
}

pub fn isMetadataEndpoint(host: []const u8) bool {
    return std.mem.eql(u8, host, "169.254.169.254");
}

test "ssrf blocks metadata" {
    const testing = std.testing;
    try testing.expect(isMetadataEndpoint("169.254.169.254"));
}
