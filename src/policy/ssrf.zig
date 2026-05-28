// SPDX-License-Identifier: Apache-2.0
// FindingNemos — SSRF validation
//
// Blocks requests to private IP ranges, link-local, metadata endpoints,
// and localhost patterns. Defense-in-depth against server-side request forgery.

const std = @import("std");

/// Returns true if the host matches known SSRF-dangerous patterns.
pub fn isDangerous(host: []const u8) bool {
    // Cloud metadata endpoints
    if (std.mem.eql(u8, host, "169.254.169.254")) return true;
    if (std.mem.eql(u8, host, "metadata.google.internal")) return true;
    if (std.mem.eql(u8, host, "metadata.google.com")) return true;

    // Localhost variations
    if (std.mem.eql(u8, host, "localhost")) return true;
    if (std.mem.eql(u8, host, "127.0.0.1")) return true;
    if (std.mem.eql(u8, host, "::1")) return true;
    if (std.mem.eql(u8, host, "[::1]")) return true;
    if (std.mem.eql(u8, host, "0.0.0.0")) return true;

    // Kubernetes internal
    if (std.mem.endsWith(u8, host, ".internal")) return true;
    if (std.mem.endsWith(u8, host, ".svc.cluster.local")) return true;

    return false;
}

/// Returns true if the host looks like a private/reserved IP address.
/// Checks RFC 1918, link-local, loopback, and carrier-grade NAT ranges.
pub fn isPrivateIp(host: []const u8) bool {
    // 10.x.x.x
    if (std.mem.startsWith(u8, host, "10.")) return true;

    // 172.16.x.x - 172.31.x.x
    if (std.mem.startsWith(u8, host, "172.")) {
        if (host.len >= 6) {
            const second_octet_str = blk: {
                const rest = host[4..];
                const dot = std.mem.indexOf(u8, rest, ".") orelse break :blk rest;
                break :blk rest[0..dot];
            };
            const second = std.fmt.parseInt(u8, second_octet_str, 10) catch return false;
            if (second >= 16 and second <= 31) return true;
        }
    }

    // 192.168.x.x
    if (std.mem.startsWith(u8, host, "192.168.")) return true;

    // 127.x.x.x (loopback)
    if (std.mem.startsWith(u8, host, "127.")) return true;

    // 169.254.x.x (link-local)
    if (std.mem.startsWith(u8, host, "169.254.")) return true;

    // 100.64-127.x.x (carrier-grade NAT)
    if (std.mem.startsWith(u8, host, "100.")) {
        if (host.len >= 6) {
            const rest = host[4..];
            const dot = std.mem.indexOf(u8, rest, ".") orelse return false;
            const second_str = rest[0..dot];
            const second = std.fmt.parseInt(u8, second_str, 10) catch return false;
            if (second >= 64 and second <= 127) return true;
        }
    }

    // IPv6 private
    if (std.mem.startsWith(u8, host, "fd") or std.mem.startsWith(u8, host, "fc")) return true;
    if (std.mem.startsWith(u8, host, "fe80")) return true;

    return false;
}

// ---------------------------------------------------------------------------
test "SSRF: metadata endpoint blocked" {
    try std.testing.expect(isDangerous("169.254.169.254"));
    try std.testing.expect(isDangerous("metadata.google.internal"));
}

test "SSRF: localhost blocked" {
    try std.testing.expect(isDangerous("localhost"));
    try std.testing.expect(isDangerous("127.0.0.1"));
    try std.testing.expect(isDangerous("::1"));
    try std.testing.expect(isDangerous("[::1]"));
    try std.testing.expect(isDangerous("0.0.0.0"));
}

test "SSRF: kubernetes internal blocked" {
    try std.testing.expect(isDangerous("myservice.default.svc.cluster.local"));
}

test "SSRF: public hosts not blocked" {
    try std.testing.expect(!isDangerous("api.openai.com"));
    try std.testing.expect(!isDangerous("huggingface.co"));
    try std.testing.expect(!isDangerous("8.8.8.8"));
}

test "private IPs detected" {
    try std.testing.expect(isPrivateIp("10.0.0.1"));
    try std.testing.expect(isPrivateIp("172.16.0.1"));
    try std.testing.expect(isPrivateIp("192.168.1.1"));
    try std.testing.expect(isPrivateIp("127.0.0.1"));
    try std.testing.expect(isPrivateIp("169.254.0.1"));
}

test "public IPs not flagged" {
    try std.testing.expect(!isPrivateIp("8.8.8.8"));
    try std.testing.expect(!isPrivateIp("1.1.1.1"));
    try std.testing.expect(!isPrivateIp("203.0.113.1"));
}
