// SPDX-License-Identifier: Apache-2.0
// FindingNemos — proofpack export

const std = @import("std");
const proofpack = @import("proofpack.zig");

/// Export format selection.
pub const Format = enum { json, markdown };
