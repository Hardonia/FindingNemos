// SPDX-License-Identifier: Apache-2.0
const std = @import("std");

pub const EvidenceType = enum {
    config_state,
    policy_decision,
    telemetry_snapshot,
};

pub const Evidence = struct {
    id: []const u8,
    type: EvidenceType,
    data: []const u8, // JSON payload redacted
};
