// SPDX-License-Identifier: Apache-2.0
// FindingNemos — sandbox filesystem isolation (stub)

/// Phase 1: Documenting planned filesystem isolation capabilities.
/// Actual bind-mount and tmpfs isolation requires container runtime integration.
pub const IsolationLevel = enum {
    none,
    read_only_root,
    tmpfs_overlay,
    full_isolation,
};
