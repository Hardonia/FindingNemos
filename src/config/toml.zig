// SPDX-License-Identifier: Apache-2.0
// FindingNemos — minimal TOML parser
//
// Handles the subset of TOML needed by FindingNemos config files:
// - [section] headers
// - key = "string_value"
// - key = integer
// - key = true/false
// - # comments
//
// This is intentionally simple. A full TOML parser is a future upgrade path.
// Fails closed: any parse error rejects the file.

const std = @import("std");

pub const Value = union(enum) {
    string: []const u8,
    integer: i64,
    boolean: bool,
};

pub const Entry = struct {
    section: []const u8,
    key: []const u8,
    value: Value,
};

pub const ParseError = error{
    InvalidToml,
    OutOfMemory,
};

/// Parse a TOML file's contents into a list of section/key/value entries.
/// Caller owns the returned slice via the provided allocator.
pub fn parse(allocator: std.mem.Allocator, source: []const u8) ParseError![]Entry {
    var entries = std.ArrayList(Entry).init(allocator);
    errdefer entries.deinit();

    var current_section: []const u8 = "";
    var iter = std.mem.splitScalar(u8, source, '\n');

    while (iter.next()) |raw_line| {
        // Strip \r for Windows line endings
        const line_cr = std.mem.trimRight(u8, raw_line, "\r");
        const line = std.mem.trim(u8, line_cr, " \t");

        // Skip empty lines and comments
        if (line.len == 0 or line[0] == '#') continue;

        // Section header
        if (line[0] == '[') {
            if (line[line.len - 1] != ']') return error.InvalidToml;
            current_section = line[1 .. line.len - 1];
            continue;
        }

        // Key = value
        const eq_pos = std.mem.indexOf(u8, line, "=") orelse return error.InvalidToml;
        const key_raw = std.mem.trim(u8, line[0..eq_pos], " \t");
        if (key_raw.len == 0) return error.InvalidToml;

        const val_raw = std.mem.trim(u8, line[eq_pos + 1 ..], " \t");
        if (val_raw.len == 0) return error.InvalidToml;

        const value: Value = blk: {
            // String value
            if (val_raw[0] == '"') {
                if (val_raw.len < 2 or val_raw[val_raw.len - 1] != '"')
                    return error.InvalidToml;
                break :blk .{ .string = val_raw[1 .. val_raw.len - 1] };
            }
            // Boolean
            if (std.mem.eql(u8, val_raw, "true")) break :blk .{ .boolean = true };
            if (std.mem.eql(u8, val_raw, "false")) break :blk .{ .boolean = false };
            // Integer
            const num = std.fmt.parseInt(i64, val_raw, 10) catch return error.InvalidToml;
            break :blk .{ .integer = num };
        };

        entries.append(.{
            .section = current_section,
            .key = key_raw,
            .value = value,
        }) catch return error.OutOfMemory;
    }

    return entries.toOwnedSlice() catch return error.OutOfMemory;
}

/// Look up a string value by section and key. Returns null if not found.
pub fn getString(entries: []const Entry, section: []const u8, key: []const u8) ?[]const u8 {
    for (entries) |e| {
        if (std.mem.eql(u8, e.section, section) and std.mem.eql(u8, e.key, key)) {
            switch (e.value) {
                .string => |s| return s,
                else => return null,
            }
        }
    }
    return null;
}

/// Look up a boolean value by section and key.
pub fn getBool(entries: []const Entry, section: []const u8, key: []const u8) ?bool {
    for (entries) |e| {
        if (std.mem.eql(u8, e.section, section) and std.mem.eql(u8, e.key, key)) {
            switch (e.value) {
                .boolean => |b| return b,
                else => return null,
            }
        }
    }
    return null;
}

/// Look up an integer value by section and key.
pub fn getInt(entries: []const Entry, section: []const u8, key: []const u8) ?i64 {
    for (entries) |e| {
        if (std.mem.eql(u8, e.section, section) and std.mem.eql(u8, e.key, key)) {
            switch (e.value) {
                .integer => |n| return n,
                else => return null,
            }
        }
    }
    return null;
}

// ---------------------------------------------------------------------------
test "parse basic TOML" {
    const src =
        \\# FindingNemos config
        \\[runtime]
        \\version = "0.1.0"
        \\debug = false
        \\port = 9100
        \\
        \\[daemon]
        \\enabled = true
    ;

    const entries = try parse(std.testing.allocator, src);
    defer std.testing.allocator.free(entries);

    try std.testing.expectEqual(@as(usize, 4), entries.len);
    try std.testing.expectEqualStrings("runtime", entries[0].section);
    try std.testing.expectEqualStrings("version", entries[0].key);

    const ver = getString(entries, "runtime", "version");
    try std.testing.expect(ver != null);
    try std.testing.expectEqualStrings("0.1.0", ver.?);

    const debug = getBool(entries, "runtime", "debug");
    try std.testing.expect(debug != null);
    try std.testing.expect(!debug.?);

    const port = getInt(entries, "runtime", "port");
    try std.testing.expect(port != null);
    try std.testing.expectEqual(@as(i64, 9100), port.?);
}

test "parse rejects invalid TOML" {
    const bad = "key without equals";
    const result = parse(std.testing.allocator, bad);
    try std.testing.expectError(error.InvalidToml, result);
}

test "parse handles empty input" {
    const entries = try parse(std.testing.allocator, "");
    defer std.testing.allocator.free(entries);
    try std.testing.expectEqual(@as(usize, 0), entries.len);
}
