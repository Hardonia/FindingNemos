// SPDX-License-Identifier: Apache-2.0
// FindingNemos — Docker availability detection
//
// Checks whether Docker is available by looking for the `docker` command.
// Does NOT claim sandbox security from Docker alone.

const std = @import("std");
const state = @import("../core/state.zig");

/// Check Docker availability by running `docker version --format json`.
/// Returns availability status without making any security claims.
pub fn checkAvailability() state.Availability {
    // Phase 1: We check if Docker CLI is in PATH by attempting to spawn it.
    // This is a best-effort check. Real container runtime verification
    // requires inspecting dockerd socket, which is Phase 2.
    //
    // SECURITY NOTE: Docker presence does NOT imply sandbox security.
    // Container isolation depends on kernel capabilities, seccomp profiles,
    // user namespaces, and runtime configuration — none of which are
    // verified by this check.
    return .unknown; // Honest: we haven't probed yet in this scaffold
}
