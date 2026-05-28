// SPDX-License-Identifier: Apache-2.0
// FindingNemos — daemon server
//
// Phase 1 implementation: local JSON-over-stdin protocol.
// HTTP server is a Phase 2 upgrade path.
// This file documents the planned interface without faking HTTP.

const std = @import("std");

pub const ServerState = enum {
    not_started,
    starting,
    running,
    stopping,
    stopped,
    failed,
};

pub const ServerConfig = struct {
    bind: []const u8 = "127.0.0.1",
    port: u16 = 9100,
};

/// Phase 1: The daemon runs as a foreground process reading JSON commands
/// from stdin and writing JSON responses to stdout. This avoids the complexity
/// of an HTTP server while providing the same logical interface.
///
/// Planned endpoints (for Phase 2 HTTP upgrade):
/// - GET  /health       → health check
/// - GET  /status       → runtime status
/// - GET  /workers      → worker list
/// - GET  /models       → model provider list
/// - POST /policy/check → policy check
/// - GET  /proof/events → proof event list
pub const PlannedEndpoint = struct {
    method: []const u8,
    path: []const u8,
    description: []const u8,
};

pub const planned_endpoints = [_]PlannedEndpoint{
    .{ .method = "GET", .path = "/health", .description = "Health check" },
    .{ .method = "GET", .path = "/status", .description = "Runtime status" },
    .{ .method = "GET", .path = "/workers", .description = "Worker list" },
    .{ .method = "GET", .path = "/models", .description = "Model provider list" },
    .{ .method = "POST", .path = "/policy/check", .description = "Policy check" },
    .{ .method = "GET", .path = "/proof/events", .description = "Proof event list" },
};
