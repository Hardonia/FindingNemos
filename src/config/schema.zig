// SPDX-License-Identifier: Apache-2.0
const std = @import("std");

pub const Config = struct {
    runtime: RuntimeConfig = .{},
    daemon: DaemonConfig = .{},
    sandbox: SandboxConfig = .{},
    policy: PolicyConfig = .{},
    models: ModelsConfig = .{},
    telemetry: TelemetryConfig = .{},
    proofpack: ProofpackConfig = .{},
};

pub const RuntimeConfig = struct {
    debug: bool = false,
};

pub const DaemonConfig = struct {
    port: u16 = 8080,
};

pub const SandboxConfig = struct {
    provider: []const u8 = "docker",
};

pub const PolicyConfig = struct {
    allowlist: [][]const u8 = &[_][]const u8{},
    denylist: [][]const u8 = &[_][]const u8{},
};

pub const ModelsConfig = struct {
    providers: [][]const u8 = &[_][]const u8{},
};

pub const TelemetryConfig = struct {
    enabled: bool = true,
};

pub const ProofpackConfig = struct {
    export_path: []const u8 = "/tmp/findingnemos/proofpacks",
};
