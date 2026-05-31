// SPDX-License-Identifier: Apache-2.0
// FindingNemos — process supervisor
//
// Spawns and manages child processes. Captures pid, stdout/stderr to logs,
// detects exit codes, tracks lifecycle timestamps.

const std = @import("std");
const state = @import("../core/state.zig");
const time = @import("../core/time.zig");

pub const ProcessHandle = struct {
    name: []const u8,
    command: []const u8,
    pid: ?u32 = null,
    state: state.WorkerState = .configured,
    exit_code: ?u8 = null,
    started_at: ?i64 = null,
    stopped_at: ?i64 = null,
    log_path: ?[]const u8 = null,

    /// Check if this process has a live pid (does NOT verify the OS process).
    pub fn hasLivePid(self: *const ProcessHandle) bool {
        return self.pid != null and self.state.isAlive();
    }
};

/// Create a new process handle (does not start the process).
pub fn create(name: []const u8, command: []const u8) ProcessHandle {
    return .{
        .name = name,
        .command = command,
        .state = .configured,
    };
}

/// Record that a process was started with a given pid.
pub fn markStarted(handle: *ProcessHandle, pid: u32) void {
    handle.pid = pid;
    handle.state = .running;
    handle.started_at = time.epochSeconds();
    handle.exit_code = null;
    handle.stopped_at = null;
}

/// Record that a process has stopped.
pub fn markStopped(handle: *ProcessHandle, exit_code: ?u8) void {
    handle.state = if (exit_code != null and exit_code.? == 0) .stopped else .failed;
    handle.exit_code = exit_code;
    handle.stopped_at = time.epochSeconds();
}

pub const ManagedProcess = struct {
    allocator: std.mem.Allocator,
    handle: ProcessHandle,
    child: ?std.process.Child = null,
    log_file: ?std.fs.File = null,

    pub fn init(allocator: std.mem.Allocator, name: []const u8, command: []const u8) ManagedProcess {
        return .{
            .allocator = allocator,
            .handle = create(name, command),
        };
    }

    pub fn start(self: *ManagedProcess, log_dir: []const u8) !void {
        if (self.handle.hasLivePid()) return error.AlreadyRunning;

        var args_list = std.ArrayList([]const u8).init(self.allocator);
        defer args_list.deinit();

        var it = std.mem.tokenizeScalar(u8, self.handle.command, ' ');
        while (it.next()) |token| {
            try args_list.append(token);
        }

        var child = std.process.Child.init(args_list.items, self.allocator);

        var path_buf: [std.fs.max_path_bytes]u8 = undefined;
        var fbs = std.io.fixedBufferStream(&path_buf);
        try fbs.writer().print("{s}/{s}.log", .{ log_dir, self.handle.name });
        const log_path = fbs.getWritten();

        self.handle.log_path = try self.allocator.dupe(u8, log_path);

        const log_file = try std.fs.cwd().createFile(log_path, .{
            .read = true,
            .truncate = false,
        });

        try log_file.seekFromEnd(0);
        self.log_file = log_file;

        child.stdout_behavior = .{ .File = log_file };
        child.stderr_behavior = .{ .File = log_file };

        try child.spawn();

        self.child = child;
        markStarted(&self.handle, @intCast(child.id));
    }

    pub fn stop(self: *ManagedProcess) !void {
        if (!self.handle.hasLivePid() or self.child == null) return;

        var child = self.child.?;
        _ = try child.kill();
        const term = try child.wait();

        const code: ?u8 = switch (term) {
            .Exited => |c| c,
            else => null,
        };

        markStopped(&self.handle, code);

        if (self.log_file) |f| {
            f.close();
            self.log_file = null;
        }
        self.child = null;
    }

    pub fn deinit(self: *ManagedProcess) void {
        if (self.handle.hasLivePid()) {
            self.stop() catch {};
        }
        if (self.handle.log_path) |p| {
            self.allocator.free(p);
        }
    }
};

// ---------------------------------------------------------------------------
test "process lifecycle" {
    var p = create("test-worker", "echo hello");
    try std.testing.expectEqual(state.WorkerState.configured, p.state);
    try std.testing.expect(!p.hasLivePid());

    markStarted(&p, 12345);
    try std.testing.expectEqual(state.WorkerState.running, p.state);
    try std.testing.expectEqual(@as(u32, 12345), p.pid.?);
    try std.testing.expect(p.hasLivePid());

    markStopped(&p, 0);
    try std.testing.expectEqual(state.WorkerState.stopped, p.state);
    try std.testing.expect(!p.hasLivePid());
}

test "failed exit code marks failed" {
    var p = create("bad-worker", "false");
    markStarted(&p, 99);
    markStopped(&p, 1);
    try std.testing.expectEqual(state.WorkerState.failed, p.state);
}

test "managed process spawn" {
    const allocator = std.testing.allocator;
    var mp = ManagedProcess.init(allocator, "test-echo", "echo hello");
    defer mp.deinit();
}
