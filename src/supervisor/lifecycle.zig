// SPDX-License-Identifier: Apache-2.0
// FindingNemos — lifecycle management

const state = @import("../core/state.zig");

/// Determine if a state transition is valid.
pub fn isValidTransition(from: state.WorkerState, to: state.WorkerState) bool {
    return switch (from) {
        .unknown => true, // unknown can go anywhere
        .configured => to == .starting or to == .stopped,
        .starting => to == .running or to == .failed or to == .stopped,
        .running => to == .healthy or to == .degraded or to == .stopping or to == .failed,
        .healthy => to == .degraded or to == .stopping or to == .failed,
        .degraded => to == .healthy or to == .stopping or to == .failed,
        .stopping => to == .stopped or to == .failed,
        .stopped => to == .starting or to == .configured,
        .failed => to == .starting or to == .configured,
    };
}
