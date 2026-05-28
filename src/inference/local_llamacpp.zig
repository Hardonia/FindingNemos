// SPDX-License-Identifier: Apache-2.0
// FindingNemos — llama.cpp provider stub

const provider = @import("provider.zig");

pub fn create(endpoint: ?[]const u8) provider.ProviderInfo {
    return provider.llamacppProvider(endpoint);
}
