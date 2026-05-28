// SPDX-License-Identifier: Apache-2.0
// FindingNemos — worker management

const process = @import("process.zig");

/// Worker wraps a ProcessHandle with additional metadata.
pub const Worker = struct {
    handle: process.ProcessHandle,
    restart_count: u32 = 0,
    max_restarts: u32 = 0,
};
