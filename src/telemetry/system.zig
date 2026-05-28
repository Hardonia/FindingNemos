// SPDX-License-Identifier: Apache-2.0
// FindingNemos — system telemetry

const std = @import("std");
const state = @import("../core/state.zig");
const time = @import("../core/time.zig");

/// Collect a basic system telemetry snapshot.
/// Phase 1: captures what's available without external probes.
pub fn snapshot() state.TelemetrySnapshot {
    return .{
        .timestamp_epoch = time.epochSeconds(),
        .cpu_count = std.Thread.getCpuCount() catch null,
        .memory_total_bytes = null, // Requires OS-specific probe (Phase 2)
        .memory_available_bytes = null,
        .gpu_available = .unknown,
        .gpu_name = null,
    };
}
