// SPDX-License-Identifier: Apache-2.0
const std = @import("std");

pub fn getDefaultConfigPath(allocator: std.mem.Allocator) ![]const u8 {
    if (std.process.getEnvVarOwned(allocator, "HOME")) |home| {
        defer allocator.free(home);
        return std.fs.path.join(allocator, &[_][]const u8{ home, ".findingnemos", "config.toml" });
    } else |err| {
        return err;
    }
}

test "paths" {
    // Tests disabled in general environment due to HOME variance, but can run manually
}
