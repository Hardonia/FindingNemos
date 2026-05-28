// SPDX-License-Identifier: Apache-2.0
// FindingNemos — config loading
//
// Top-level config module: reads file, parses TOML, validates, returns Config.

const std = @import("std");
const toml = @import("toml.zig");
const validation = @import("validation.zig");
const schema = @import("schema.zig");

pub const Config = schema.Config;
pub const ValidationResult = validation.ValidationResult;

/// Load and validate a config file. Returns the validation result including
/// the Config struct, errors, and warnings. Caller must free the result slices.
pub fn loadFile(allocator: std.mem.Allocator, path: []const u8) !ValidationResult {
    const file = std.fs.cwd().openFile(path, .{}) catch return error.FileNotFound;
    defer file.close();

    const source = file.readToEndAlloc(allocator, 1024 * 1024) catch return error.IoError;
    defer allocator.free(source);

    const entries = try toml.parse(allocator, source);
    defer allocator.free(entries);

    return try validation.validate(allocator, entries);
}

/// Load from string (for testing and embedded configs).
pub fn loadString(allocator: std.mem.Allocator, source: []const u8) !ValidationResult {
    const entries = try toml.parse(allocator, source);
    defer allocator.free(entries);

    return try validation.validate(allocator, entries);
}
