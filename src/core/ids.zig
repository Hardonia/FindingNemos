// SPDX-License-Identifier: Apache-2.0
// FindingNemos — unique ID generation
//
// Deterministic and random ID helpers for workers, proofpack events, etc.
// Uses timestamp + random suffix for sortable uniqueness without external deps.

const std = @import("std");

/// Generate a sortable ID: hex(epoch_ms) + "-" + hex(random_u64).
/// Writes into the provided buffer and returns the used slice.
pub fn generate(buf: *[37]u8) []const u8 {
    const ts = std.time.milliTimestamp();
    const ts_u: u64 = @bitCast(ts);
    var rng = std.Random.DefaultPrng.init(@bitCast(ts));
    const rand = rng.random().int(u64);

    var stream = std.io.fixedBufferStream(buf);
    const w = stream.writer();
    w.print("{x:0>16}-{x:0>16}", .{ ts_u, rand }) catch {};

    return stream.getWritten();
}

/// Fixed-length ID suitable for worker names (8 hex chars from timestamp).
pub fn shortId(buf: *[8]u8) []const u8 {
    const ts = std.time.milliTimestamp();
    const ts_u: u64 = @bitCast(ts);
    var stream = std.io.fixedBufferStream(buf);
    const w = stream.writer();
    w.print("{x:0>8}", .{@as(u32, @truncate(ts_u))}) catch {};
    return stream.getWritten();
}

// ---------------------------------------------------------------------------
test "generate produces non-empty sortable id" {
    var buf: [37]u8 = undefined;
    const id = generate(&buf);
    try std.testing.expect(id.len > 0);
    // Must contain the separator
    try std.testing.expect(std.mem.indexOf(u8, id, "-") != null);
}

test "shortId produces 8-char hex" {
    var buf: [8]u8 = undefined;
    const id = shortId(&buf);
    try std.testing.expectEqual(@as(usize, 8), id.len);
}
