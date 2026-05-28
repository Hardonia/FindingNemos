// SPDX-License-Identifier: Apache-2.0
const std = @import("std");
const schema = @import("schema.zig");
const errors = @import("../core/errors.zig");

pub fn validateConfig(cfg: schema.Config) !void {
    if (cfg.daemon.port == 0) {
        return errors.FindingNemosError.InvalidConfig;
    }
    // Fail closed validation
    if (cfg.policy.allowlist.len == 0 and cfg.policy.denylist.len == 0) {
        // Just an example validation rule
    }
}

test "validateConfig" {
    const testing = std.testing;
    const cfg = schema.Config{};
    try validateConfig(cfg);
}
