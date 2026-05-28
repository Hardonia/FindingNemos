// SPDX-License-Identifier: Apache-2.0
// FindingNemos — time utilities
//
// Timestamp helpers for consistent epoch-based time across logs,
// state snapshots, and proofpack events.

const std = @import("std");

/// Current epoch time in seconds.
pub fn epochSeconds() i64 {
    return @divTrunc(std.time.milliTimestamp(), 1000);
}

/// Current epoch time in milliseconds.
pub fn epochMillis() i64 {
    return std.time.milliTimestamp();
}

/// Format epoch seconds into ISO-8601-like "YYYY-MM-DDTHH:MM:SSZ" in UTC.
/// Writes into buf and returns the written slice.
pub fn formatEpoch(epoch_secs: i64, buf: *[20]u8) []const u8 {
    const es: u64 = @bitCast(epoch_secs);
    const epoch_day = @divTrunc(es, 86400);
    const day_secs = @mod(es, 86400);
    const hour = @divTrunc(day_secs, 3600);
    const minute = @divTrunc(@mod(day_secs, 3600), 60);
    const second = @mod(day_secs, 60);

    // Civil date from epoch day (algorithm from Howard Hinnant)
    const z = epoch_day + 719468;
    const era = @divTrunc(z, 146097);
    const doe = z - era * 146097;
    const yoe = @divTrunc(doe - @divTrunc(doe, 1460) + @divTrunc(doe, 36524) - @divTrunc(doe, 146096), 365);
    const y = yoe + era * 400;
    const doy = doe - (365 * yoe + @divTrunc(yoe, 4) - @divTrunc(yoe, 100));
    const mp = @divTrunc(5 * doy + 2, 153);
    const d = doy - @divTrunc(153 * mp + 2, 5) + 1;
    const m_raw = if (mp < 10) mp + 3 else mp - 9;
    const y_final = if (m_raw <= 2) y + 1 else y;

    var stream = std.io.fixedBufferStream(buf);
    const w = stream.writer();
    w.print("{d:0>4}-{d:0>2}-{d:0>2}T{d:0>2}:{d:0>2}:{d:0>2}Z", .{
        @as(u32, @truncate(y_final)),
        @as(u32, @truncate(m_raw)),
        @as(u32, @truncate(d)),
        @as(u32, @truncate(hour)),
        @as(u32, @truncate(minute)),
        @as(u32, @truncate(second)),
    }) catch {};
    return stream.getWritten();
}

// ---------------------------------------------------------------------------
test "epochSeconds returns positive value" {
    const t = epochSeconds();
    try std.testing.expect(t > 0);
}

test "formatEpoch unix epoch zero" {
    var buf: [20]u8 = undefined;
    const s = formatEpoch(0, &buf);
    try std.testing.expectEqualStrings("1970-01-01T00:00:00Z", s);
}

test "formatEpoch known date" {
    var buf: [20]u8 = undefined;
    // 2024-01-01T00:00:00Z = 1704067200
    const s = formatEpoch(1704067200, &buf);
    try std.testing.expectEqualStrings("2024-01-01T00:00:00Z", s);
}
