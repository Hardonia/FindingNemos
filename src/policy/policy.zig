// SPDX-License-Identifier: Apache-2.0
const std = @import("std");
const state = @import("../core/state.zig");

pub fn evaluateRequest(host: []const u8) state.PolicyDecision {
    _ = host;
    // Default deny placeholder
    return state.PolicyDecision{
        .state = .denied,
        .reason = "default deny",
    };
}

test "evaluateRequest defaults to deny" {
    const testing = std.testing;
    const decision = evaluateRequest("example.com");
    try testing.expect(decision.state == .denied);
}
