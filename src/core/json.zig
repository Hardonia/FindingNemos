// SPDX-License-Identifier: Apache-2.0
const std = @import("std");

pub fn redactSecret(secret: []const u8) []const u8 {
    _ = secret;
    return "[REDACTED]";
}

test "redaction" {
    const testing = std.testing;
    try testing.expectEqualStrings("[REDACTED]", redactSecret("my_secret_key_123"));
}
