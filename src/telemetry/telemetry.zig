// SPDX-License-Identifier: Apache-2.0
const std = @import("std");
const state = @import("../core/state.zig");
const gpu = @import("gpu.zig");

pub fn getSnapshot() state.TelemetrySnapshot {
    return state.TelemetrySnapshot{
        .timestamp = std.time.milliTimestamp(),
        .cpu_usage_pct = null,
        .memory_usage_bytes = null,
        .gpu_state = gpu.checkGpuState(),
    };
}
