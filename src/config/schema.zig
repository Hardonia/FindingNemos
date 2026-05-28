// SPDX-License-Identifier: Apache-2.0
// FindingNemos — config schema
//
// Typed configuration struct populated from TOML entries.
// Every field has a safe default. Missing optional fields are null, not empty.

const std = @import("std");

pub const Config = struct {
    // [runtime]
    runtime_version: []const u8 = "0.1.0",
    runtime_debug: bool = false,
    runtime_log_level: []const u8 = "info",

    // [daemon]
    daemon_enabled: bool = false,
    daemon_bind: []const u8 = "127.0.0.1",
    daemon_port: u16 = 9100,

    // [sandbox]
    sandbox_runtime: []const u8 = "none", // "none" | "docker" | "openshell"
    sandbox_image: ?[]const u8 = null,

    // [policy]
    policy_default: []const u8 = "deny", // "allow" | "deny"
    policy_allowlist: ?[]const u8 = null, // comma-separated hosts
    policy_denylist: ?[]const u8 = null,
    policy_block_private: bool = true,
    policy_block_ssrf: bool = true,

    // [models]
    models_local_first: bool = true,
    models_ollama_endpoint: ?[]const u8 = null,
    models_llamacpp_endpoint: ?[]const u8 = null,
    models_vllm_endpoint: ?[]const u8 = null,
    models_openai_endpoint: ?[]const u8 = null,
    models_openai_key_env: ?[]const u8 = null, // env var name, NOT the key itself

    // [telemetry]
    telemetry_enabled: bool = true,
    telemetry_gpu_probe: bool = false, // disabled by default until implemented

    // [proofpack]
    proofpack_dir: ?[]const u8 = null,
    proofpack_redact_secrets: bool = true,
};
