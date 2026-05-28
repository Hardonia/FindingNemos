// SPDX-License-Identifier: Apache-2.0
// FindingNemos — core error types
//
// Unified error set for the FindingNemos runtime. Every module surfaces
// errors through this set so that CLI exit-code mapping is deterministic.

const std = @import("std");

/// Exit codes per the FindingNemos convention.
pub const ExitCode = enum(u8) {
    success = 0,
    operational_failure = 1,
    invalid_input = 2,
    dependency_unavailable = 3,
    policy_denied = 4,
    degraded = 5,
    internal = 10,
};

/// Unified error set covering every recoverable failure path.
pub const Error = error{
    // --- operational (exit 1) ---
    IoError,
    FileNotFound,
    SpawnFailed,
    DaemonUnreachable,
    WorkerNotFound,
    Timeout,
    ProcessExitFailure,
    HttpRequestFailed,

    // --- invalid input (exit 2) ---
    InvalidConfig,
    MissingField,
    InvalidToml,
    UnknownCommand,
    InvalidArgument,
    MissingArgument,

    // --- dependency unavailable (exit 3) ---
    DockerUnavailable,
    OpenShellUnavailable,
    OllamaUnavailable,
    ProviderUnavailable,
    ZigUnavailable,
    GpuUnavailable,

    // --- policy denied (exit 4) ---
    EgressDenied,
    SsrfBlocked,
    PolicyDenied,

    // --- degraded (exit 5) ---
    DegradedState,
    PartialResult,

    // --- internal (exit 10) ---
    InvariantViolation,
    OutOfMemory,
    BufferOverflow,
};

/// Map an Error to its deterministic exit code.
pub fn exitCode(err: Error) ExitCode {
    return switch (err) {
        error.IoError,
        error.FileNotFound,
        error.SpawnFailed,
        error.DaemonUnreachable,
        error.WorkerNotFound,
        error.Timeout,
        error.ProcessExitFailure,
        error.HttpRequestFailed,
        => .operational_failure,

        error.InvalidConfig,
        error.MissingField,
        error.InvalidToml,
        error.UnknownCommand,
        error.InvalidArgument,
        error.MissingArgument,
        => .invalid_input,

        error.DockerUnavailable,
        error.OpenShellUnavailable,
        error.OllamaUnavailable,
        error.ProviderUnavailable,
        error.ZigUnavailable,
        error.GpuUnavailable,
        => .dependency_unavailable,

        error.EgressDenied,
        error.SsrfBlocked,
        error.PolicyDenied,
        => .policy_denied,

        error.DegradedState,
        error.PartialResult,
        => .degraded,

        error.InvariantViolation,
        error.OutOfMemory,
        error.BufferOverflow,
        => .internal,
    };
}

/// Human-readable label for operator output.
pub fn label(err: Error) []const u8 {
    return @errorName(err);
}

// ---------------------------------------------------------------------------
test "exit code mapping covers all errors" {
    // Compile-time guarantee: if a new error is added to Error but not to
    // exitCode(), the switch becomes non-exhaustive and fails to compile.
    // This test simply exercises the function at runtime for coverage.
    const cases = [_]Error{
        error.IoError,
        error.InvalidConfig,
        error.DockerUnavailable,
        error.EgressDenied,
        error.DegradedState,
        error.InvariantViolation,
    };
    for (cases) |e| {
        const code = exitCode(e);
        try std.testing.expect(@intFromEnum(code) <= 10);
    }
}

test "label returns non-empty string" {
    const l = label(error.IoError);
    try std.testing.expect(l.len > 0);
}
