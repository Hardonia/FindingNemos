// SPDX-License-Identifier: Apache-2.0
const std = @import("std");
const errors = @import("errors.zig");

pub fn Result(comptime T: type) type {
    return union(enum) {
        ok: T,
        err: errors.FindingNemosError,
    };
}
