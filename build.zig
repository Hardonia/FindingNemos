// SPDX-License-Identifier: Apache-2.0
// FindingNemos — Zig-first local AI substrate
//
// Build configuration for the FindingNemos CLI binary and tests.

const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    // ---------- Main CLI executable ----------
    const exe = b.addExecutable(.{
        .name = "findingnemos",
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = optimize,
    });

    b.installArtifact(exe);

    // ---------- Run step ----------
    const run_cmd = b.addRunArtifact(exe);
    run_cmd.step.dependOn(b.getInstallStep());
    if (b.args) |args| {
        run_cmd.addArgs(args);
    }

    const run_step = b.step("run", "Run the FindingNemos CLI");
    run_step.dependOn(&run_cmd.step);

    // ---------- Tests ----------
    // Collect test modules. Each source file with `test` blocks is testable.
    const test_targets = [_][]const u8{
        "src/core/errors.zig",
        "src/core/result.zig",
        "src/core/state.zig",
        "src/core/ids.zig",
        "src/core/time.zig",
        "src/core/paths.zig",
        "src/core/json.zig",
        "src/config/toml.zig",
        "src/config/validation.zig",
        "src/policy/egress.zig",
        "src/policy/ssrf.zig",
        "src/inference/provider.zig",
        "src/inference/router.zig",
        "src/inference/credentials.zig",
        "src/proof/proofpack.zig",
        "src/proof/evidence.zig",
        "src/supervisor/process.zig",
        "src/supervisor/restart_policy.zig",
        "src/daemon/health.zig",
        "src/daemon/server.zig",
        "src/cli/cli.zig",
    };

    const test_step = b.step("test", "Run all unit tests");

    for (test_targets) |path| {
        const t = b.addTest(.{
            .root_source_file = b.path(path),
            .target = target,
            .optimize = optimize,
        });
        const run_t = b.addRunArtifact(t);
        test_step.dependOn(&run_t.step);
    }

    // ---------- Format check step ----------
    const fmt_step = b.step("fmt", "Check Zig formatting");
    const fmt = b.addFmt(.{
        .paths = &.{"src"},
        .check = true,
    });
    fmt_step.dependOn(&fmt.step);
}
