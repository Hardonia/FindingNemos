// SPDX-License-Identifier: Apache-2.0
// FindingNemos — memory telemetry (stub)

/// Phase 1: Memory probing requires OS-specific APIs.
/// Linux: /proc/meminfo. Windows: GlobalMemoryStatusEx.
/// Not implemented in scaffold.
pub fn totalBytes() ?u64 {
    return null;
}

pub fn availableBytes() ?u64 {
    return null;
}
