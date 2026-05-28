// SPDX-License-Identifier: Apache-2.0
// FindingNemos — egress policy engine
//
// Evaluates whether outbound requests to a host are allowed, denied,
// or unknown based on operator-configured allowlists, denylists, and
// private-IP blocking rules.

const std = @import("std");
const ssrf = @import("ssrf.zig");

pub const Decision = enum {
    allowed,
    denied,
    unknown,
    unsupported,

    pub fn label(self: Decision) []const u8 {
        return @tagName(self);
    }
};

pub const CheckResult = struct {
    decision: Decision,
    reason: []const u8,
};

pub const PolicyConfig = struct {
    default: Default = .deny,
    allowlist: ?[]const u8 = null, // comma-separated
    denylist: ?[]const u8 = null,
    block_private: bool = true,
    block_ssrf: bool = true,

    pub const Default = enum { allow, deny };
};

/// Check whether egress to `host` is permitted under the given policy.
pub fn check(policy: PolicyConfig, host: []const u8) CheckResult {
    // 1. SSRF checks first — always block dangerous patterns
    if (policy.block_ssrf) {
        if (ssrf.isDangerous(host)) {
            return .{ .decision = .denied, .reason = "SSRF: dangerous host pattern blocked" };
        }
    }

    // 2. Private IP block
    if (policy.block_private) {
        if (ssrf.isPrivateIp(host)) {
            return .{ .decision = .denied, .reason = "private IP range blocked by policy" };
        }
    }

    // 3. Denylist
    if (policy.denylist) |denylist| {
        if (matchesHostList(host, denylist)) {
            return .{ .decision = .denied, .reason = "host is on the denylist" };
        }
    }

    // 4. Allowlist
    if (policy.allowlist) |allowlist| {
        if (matchesHostList(host, allowlist)) {
            return .{ .decision = .allowed, .reason = "host is on the allowlist" };
        }
        // If allowlist is configured but host is not on it, deny
        return .{ .decision = .denied, .reason = "host is not on the allowlist" };
    }

    // 5. Fall through to default
    return switch (policy.default) {
        .allow => .{ .decision = .allowed, .reason = "default policy: allow" },
        .deny => .{ .decision = .denied, .reason = "default policy: deny" },
    };
}

/// Check if host matches any entry in a comma-separated host list.
/// Supports exact match and suffix match (e.g., ".example.com" matches "sub.example.com").
fn matchesHostList(host: []const u8, list: []const u8) bool {
    var iter = std.mem.splitScalar(u8, list, ',');
    while (iter.next()) |raw| {
        const entry = std.mem.trim(u8, raw, " \t");
        if (entry.len == 0) continue;

        // Exact match
        if (std.mem.eql(u8, host, entry)) return true;

        // Suffix match for domain wildcards (e.g., ".github.com")
        if (entry[0] == '.' and std.mem.endsWith(u8, host, entry)) return true;
    }
    return false;
}

// ---------------------------------------------------------------------------
test "deny by default" {
    const policy = PolicyConfig{};
    const result = check(policy, "evil.com");
    try std.testing.expectEqual(Decision.denied, result.decision);
}

test "allowlist permits listed host" {
    const policy = PolicyConfig{
        .allowlist = "api.openai.com, huggingface.co",
    };
    const r1 = check(policy, "api.openai.com");
    try std.testing.expectEqual(Decision.allowed, r1.decision);

    const r2 = check(policy, "evil.com");
    try std.testing.expectEqual(Decision.denied, r2.decision);
}

test "denylist blocks listed host" {
    const policy = PolicyConfig{
        .default = .allow,
        .denylist = "evil.com, malware.org",
    };
    const r1 = check(policy, "evil.com");
    try std.testing.expectEqual(Decision.denied, r1.decision);

    const r2 = check(policy, "safe.com");
    try std.testing.expectEqual(Decision.allowed, r2.decision);
}

test "suffix matching" {
    const policy = PolicyConfig{
        .allowlist = ".openai.com",
    };
    const r1 = check(policy, "api.openai.com");
    try std.testing.expectEqual(Decision.allowed, r1.decision);

    const r2 = check(policy, "openai.com");
    try std.testing.expectEqual(Decision.denied, r2.decision);
}

test "private IP blocked" {
    const policy = PolicyConfig{
        .default = .allow,
        .block_private = true,
    };
    const r = check(policy, "192.168.1.1");
    try std.testing.expectEqual(Decision.denied, r.decision);
}

test "SSRF patterns blocked" {
    const policy = PolicyConfig{
        .default = .allow,
        .block_ssrf = true,
    };
    const r = check(policy, "169.254.169.254");
    try std.testing.expectEqual(Decision.denied, r.decision);
}
