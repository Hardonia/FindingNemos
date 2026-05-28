// SPDX-License-Identifier: Apache-2.0
const std = @import("std");
const provider = @import("provider.zig");
const state = @import("../core/state.zig");

pub fn routePrompt(prompt: []const u8, providers: []const provider.Provider) !state.RouteTrace {
    _ = prompt;
    
    // Sort providers by priority (scaffold)
    // Find first healthy provider
    var selected: ?[]const u8 = null;
    var reason: []const u8 = "no_route_available";
    
    for (providers) |p| {
        if (!p.enabled) continue;
        if (p.checkHealth() catch false) {
            selected = p.name;
            reason = "healthy and highest priority";
            break;
        }
    }
    
    return state.RouteTrace{
        .prompt_id = "dummy_id",
        .selected_provider = selected,
        .reason = reason,
    };
}

test "router no-route" {
    const testing = std.testing;
    const providers = [_]provider.Provider{};
    const trace = try routePrompt("test", &providers);
    try testing.expect(trace.selected_provider == null);
}
