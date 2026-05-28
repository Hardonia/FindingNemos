// SPDX-License-Identifier: Apache-2.0
// FindingNemos — model pool

const provider = @import("provider.zig");

/// A collection of configured providers. Phase 1 is a simple fixed-size list.
pub const ModelPool = struct {
    providers: [8]?provider.ProviderInfo = .{ null, null, null, null, null, null, null, null },
    count: usize = 0,

    pub fn add(self: *ModelPool, p: provider.ProviderInfo) void {
        if (self.count < 8) {
            self.providers[self.count] = p;
            self.count += 1;
        }
    }

    pub fn activeSlice(self: *const ModelPool) []const ?provider.ProviderInfo {
        return self.providers[0..self.count];
    }
};
