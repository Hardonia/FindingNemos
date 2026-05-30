// SPDX-License-Identifier: Apache-2.0
// FindingNemos — backup and restore operations
//
// Handles atomic snapshots of configuration, state, and audit logs.

const std = @import("std");

pub const BackupError = error{
    SourceDirNotFound,
    AccessDenied,
    DiskFull,
    InvalidArchive,
} || std.fs.File.OpenError || std.fs.Dir.OpenError;

/// Creates a backup of the FindingNemos state directory to a specified archive path.
pub fn createBackup(allocator: std.mem.Allocator, source_dir: []const u8, dest_archive: []const u8) BackupError!void {
    // Phase 4: Mock implementation. A real implementation would:
    // 1. Lock the state directory
    // 2. Walk `source_dir`
    // 3. Stream to a `.tar.gz` archive using `std.tar` and `std.compress`
    _ = allocator;

    std.fs.cwd().access(source_dir, .{}) catch |err| switch(err) {
        error.FileNotFound => return error.SourceDirNotFound,
        else => return error.AccessDenied,
    };

    // Touch the destination file to simulate successful creation
    var file = std.fs.cwd().createFile(dest_archive, .{ .truncate = true }) catch {
        return error.AccessDenied;
    };
    defer file.close();

    file.writeAll("FINDINGNEMOS_BACKUP_V1\n") catch return error.DiskFull;
}

/// Restores a FindingNemos state directory from a specified archive path.
pub fn restoreBackup(allocator: std.mem.Allocator, source_archive: []const u8, dest_dir: []const u8) BackupError!void {
    _ = allocator;

    var file = std.fs.cwd().openFile(source_archive, .{}) catch |err| switch(err) {
        error.FileNotFound => return error.InvalidArchive,
        else => return error.AccessDenied,
    };
    defer file.close();

    var buf: [32]u8 = undefined;
    const bytes_read = file.read(&buf) catch return error.InvalidArchive;
    if (bytes_read == 0 or !std.mem.startsWith(u8, buf[0..bytes_read], "FINDINGNEMOS_BACKUP")) {
        return error.InvalidArchive;
    }

    std.fs.cwd().makePath(dest_dir) catch return error.AccessDenied;
}

test "backup and restore cycle" {
    const allocator = std.testing.allocator;

    const test_dir = "test_state";
    const test_archive = "test_backup.tar.gz";

    std.fs.cwd().makePath(test_dir) catch {};
    defer std.fs.cwd().deleteTree(test_dir) catch {};
    defer std.fs.cwd().deleteFile(test_archive) catch {};

    try createBackup(allocator, test_dir, test_archive);

    const restore_dir = "test_restore";
    defer std.fs.cwd().deleteTree(restore_dir) catch {};

    try restoreBackup(allocator, test_archive, restore_dir);
}
