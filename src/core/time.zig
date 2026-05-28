// SPDX-License-Identifier: Apache-2.0
const std = @import("std");

pub fn currentTimestampMs() i64 {
    return std.time.milliTimestamp();
}

test "time" {
    const testing = std.testing;
    try testing.expect(currentTimestampMs() > 0);
}
