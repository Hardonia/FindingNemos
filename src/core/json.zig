// SPDX-License-Identifier: Apache-2.0
// FindingNemos — minimal JSON writer
//
// Bounded-buffer JSON serialization for status, proofpacks, and state export.
// No heap allocation — writes directly to a fixed buffer.
// This is intentionally minimal: object/array/string/int/bool/null.

const std = @import("std");

pub const JsonWriter = struct {
    buf: []u8,
    pos: usize = 0,
    depth: usize = 0,
    needs_comma: bool = false,

    pub fn init(buf: []u8) JsonWriter {
        return .{ .buf = buf };
    }

    pub fn getWritten(self: *const JsonWriter) []const u8 {
        return self.buf[0..self.pos];
    }

    fn put(self: *JsonWriter, byte: u8) void {
        if (self.pos < self.buf.len) {
            self.buf[self.pos] = byte;
            self.pos += 1;
        }
    }

    fn putSlice(self: *JsonWriter, s: []const u8) void {
        for (s) |c| self.put(c);
    }

    fn comma(self: *JsonWriter) void {
        if (self.needs_comma) self.put(',');
        self.needs_comma = false;
    }

    pub fn beginObject(self: *JsonWriter) void {
        self.comma();
        self.put('{');
        self.depth += 1;
        self.needs_comma = false;
    }

    pub fn endObject(self: *JsonWriter) void {
        self.put('}');
        self.depth -|= 1;
        self.needs_comma = true;
    }

    pub fn beginArray(self: *JsonWriter) void {
        self.comma();
        self.put('[');
        self.depth += 1;
        self.needs_comma = false;
    }

    pub fn endArray(self: *JsonWriter) void {
        self.put(']');
        self.depth -|= 1;
        self.needs_comma = true;
    }

    pub fn key(self: *JsonWriter, k: []const u8) void {
        self.comma();
        self.put('"');
        self.putSlice(k);
        self.put('"');
        self.put(':');
        self.needs_comma = false;
    }

    pub fn stringValue(self: *JsonWriter, v: []const u8) void {
        self.comma();
        self.put('"');
        // Escape special chars
        for (v) |c| {
            switch (c) {
                '"' => {
                    self.put('\\');
                    self.put('"');
                },
                '\\' => {
                    self.put('\\');
                    self.put('\\');
                },
                '\n' => {
                    self.put('\\');
                    self.put('n');
                },
                '\r' => {
                    self.put('\\');
                    self.put('r');
                },
                '\t' => {
                    self.put('\\');
                    self.put('t');
                },
                else => self.put(c),
            }
        }
        self.put('"');
        self.needs_comma = true;
    }

    pub fn intValue(self: *JsonWriter, v: i64) void {
        self.comma();
        var num_buf: [20]u8 = undefined;
        var stream = std.io.fixedBufferStream(&num_buf);
        stream.writer().print("{d}", .{v}) catch {};
        self.putSlice(stream.getWritten());
        self.needs_comma = true;
    }

    pub fn boolValue(self: *JsonWriter, v: bool) void {
        self.comma();
        self.putSlice(if (v) "true" else "false");
        self.needs_comma = true;
    }

    pub fn nullValue(self: *JsonWriter) void {
        self.comma();
        self.putSlice("null");
        self.needs_comma = true;
    }

    /// Write a key-value pair where value is a string.
    pub fn field(self: *JsonWriter, k: []const u8, v: []const u8) void {
        self.key(k);
        self.stringValue(v);
    }

    /// Write a key-value pair where value is an integer.
    pub fn fieldInt(self: *JsonWriter, k: []const u8, v: i64) void {
        self.key(k);
        self.intValue(v);
    }

    /// Write a key-value pair where value is a bool.
    pub fn fieldBool(self: *JsonWriter, k: []const u8, v: bool) void {
        self.key(k);
        self.boolValue(v);
    }

    /// Write a key-value pair with null value.
    pub fn fieldNull(self: *JsonWriter, k: []const u8) void {
        self.key(k);
        self.nullValue();
    }
};

// ---------------------------------------------------------------------------
test "basic JSON object" {
    var buf: [256]u8 = undefined;
    var w = JsonWriter.init(&buf);
    w.beginObject();
    w.field("name", "findingnemos");
    w.fieldInt("version", 1);
    w.fieldBool("ok", true);
    w.endObject();

    const out = w.getWritten();
    try std.testing.expectEqualStrings(
        "{\"name\":\"findingnemos\",\"version\":1,\"ok\":true}",
        out,
    );
}

test "nested JSON with array" {
    var buf: [512]u8 = undefined;
    var w = JsonWriter.init(&buf);
    w.beginObject();
    w.key("items");
    w.beginArray();
    w.stringValue("a");
    w.stringValue("b");
    w.endArray();
    w.endObject();

    const out = w.getWritten();
    try std.testing.expectEqualStrings(
        "{\"items\":[\"a\",\"b\"]}",
        out,
    );
}

test "string escaping" {
    var buf: [128]u8 = undefined;
    var w = JsonWriter.init(&buf);
    w.stringValue("line1\nline2\t\"quoted\"");
    const out = w.getWritten();
    try std.testing.expectEqualStrings(
        "\"line1\\nline2\\t\\\"quoted\\\"\"",
        out,
    );
}
