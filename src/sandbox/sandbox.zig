// SPDX-License-Identifier: Apache-2.0
const std = @import("std");

pub const SandboxConfig = struct {
    runtime: []const u8 = "docker",
    network: bool = false,
};

pub fn checkSandboxCapabilities() !bool {
    // Scaffold implementation
    return true;
}
