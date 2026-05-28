// SPDX-License-Identifier: Apache-2.0
const std = @import("std");

pub const ProviderType = enum {
    ollama,
    vllm,
    llamacpp,
    openai_compatible,
};

pub const Provider = struct {
    name: []const u8,
    type: ProviderType,
    endpoint: []const u8,
    priority: u32,
    enabled: bool,
    
    pub fn checkHealth(self: Provider) !bool {
        _ = self;
        // Scaffold implementation
        return true;
    }
};
