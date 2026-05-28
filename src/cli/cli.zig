// SPDX-License-Identifier: Apache-2.0
// FindingNemos — CLI argument parser
//
// Hand-rolled arg parser for the findingnemos CLI. No external dependencies.
// Supports subcommands, flags, and named options.

const std = @import("std");

pub const ParsedArgs = struct {
    command: []const u8 = "",
    subcommand: []const u8 = "",
    json_output: bool = false,
    config_path: ?[]const u8 = null,
    name: ?[]const u8 = null,
    cmd: ?[]const u8 = null,
    host: ?[]const u8 = null,
    out: ?[]const u8 = null,
    prompt_file: ?[]const u8 = null,
    help: bool = false,
    raw_args: []const [:0]const u8 = &.{},
};

pub fn parse(args: []const [:0]const u8) ParsedArgs {
    var result = ParsedArgs{};
    result.raw_args = args;

    // Skip argv[0] (the binary name)
    if (args.len <= 1) {
        result.help = true;
        return result;
    }

    var i: usize = 1;
    while (i < args.len) : (i += 1) {
        const arg = args[i];

        if (std.mem.eql(u8, arg, "--help") or std.mem.eql(u8, arg, "-h")) {
            result.help = true;
            continue;
        }
        if (std.mem.eql(u8, arg, "--json")) {
            result.json_output = true;
            continue;
        }
        if (std.mem.eql(u8, arg, "--config")) {
            i += 1;
            if (i < args.len) result.config_path = args[i];
            continue;
        }
        if (std.mem.eql(u8, arg, "--name")) {
            i += 1;
            if (i < args.len) result.name = args[i];
            continue;
        }
        if (std.mem.eql(u8, arg, "--cmd")) {
            i += 1;
            if (i < args.len) result.cmd = args[i];
            continue;
        }
        if (std.mem.eql(u8, arg, "--host")) {
            i += 1;
            if (i < args.len) result.host = args[i];
            continue;
        }
        if (std.mem.eql(u8, arg, "--out")) {
            i += 1;
            if (i < args.len) result.out = args[i];
            continue;
        }
        if (std.mem.eql(u8, arg, "--prompt-file")) {
            i += 1;
            if (i < args.len) result.prompt_file = args[i];
            continue;
        }

        // Positional: first is command, second is subcommand
        if (result.command.len == 0) {
            result.command = arg;
        } else if (result.subcommand.len == 0) {
            result.subcommand = arg;
        }
    }

    return result;
}

// ---------------------------------------------------------------------------
test "parse empty args shows help" {
    const args = [_][:0]const u8{@as([:0]const u8, "findingnemos")};
    const result = parse(&args);
    try std.testing.expect(result.help);
}

test "parse version command" {
    const args = [_][:0]const u8{
        @as([:0]const u8, "findingnemos"),
        @as([:0]const u8, "version"),
    };
    const result = parse(&args);
    try std.testing.expectEqualStrings("version", result.command);
}

test "parse with flags" {
    const args = [_][:0]const u8{
        @as([:0]const u8, "findingnemos"),
        @as([:0]const u8, "status"),
        @as([:0]const u8, "--json"),
    };
    const result = parse(&args);
    try std.testing.expectEqualStrings("status", result.command);
    try std.testing.expect(result.json_output);
}

test "parse subcommand with options" {
    const args = [_][:0]const u8{
        @as([:0]const u8, "findingnemos"),
        @as([:0]const u8, "policy"),
        @as([:0]const u8, "check"),
        @as([:0]const u8, "--host"),
        @as([:0]const u8, "example.com"),
    };
    const result = parse(&args);
    try std.testing.expectEqualStrings("policy", result.command);
    try std.testing.expectEqualStrings("check", result.subcommand);
    try std.testing.expectEqualStrings("example.com", result.host.?);
}
