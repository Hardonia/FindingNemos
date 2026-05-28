// SPDX-License-Identifier: Apache-2.0
const std = @import("std");
const schema = @import("schema.zig");

// A basic fail-closed config parser placeholder.
// We will parse TOML if we add a dependency, but for now we have a stub that returns default or err.

pub fn parseConfig(allocator: std.mem.Allocator, file_path: []const u8) !schema.Config {
    _ = allocator;
    _ = file_path;
    // In a real implementation this would parse the TOML file.
    // For now we just return a default struct to satisfy the scaffold.
    return schema.Config{};
}

test "parseConfig" {
    const testing = std.testing;
    const cfg = try parseConfig(testing.allocator, "dummy");
    try testing.expect(cfg.daemon.port == 8080);
}
