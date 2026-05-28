// SPDX-License-Identifier: Apache-2.0
// FindingNemos — persistent audit logging
//
// Records critical security and lifecycle events to an append-only log.

const std = @import("std");
const time = @import("../core/time.zig");
const json = @import("../core/json.zig");

pub const AuditLog = struct {
    file: std.fs.File,
    mutex: std.Thread.Mutex,

    /// Opens or creates the audit log file at the given path.
    pub fn init(path: []const u8) !AuditLog {
        const file = try std.fs.cwd().createFile(path, .{
            .read = false,
            .truncate = false,
        });
        
        // Seek to end to append
        try file.seekFromEnd(0);
        
        return AuditLog{
            .file = file,
            .mutex = .{},
        };
    }

    /// Appends a new event to the audit log in JSON Lines format.
    pub fn logEvent(self: *AuditLog, event_type: []const u8, details: []const u8) !void {
        self.mutex.lock();
        defer self.mutex.unlock();

        var buf: [1024]u8 = undefined;
        var w = json.JsonWriter.init(&buf);
        w.beginObject();
        w.fieldInt("timestamp", time.epochSeconds());
        w.field("type", event_type);
        w.field("details", details);
        w.endObject();
        
        const payload = w.getWritten();
        try self.file.writer().print("{s}\n", .{payload});
        
        // Ensure the write is synced to disk for audit reliability
        try self.file.sync();
    }

    /// Closes the audit log.
    pub fn deinit(self: *AuditLog) void {
        self.file.close();
    }
};

test "audit log append" {
    // We don't want to pollute the filesystem in normal tests,
    // but we can verify it compiles. Real tests would use a temp dir.
    const path = "test_audit.jsonl";
    
    // Create
    var audit = try AuditLog.init(path);
    defer audit.deinit();
    defer std.fs.cwd().deleteFile(path) catch {};
    
    // Log
    try audit.logEvent("test_start", "running unit tests");
    
    // Verify file exists and has content
    const stat = try std.fs.cwd().statFile(path);
    try std.testing.expect(stat.size > 0);
}
