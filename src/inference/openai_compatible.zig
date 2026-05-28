// SPDX-License-Identifier: Apache-2.0
// FindingNemos — OpenAI-compatible provider stub

const provider = @import("provider.zig");

pub fn create(endpoint: ?[]const u8) provider.ProviderInfo {
    return provider.openaiProvider(endpoint);
}
