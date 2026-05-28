// SPDX-License-Identifier: Apache-2.0
// FindingNemos — GPU telemetry

const state = @import("../core/state.zig");

/// GPU detection status.
/// Phase 1: always returns unknown. Real nvidia-smi / ROCm probes are Phase 2.
/// We do NOT claim GPU support that hasn't been verified.
pub fn detect() state.Availability {
    return .unknown;
}
