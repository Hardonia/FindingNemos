// SPDX-License-Identifier: Apache-2.0
// FindingNemos — config validation
//
// Validates parsed TOML entries against the schema. Reports all errors
// rather than failing on the first one, so operators can fix everything
// in one pass.

const std = @import("std");
const toml = @import("toml.zig");
const schema = @import("schema.zig");

pub const ValidationError = struct {
    section: []const u8,
    key: []const u8,
    message: []const u8,
};

pub const ValidationResult = struct {
    config: schema.Config,
    errors: []const ValidationError,
    warnings: []const ValidationError,
    is_valid: bool,
};

/// Known sections. Entries in unknown sections generate warnings.
const known_sections = [_][]const u8{
    "runtime", "daemon", "sandbox", "policy", "models", "telemetry", "proofpack",
};

fn isKnownSection(section: []const u8) bool {
    for (known_sections) |s| {
        if (std.mem.eql(u8, s, section)) return true;
    }
    return false;
}

/// Validate parsed TOML entries and produce a typed Config.
/// Caller owns the returned errors/warnings slices via allocator.
pub fn validate(allocator: std.mem.Allocator, entries: []const toml.Entry) !ValidationResult {
    var cfg = schema.Config{};
    var errs = std.ArrayList(ValidationError).init(allocator);
    errdefer errs.deinit();
    var warns = std.ArrayList(ValidationError).init(allocator);
    errdefer warns.deinit();

    // Check for unknown sections
    for (entries) |e| {
        if (e.section.len > 0 and !isKnownSection(e.section)) {
            try warns.append(.{
                .section = e.section,
                .key = e.key,
                .message = "unknown section",
            });
        }
    }

    // Populate config from entries
    if (toml.getString(entries, "runtime", "version")) |v| cfg.runtime_version = v;
    if (toml.getBool(entries, "runtime", "debug")) |v| cfg.runtime_debug = v;
    if (toml.getString(entries, "runtime", "log_level")) |v| cfg.runtime_log_level = v;

    if (toml.getBool(entries, "daemon", "enabled")) |v| cfg.daemon_enabled = v;
    if (toml.getString(entries, "daemon", "bind")) |v| cfg.daemon_bind = v;
    if (toml.getInt(entries, "daemon", "port")) |v| {
        if (v > 0 and v <= 65535) {
            cfg.daemon_port = @intCast(v);
        } else {
            try errs.append(.{ .section = "daemon", .key = "port", .message = "port must be 1-65535" });
        }
    }

    if (toml.getString(entries, "sandbox", "runtime")) |v| {
        if (std.mem.eql(u8, v, "none") or std.mem.eql(u8, v, "docker") or std.mem.eql(u8, v, "openshell")) {
            cfg.sandbox_runtime = v;
        } else {
            try errs.append(.{ .section = "sandbox", .key = "runtime", .message = "must be none, docker, or openshell" });
        }
    }
    if (toml.getString(entries, "sandbox", "image")) |v| cfg.sandbox_image = v;

    if (toml.getString(entries, "policy", "default")) |v| {
        if (std.mem.eql(u8, v, "allow") or std.mem.eql(u8, v, "deny")) {
            cfg.policy_default = v;
        } else {
            try errs.append(.{ .section = "policy", .key = "default", .message = "must be allow or deny" });
        }
    }
    if (toml.getString(entries, "policy", "allowlist")) |v| cfg.policy_allowlist = v;
    if (toml.getString(entries, "policy", "denylist")) |v| cfg.policy_denylist = v;
    if (toml.getBool(entries, "policy", "block_private")) |v| cfg.policy_block_private = v;
    if (toml.getBool(entries, "policy", "block_ssrf")) |v| cfg.policy_block_ssrf = v;

    if (toml.getBool(entries, "models", "local_first")) |v| cfg.models_local_first = v;
    if (toml.getString(entries, "models", "ollama_endpoint")) |v| cfg.models_ollama_endpoint = v;
    if (toml.getString(entries, "models", "llamacpp_endpoint")) |v| cfg.models_llamacpp_endpoint = v;
    if (toml.getString(entries, "models", "vllm_endpoint")) |v| cfg.models_vllm_endpoint = v;
    if (toml.getString(entries, "models", "openai_endpoint")) |v| cfg.models_openai_endpoint = v;
    if (toml.getString(entries, "models", "openai_key_env")) |v| cfg.models_openai_key_env = v;

    if (toml.getBool(entries, "telemetry", "enabled")) |v| cfg.telemetry_enabled = v;
    if (toml.getBool(entries, "telemetry", "gpu_probe")) |v| cfg.telemetry_gpu_probe = v;

    if (toml.getString(entries, "proofpack", "dir")) |v| cfg.proofpack_dir = v;
    if (toml.getBool(entries, "proofpack", "redact_secrets")) |v| cfg.proofpack_redact_secrets = v;

    // Security: warn if secrets redaction is disabled
    if (!cfg.proofpack_redact_secrets) {
        try warns.append(.{
            .section = "proofpack",
            .key = "redact_secrets",
            .message = "secret redaction is disabled — secrets may leak to proofpacks",
        });
    }

    const err_slice = try errs.toOwnedSlice();
    const warn_slice = try warns.toOwnedSlice();

    return .{
        .config = cfg,
        .errors = err_slice,
        .warnings = warn_slice,
        .is_valid = err_slice.len == 0,
    };
}

// ---------------------------------------------------------------------------
test "validate minimal valid config" {
    const src =
        \\[runtime]
        \\version = "0.1.0"
    ;
    const entries = try toml.parse(std.testing.allocator, src);
    defer std.testing.allocator.free(entries);

    const result = try validate(std.testing.allocator, entries);
    defer std.testing.allocator.free(result.errors);
    defer std.testing.allocator.free(result.warnings);

    try std.testing.expect(result.is_valid);
    try std.testing.expectEqualStrings("0.1.0", result.config.runtime_version);
}

test "validate rejects bad port" {
    const src =
        \\[daemon]
        \\port = 99999
    ;
    const entries = try toml.parse(std.testing.allocator, src);
    defer std.testing.allocator.free(entries);

    const result = try validate(std.testing.allocator, entries);
    defer std.testing.allocator.free(result.errors);
    defer std.testing.allocator.free(result.warnings);

    try std.testing.expect(!result.is_valid);
    try std.testing.expectEqual(@as(usize, 1), result.errors.len);
}

test "validate warns on unknown section" {
    const src =
        \\[mystery]
        \\key = "val"
    ;
    const entries = try toml.parse(std.testing.allocator, src);
    defer std.testing.allocator.free(entries);

    const result = try validate(std.testing.allocator, entries);
    defer std.testing.allocator.free(result.errors);
    defer std.testing.allocator.free(result.warnings);

    try std.testing.expect(result.is_valid);
    try std.testing.expectEqual(@as(usize, 1), result.warnings.len);
}
