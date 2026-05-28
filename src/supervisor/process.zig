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
