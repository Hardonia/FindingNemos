// SPDX-License-Identifier: Apache-2.0
// FindingNemos — sandbox policy

const egress = @import("../policy/egress.zig");

/// Sandbox-specific policy wrapping the egress engine.
pub const SandboxPolicy = struct {
    egress_config: egress.PolicyConfig = .{},
};
