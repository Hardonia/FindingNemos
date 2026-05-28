// SPDX-License-Identifier: Apache-2.0
const std = @import("std");

pub fn generateId(allocator: std.mem.Allocator) ![]const u8 {
    var prng = std.Random.DefaultPrng.init(@as(u64, @intCast(std.time.milliTimestamp())));
    const random = prng.random();

    var bytes: [16]u8 = undefined;
    random.bytes(&bytes);

    return std.fmt.allocPrint(allocator, "{}", .{std.fmt.fmtSliceHexLower(&bytes)});
}

test "generateId" {
    const testing = std.testing;
    const id = try generateId(testing.allocator);
    defer testing.allocator.free(id);
    try testing.expect(id.len == 32);
}
