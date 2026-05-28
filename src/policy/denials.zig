// SPDX-License-Identifier: Apache-2.0
// FindingNemos — denial logging

const std = @import("std");

pub const Denial = struct {
    host: []const u8,
    reason: []const u8,
    timestamp_epoch: i64,
};
