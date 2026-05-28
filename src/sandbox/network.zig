// SPDX-License-Identifier: Apache-2.0
// FindingNemos — sandbox network isolation
//
// Models network isolation policies and capabilities for the sandbox.

const std = @import("std");

pub const NetworkMode = enum {
    host,
    bridge,
    none,
    custom,
    
    pub fn label(self: NetworkMode) []const u8 {
        return @tagName(self);
    }
};

pub const NetworkProfile = struct {
    mode: NetworkMode = .none,
    allowed_hosts: [][]const u8 = &[_][]const u8{},
    blocked_hosts: [][]const u8 = &[_][]const u8{},
    
    /// Determines if the current OS and environment can strictly enforce this profile.
    /// On Windows, namespace-based isolation is typically delegated to WSL2/Docker.
    pub fn isEnforceable(self: NetworkProfile) bool {
        // We only guarantee strict enforcement of `.none` if we delegate to a true container.
        if (self.mode == .none) return true;
        return false;
    }
};

test "network profile enforceability" {
    const p1 = NetworkProfile{ .mode = .none };
    try std.testing.expect(p1.isEnforceable());
    
    const p2 = NetworkProfile{ .mode = .host };
    try std.testing.expect(!p2.isEnforceable());
}
