// SPDX-License-Identifier: Apache-2.0
// FindingNemos — Ollama provider
//
// Status: Phase 1 stub. Checks config only. Real health probe (/api/tags)
// will be implemented when HTTP client is available.

const provider = @import("provider.zig");

pub fn create(endpoint: ?[]const u8) provider.ProviderInfo {
    return provider.ollamaProvider(endpoint);
}
