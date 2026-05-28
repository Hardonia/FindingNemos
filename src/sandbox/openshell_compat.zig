// SPDX-License-Identifier: Apache-2.0
// FindingNemos — OpenShell compatibility layer
//
// FindingNemos is derived from NVIDIA NemoClaw which uses OpenShell sandboxes.
// This module detects OpenShell presence without claiming its security properties.
// OpenShell integration is opt-in and only activated when explicitly configured.

const state = @import("../core/state.zig");

pub const CompatStatus = struct {
    openshell_installed: state.Availability = .unknown,
    docker_available: state.Availability = .unknown,
    openclaw_available: state.Availability = .unknown,

    pub fn isFunctional(self: CompatStatus) bool {
        return self.openshell_installed == .available and
            self.docker_available == .available;
    }
};

/// Check OpenShell compatibility status.
/// Phase 1: returns all-unknown. Real detection is Phase 2.
pub fn detect() CompatStatus {
    return .{
        .openshell_installed = .unknown,
        .docker_available = .unknown,
        .openclaw_available = .unknown,
    };
}
