// SPDX-License-Identifier: Apache-2.0
// FindingNemos — Docker Sandbox Execution
//
// Manages container execution using the Docker CLI, enforcing resource limits
// and providing a consistent ProcessHandle for the supervisor.

const std = @import("std");
const state = @import("../core/state.zig");
const process = @import("../supervisor/process.zig");

pub const DockerConfig = struct {
    image: []const u8 = "alpine:latest",
    memory_mb: u32 = 512,
    cpu_limit: f32 = 1.0,
    network_none: bool = true,
};

/// Check Docker availability by attempting to run `docker --version`.
pub fn checkAvailability(allocator: std.mem.Allocator) state.Availability {
    const argv = &[_][]const u8{ "docker", "--version" };
    
    // We just want to check if the command runs, ignore output
    const result = std.process.Child.run(.{
        .allocator = allocator,
        .argv = argv,
    }) catch return .unavailable;

    defer allocator.free(result.stdout);
    defer allocator.free(result.stderr);

    return switch (result.term) {
        .Exited => |code| if (code == 0) .available else .unavailable,
        else => .unavailable,
    };
}

/// Creates a ManagedProcess that wraps `docker run` with the given configuration.
/// The supervisor can then start() and stop() this process normally.
pub fn createContainerProcess(
    allocator: std.mem.Allocator,
    name: []const u8,
    config: DockerConfig,
    cmd_args: []const []const u8
) !process.ManagedProcess {
    var cmd_builder = std.ArrayList(u8).init(allocator);
    defer cmd_builder.deinit();
    
    const writer = cmd_builder.writer();
    
    // docker run --name <name> --rm
    try writer.print("docker run --name {s} --rm", .{name});
    
    // Limits
    try writer.print(" -m {d}m --cpus={d:.1}", .{ config.memory_mb, config.cpu_limit });
    
    // Networking
    if (config.network_none) {
        try writer.print(" --network none", .{});
    }
    
    // Image
    try writer.print(" {s}", .{config.image});
    
    // User command
    for (cmd_args) |arg| {
        try writer.print(" {s}", .{arg});
    }

    const full_cmd = try cmd_builder.toOwnedSlice();
    // caller owns full_cmd memory
    
    return process.ManagedProcess.init(allocator, name, full_cmd);
}

test "docker availability check" {
    // In CI, Docker might not be installed, so we just ensure it doesn't crash.
    _ = checkAvailability(std.testing.allocator);
}

test "container process formatting" {
    const allocator = std.testing.allocator;
    const args = &[_][]const u8{"echo", "hello"};
    var p = try createContainerProcess(allocator, "test-box", .{}, args);
    defer p.deinit();
    defer allocator.free(p.handle.command);
    
    // Check if the command starts with "docker run"
    try std.testing.expect(std.mem.startsWith(u8, p.handle.command, "docker run"));
}
