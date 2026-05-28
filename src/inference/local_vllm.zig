// SPDX-License-Identifier: Apache-2.0
// FindingNemos — vLLM provider stub

const provider = @import("provider.zig");

pub fn create(endpoint: ?[]const u8) provider.ProviderInfo {
    return provider.vllmProvider(endpoint);
}
