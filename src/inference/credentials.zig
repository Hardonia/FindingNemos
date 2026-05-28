// SPDX-License-Identifier: Apache-2.0
// FindingNemos — credential handling
//
// Secrets are NEVER stored directly. We only reference environment variable
// names. The redact() function masks values for safe logging/export.

const std = @import("std");

/// Redact a secret value for display. Shows first 4 chars + "***" if long enough,
/// or "***" for short values.
pub fn redact(value: []const u8) [7]u8 {
    var buf: [7]u8 = .{ '*', '*', '*', '*', '*', '*', '*' };
    if (value.len >= 4) {
        buf[0] = value[0];
        buf[1] = value[1];
        buf[2] = value[2];
        buf[3] = value[3];
        buf[4] = '*';
        buf[5] = '*';
        buf[6] = '*';
    }
    return buf;
}

/// Redact to a slice (for callers that need []const u8).
pub fn redactSlice(value: []const u8) []const u8 {
    if (value.len == 0) return "***";
    // For display purposes, we always return "***" for the value itself.
    // The actual env var NAME is safe to show; only the resolved value is secret.
    // value used for length check above, no discard needed
}

/// Check if a string looks like it might be a raw API key (heuristic).
/// Used for safety checks — we never want raw keys in config values.
pub fn looksLikeKey(value: []const u8) bool {
    if (value.len < 20) return false;
    // Common key prefixes
    if (std.mem.startsWith(u8, value, "sk-")) return true;
    if (std.mem.startsWith(u8, value, "nvapi-")) return true;
    if (std.mem.startsWith(u8, value, "hf_")) return true;
    // High entropy heuristic: if >60% alphanumeric and >30 chars
    if (value.len > 30) {
        var alnum_count: usize = 0;
        for (value) |c| {
            if (std.ascii.isAlphanumeric(c) or c == '-' or c == '_') alnum_count += 1;
        }
        const ratio = (alnum_count * 100) / value.len;
        if (ratio > 80) return true;
    }
    return false;
}

// ---------------------------------------------------------------------------
test "redact short value" {
    const r = redact("abc");
    try std.testing.expectEqualStrings("*******", &r);
}

test "redact long value shows prefix" {
    const r = redact("sk-1234567890abcdef");
    try std.testing.expectEqualStrings("sk-1***", &r);
}

test "looksLikeKey detects common prefixes" {
    try std.testing.expect(looksLikeKey("sk-1234567890abcdefghij"));
    try std.testing.expect(looksLikeKey("nvapi-abcdefghijklmnopqrst"));
    try std.testing.expect(looksLikeKey("hf_abcdefghijklmnopqrst"));
}

test "looksLikeKey rejects normal strings" {
    try std.testing.expect(!looksLikeKey("hello"));
    try std.testing.expect(!looksLikeKey("OPENAI_API_KEY"));
    try std.testing.expect(!looksLikeKey("http://localhost:11434"));
}
