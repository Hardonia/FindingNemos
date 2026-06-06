// SPDX-License-Identifier: Apache-2.0
// FindingNemos — CLI command dispatch and implementations

const std = @import("std");
const cli = @import("cli.zig");
const app_mod = @import("../core/app.zig");
const json = @import("../core/json.zig");
const time = @import("../core/time.zig");
const state = @import("../core/state.zig");
const config_mod = @import("../config/config.zig");
const toml = @import("../config/toml.zig");
const validation = @import("../config/validation.zig");
const egress = @import("../policy/egress.zig");
const ssrf_mod = @import("../policy/ssrf.zig");
const provider_mod = @import("../inference/provider.zig");
const router = @import("../inference/router.zig");
const openshell = @import("../sandbox/openshell_compat.zig");
const proofpack_mod = @import("../proof/proofpack.zig");
const health_mod = @import("../daemon/health.zig");
const telemetry_sys = @import("../telemetry/system.zig");




/// Dispatch to the appropriate command handler. Returns the exit code.
pub fn dispatch(args: cli.ParsedArgs) u8 {
    if (args.help and args.command.len == 0) {
        printHelp();
        return 0;
    }

    if (std.mem.eql(u8, args.command, "version")) return cmdVersion(args);
    if (std.mem.eql(u8, args.command, "doctor")) return cmdDoctor(args);
    if (std.mem.eql(u8, args.command, "status")) return cmdStatus(args);
    if (std.mem.eql(u8, args.command, "init")) return cmdInit(args);
    if (std.mem.eql(u8, args.command, "config")) return cmdConfig(args);
    if (std.mem.eql(u8, args.command, "daemon")) return cmdDaemon(args);
    if (std.mem.eql(u8, args.command, "worker")) return cmdWorker(args);
    if (std.mem.eql(u8, args.command, "model")) return cmdModel(args);
    if (std.mem.eql(u8, args.command, "policy")) return cmdPolicy(args);
    if (std.mem.eql(u8, args.command, "proofpack")) return cmdProofpack(args);

    if (args.help) {
        printHelp();
        return 0;
    }

    std.io.getStdErr().writer().print("error: unknown command '{s}'\n", .{args.command}) catch {};
    std.io.getStdErr().writer().print("Run 'findingnemos --help' for usage.\n", .{}) catch {};
    return 2;
}

fn printHelp() void {
    std.io.getStdOut().writer().print(
        \\FindingNemos — Zig-first local AI substrate
        \\
        \\USAGE:
        \\    findingnemos <command> [options]
        \\
        \\COMMANDS:
        \\    version             Show version information
        \\    doctor              Check system dependencies and health
        \\    status              Show runtime status
        \\    init                Initialize FindingNemos in the current directory
        \\    config validate     Validate a configuration file
        \\    daemon run          Start the daemon (foreground)
        \\    daemon status       Check daemon status
        \\    worker list         List managed workers
        \\    worker start        Start a worker process
        \\    worker stop         Stop a worker process
        \\    worker logs         Show worker logs
        \\    model list          List configured model providers
        \\    model route         Route a prompt to the best provider
        \\    policy check        Check egress policy for a host
        \\    proofpack export    Export evidence proofpack
        \\
        \\OPTIONS:
        \\    --help              Show this help
        \\    --json              Machine-readable JSON output
        \\    --config <path>     Path to config file
        \\
        \\EXIT CODES:
        \\    0  success
        \\    1  operational failure
        \\    2  invalid input
        \\    3  dependency unavailable
        \\    4  policy denied
        \\    5  degraded state
        \\   10  internal error
        \\
    , .{}) catch {};
}

// ---- version ----
fn cmdVersion(args: cli.ParsedArgs) u8 {
    if (args.json_output) {
        var buf: [128]u8 = undefined;
        var w = json.JsonWriter.init(&buf);
        w.beginObject();
        w.field("name", app_mod.name);
        w.field("version", app_mod.version);
        w.field("language", "zig");
        w.endObject();
        std.io.getStdOut().writer().print("{s}\n", .{w.getWritten()}) catch {};
    } else {
        std.io.getStdOut().writer().print("{s} {s}\n", .{ app_mod.name, app_mod.version }) catch {};
    }
    return 0;
}

// ---- doctor ----
fn cmdDoctor(args: cli.ParsedArgs) u8 {
    var report = health_mod.HealthReport{};

    // Check config
    report.addCheck("config", .healthy, "default config available");

    // Check Docker
    report.addCheck("docker", .unknown, "not probed in scaffold");

    // Check OpenShell
    report.addCheck("openshell", .unknown, "not probed in scaffold");

    // System info
    const snap = telemetry_sys.snapshot();
    if (snap.cpu_count) |cpus| {
        var detail_buf: [32]u8 = undefined;
        var stream = std.io.fixedBufferStream(&detail_buf);
        stream.writer().print("{d} CPUs detected", .{cpus}) catch {};
        report.addCheck("system", .healthy, stream.getWritten());
    }

    report.computeOverall();

    if (args.json_output) {
        var buf: [512]u8 = undefined;
        var w = json.JsonWriter.init(&buf);
        w.beginObject();
        w.field("status", report.status.label());
        w.fieldInt("checks", @intCast(report.check_count));
        w.key("components");
        w.beginArray();
        for (report.checks[0..report.check_count]) |maybe_c| {
            if (maybe_c) |c| {
                w.beginObject();
                w.field("name", c.name);
                w.field("status", c.status.label());
                if (c.detail) |d| w.field("detail", d);
                w.endObject();
            }
        }
        w.endArray();
        w.endObject();
        std.io.getStdOut().writer().print("{s}\n", .{w.getWritten()}) catch {};
    } else {
        std.io.getStdOut().writer().print("FindingNemos Doctor\n", .{}) catch {};
        std.io.getStdOut().writer().print("==================\n\n", .{}) catch {};
        for (report.checks[0..report.check_count]) |maybe_c| {
            if (maybe_c) |c| {
                const icon: []const u8 = switch (c.status) {
                    .healthy => "[ok]",
                    .degraded => "[!!]",
                    .unhealthy => "[FAIL]",
                    .unknown => "[??]",
                };
                std.io.getStdOut().writer().print("  {s} {s}", .{ icon, c.name }) catch {};
                if (c.detail) |d| std.io.getStdOut().writer().print(" — {s}", .{d}) catch {};
                std.io.getStdOut().writer().print("\n", .{}) catch {};
            }
        }
        std.io.getStdOut().writer().print("\nOverall: {s}\n", .{report.status.label()}) catch {};
    }

    return if (report.status == .unhealthy) 1 else if (report.status == .degraded) @as(u8, 5) else 0;
}

// ---- status ----
fn cmdStatus(args: cli.ParsedArgs) u8 {
    const compat = openshell.detect();
    const snap = telemetry_sys.snapshot();

    if (args.json_output) {
        var buf: [1024]u8 = undefined;
        var w = json.JsonWriter.init(&buf);
        w.beginObject();
        w.field("version", app_mod.version);
        w.field("status", "scaffold");
        w.fieldInt("timestamp", time.epochSeconds());
        w.key("dependencies");
        w.beginObject();
        w.field("docker", compat.docker_available.label());
        w.field("openshell", compat.openshell_installed.label());
        w.field("openclaw", compat.openclaw_available.label());
        w.endObject();
        w.key("system");
        w.beginObject();
        if (snap.cpu_count) |cpus| w.fieldInt("cpu_count", @intCast(cpus));
        w.field("gpu", snap.gpu_available.label());
        w.endObject();
        w.key("workers");
        w.beginArray();
        w.endArray();
        w.key("providers");
        w.beginArray();
        w.endArray();
        w.endObject();
        std.io.getStdOut().writer().print("{s}\n", .{w.getWritten()}) catch {};
    } else {
        std.io.getStdOut().writer().print("FindingNemos Status\n", .{}) catch {};
        std.io.getStdOut().writer().print("===================\n\n", .{}) catch {};
        std.io.getStdOut().writer().print("  Version:    {s}\n", .{app_mod.version}) catch {};
        std.io.getStdOut().writer().print("  Phase:      scaffold (Phase 1)\n", .{}) catch {};
        std.io.getStdOut().writer().print("  Docker:     {s}\n", .{compat.docker_available.label()}) catch {};
        std.io.getStdOut().writer().print("  OpenShell:  {s}\n", .{compat.openshell_installed.label()}) catch {};
        std.io.getStdOut().writer().print("  OpenClaw:   {s}\n", .{compat.openclaw_available.label()}) catch {};
        if (snap.cpu_count) |cpus| {
            std.io.getStdOut().writer().print("  CPUs:       {d}\n", .{cpus}) catch {};
        }
        std.io.getStdOut().writer().print("  GPU:        {s}\n", .{snap.gpu_available.label()}) catch {};
        std.io.getStdOut().writer().print("  Workers:    0\n", .{}) catch {};
        std.io.getStdOut().writer().print("  Providers:  0 configured\n", .{}) catch {};
    }
    return 0;
}

// ---- init ----
fn cmdInit(_: cli.ParsedArgs) u8 {
    std.io.getStdOut().writer().print("FindingNemos init\n", .{}) catch {};
    std.io.getStdOut().writer().print("Creating ~/.findingnemos/ directory structure...\n", .{}) catch {};

    // Create home directory
    var home_buf: [std.fs.max_path_bytes]u8 = undefined;
    const paths = @import("../core/paths.zig");
    const home = paths.homeDir(&home_buf) catch {
        std.io.getStdErr().writer().print("error: could not determine home directory\n", .{}) catch {};
        return 1;
    };

    std.fs.makeDirAbsolute(home) catch |err| switch (err) {
        error.PathAlreadyExists => {
            std.io.getStdOut().writer().print("  Directory already exists: {s}\n", .{home}) catch {};
        },
        else => {
            std.io.getStdErr().writer().print("error: could not create {s}\n", .{home}) catch {};
            return 1;
        },
    };

    std.io.getStdOut().writer().print("  Created: {s}\n", .{home}) catch {};
    std.io.getStdOut().writer().print("\nDone. Edit ~/.findingnemos/config.toml to configure.\n", .{}) catch {};
    return 0;
}

// ---- config ----
fn cmdConfig(args: cli.ParsedArgs) u8 {
    if (std.mem.eql(u8, args.subcommand, "validate")) {
        return cmdConfigValidate(args);
    }
    std.io.getStdErr().writer().print("error: unknown config subcommand '{s}'\n", .{args.subcommand}) catch {};
    std.io.getStdErr().writer().print("Usage: findingnemos config validate --config <path>\n", .{}) catch {};
    return 2;
}

fn cmdConfigValidate(args: cli.ParsedArgs) u8 {
    const path = args.config_path orelse {
        std.io.getStdErr().writer().print("error: --config <path> is required\n", .{}) catch {};
        return 2;
    };

    const allocator = std.heap.page_allocator;

    // Read the file
    const file = std.fs.cwd().openFile(path, .{}) catch {
        std.io.getStdErr().writer().print("error: could not open config file: {s}\n", .{path}) catch {};
        return 1;
    };
    defer file.close();

    const source = file.readToEndAlloc(allocator, 1024 * 1024) catch {
        std.io.getStdErr().writer().print("error: could not read config file\n", .{}) catch {};
        return 1;
    };
    defer allocator.free(source);

    const entries = toml.parse(allocator, source) catch {
        std.io.getStdErr().writer().print("error: invalid TOML syntax\n", .{}) catch {};
        return 2;
    };
    defer allocator.free(entries);

    const result = validation.validate(allocator, entries) catch {
        std.io.getStdErr().writer().print("error: validation failed\n", .{}) catch {};
        return 10;
    };
    defer allocator.free(result.errors);
    defer allocator.free(result.warnings);

    if (args.json_output) {
        var buf: [1024]u8 = undefined;
        var w = json.JsonWriter.init(&buf);
        w.beginObject();
        w.fieldBool("valid", result.is_valid);
        w.fieldInt("errors", @intCast(result.errors.len));
        w.fieldInt("warnings", @intCast(result.warnings.len));
        w.endObject();
        std.io.getStdOut().writer().print("{s}\n", .{w.getWritten()}) catch {};
    } else {
        if (result.is_valid) {
            std.io.getStdOut().writer().print("Config valid: {s}\n", .{path}) catch {};
        } else {
            std.io.getStdOut().writer().print("Config INVALID: {s}\n", .{path}) catch {};
        }
        for (result.errors) |e| {
            std.io.getStdOut().writer().print("  ERROR [{s}].{s}: {s}\n", .{ e.section, e.key, e.message }) catch {};
        }
        for (result.warnings) |w_entry| {
            std.io.getStdOut().writer().print("  WARN  [{s}].{s}: {s}\n", .{ w_entry.section, w_entry.key, w_entry.message }) catch {};
        }
    }

    return if (result.is_valid) 0 else 2;
}

// ---- daemon ----
fn cmdDaemon(args: cli.ParsedArgs) u8 {
    if (std.mem.eql(u8, args.subcommand, "run")) {
        std.io.getStdOut().writer().print("FindingNemos daemon starting...\n", .{}) catch {};

        var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
        defer arena.deinit();

        const server = @import("../daemon/server.zig");
        var srv = server.Server.init(arena.allocator(), .{}) catch |err| {
            std.io.getStdErr().writer().print("error: could not init daemon server: {}\n", .{err}) catch {};
            return 1;
        };
        defer srv.deinit();

        srv.start() catch |err| {
            std.io.getStdErr().writer().print("error: could not start daemon server: {}\n", .{err}) catch {};
            return 1;
        };

        std.io.getStdOut().writer().print("Daemon HTTP Server running on 127.0.0.1:8080\n", .{}) catch {};
        std.io.getStdOut().writer().print("Press Ctrl+C to stop.\n", .{}) catch {};

        // Wait indefinitely (Ctrl+C will terminate)
        while (true) {
            std.time.sleep(1 * std.time.ns_per_s);
        }

        return 0;
    }
    if (std.mem.eql(u8, args.subcommand, "status")) {
        if (args.json_output) {
            var buf: [128]u8 = undefined;
            var w = json.JsonWriter.init(&buf);
            w.beginObject();
            w.field("daemon", "not_running");
            w.field("protocol", "json-over-stdin");
            w.endObject();
            std.io.getStdOut().writer().print("{s}\n", .{w.getWritten()}) catch {};
        } else {
            std.io.getStdOut().writer().print("Daemon: not running\n", .{}) catch {};
            std.io.getStdOut().writer().print("Protocol: json-over-stdin (Phase 1)\n", .{}) catch {};
        }
        return 0;
    }
    std.io.getStdErr().writer().print("error: unknown daemon subcommand '{s}'\n", .{args.subcommand}) catch {};
    return 2;
}

// ---- worker ----
fn cmdWorker(args: cli.ParsedArgs) u8 {
    if (std.mem.eql(u8, args.subcommand, "list")) {
        if (args.json_output) {
            std.io.getStdOut().writer().print("{{\"workers\":[]}}\n", .{}) catch {};
        } else {
            std.io.getStdOut().writer().print("No workers configured.\n", .{}) catch {};
        }
        return 0;
    }
    if (std.mem.eql(u8, args.subcommand, "start")) {
        const name = args.name orelse {
            std.io.getStdErr().writer().print("error: --name is required\n", .{}) catch {};
            return 2;
        };
        const cmd = args.cmd orelse {
            std.io.getStdErr().writer().print("error: --cmd is required\n", .{}) catch {};
            return 2;
        };
        std.io.getStdOut().writer().print("Would start worker '{s}' with command: {s}\n", .{ name, cmd }) catch {};
        std.io.getStdOut().writer().print("Note: process spawning requires daemon to be running (Phase 2)\n", .{}) catch {};
        return 0;
    }
    if (std.mem.eql(u8, args.subcommand, "stop")) {
        const name = args.name orelse {
            std.io.getStdErr().writer().print("error: --name is required\n", .{}) catch {};
            return 2;
        };
        std.io.getStdOut().writer().print("Would stop worker '{s}'\n", .{name}) catch {};
        return 0;
    }
    if (std.mem.eql(u8, args.subcommand, "logs")) {
        const name = args.name orelse {
            std.io.getStdErr().writer().print("error: --name is required\n", .{}) catch {};
            return 2;
        };
        std.io.getStdOut().writer().print("No logs available for worker '{s}' (no workers running)\n", .{name}) catch {};
        return 0;
    }
    std.io.getStdErr().writer().print("error: unknown worker subcommand '{s}'\n", .{args.subcommand}) catch {};
    return 2;
}

// ---- model ----
fn cmdModel(args: cli.ParsedArgs) u8 {
    if (std.mem.eql(u8, args.subcommand, "list")) {
        // Build provider list from default config
        var providers: [4]provider_mod.ProviderInfo = undefined;
        providers[0] = provider_mod.ollamaProvider(null);
        providers[1] = provider_mod.llamacppProvider(null);
        providers[2] = provider_mod.vllmProvider(null);
        providers[3] = provider_mod.openaiProvider(null);

        for (&providers) |*p| provider_mod.assessConfig(p);

        if (args.json_output) {
            var buf: [512]u8 = undefined;
            var w = json.JsonWriter.init(&buf);
            w.beginObject();
            w.key("providers");
            w.beginArray();
            for (providers) |p| {
                w.beginObject();
                w.field("name", p.name);
                w.field("kind", p.kind.label());
                w.field("state", p.state.label());
                w.endObject();
            }
            w.endArray();
            w.endObject();
            std.io.getStdOut().writer().print("{s}\n", .{w.getWritten()}) catch {};
        } else {
            std.io.getStdOut().writer().print("Model Providers\n", .{}) catch {};
            std.io.getStdOut().writer().print("===============\n\n", .{}) catch {};
            for (providers) |p| {
                std.io.getStdOut().writer().print("  {s}: {s} ({s})\n", .{ p.name, p.state.label(), p.kind.label() }) catch {};
            }
        }
        return 0;
    }
    if (std.mem.eql(u8, args.subcommand, "route")) {
        std.io.getStdOut().writer().print("Model routing: no providers configured/reachable\n", .{}) catch {};
        std.io.getStdOut().writer().print("Configure providers in config.toml under [models]\n", .{}) catch {};
        return 3;
    }
    std.io.getStdErr().writer().print("error: unknown model subcommand '{s}'\n", .{args.subcommand}) catch {};
    return 2;
}

// ---- policy ----
fn cmdPolicy(args: cli.ParsedArgs) u8 {
    if (std.mem.eql(u8, args.subcommand, "check")) {
        const host = args.host orelse {
            std.io.getStdErr().writer().print("error: --host is required\n", .{}) catch {};
            return 2;
        };

        // Build policy from config or defaults
        var policy = egress.PolicyConfig{};

        // If config file provided, try to load policy settings
        if (args.config_path) |path| {
            const allocator = std.heap.page_allocator;
            if (std.fs.cwd().openFile(path, .{})) |file| {
                defer file.close();
                if (file.readToEndAlloc(allocator, 1024 * 1024)) |source| {
                    defer allocator.free(source);
                    if (toml.parse(allocator, source)) |entries| {
                        defer allocator.free(entries);
                        if (toml.getString(entries, "policy", "allowlist")) |v| policy.allowlist = v;
                        if (toml.getString(entries, "policy", "denylist")) |v| policy.denylist = v;
                        if (toml.getBool(entries, "policy", "block_private")) |v| policy.block_private = v;
                        if (toml.getBool(entries, "policy", "block_ssrf")) |v| policy.block_ssrf = v;
                        if (toml.getString(entries, "policy", "default")) |v| {
                            if (std.mem.eql(u8, v, "allow")) policy.default = .allow;
                        }
                    } else |_| {}
                } else |_| {}
            } else |_| {
                std.io.getStdErr().writer().print("warning: could not open policy config: {s}\n", .{path}) catch {};
            }
        }

        const result = egress.check(policy, host);

        if (args.json_output) {
            var buf: [256]u8 = undefined;
            var w = json.JsonWriter.init(&buf);
            w.beginObject();
            w.field("host", host);
            w.field("decision", result.decision.label());
            w.field("reason", result.reason);
            w.endObject();
            std.io.getStdOut().writer().print("{s}\n", .{w.getWritten()}) catch {};
        } else {
            const icon: []const u8 = switch (result.decision) {
                .allowed => "[ALLOW]",
                .denied => "[DENY]",
                .unknown => "[??]",
                .unsupported => "[N/A]",
            };
            std.io.getStdOut().writer().print("{s} {s} — {s}\n", .{ icon, host, result.reason }) catch {};
        }

        return switch (result.decision) {
            .allowed => 0,
            .denied => 4,
            .unknown => 5,
            .unsupported => 3,
        };
    }
    std.io.getStdErr().writer().print("error: unknown policy subcommand '{s}'\n", .{args.subcommand}) catch {};
    return 2;
}

// ---- proofpack ----
fn cmdProofpack(args: cli.ParsedArgs) u8 {
    if (std.mem.eql(u8, args.subcommand, "export")) {
        const out_dir = args.out orelse {
            std.io.getStdErr().writer().print("error: --out <path> is required\n", .{}) catch {};
            return 2;
        };

        // Build proofpack
        var pp = proofpack_mod.create();
        pp.config_valid = true; // Would be from actual validation
        pp.addEvent("proofpack_export", "proofpack generated by CLI");

        // Create output directory
        std.fs.cwd().makePath(out_dir) catch {
            std.io.getStdErr().writer().print("error: could not create output directory: {s}\n", .{out_dir}) catch {};
            return 1;
        };

        // Write JSON
        var json_buf: [4096]u8 = undefined;
        const json_content = pp.toJson(&json_buf);
        {
            var path_buf: [std.fs.max_path_bytes]u8 = undefined;
            var stream = std.io.fixedBufferStream(&path_buf);
            stream.writer().print("{s}/proofpack.json", .{out_dir}) catch {};
            const json_path = stream.getWritten();
            if (std.fs.cwd().createFile(json_path, .{})) |f| {
                defer f.close();
                f.writeAll(json_content) catch {};
                std.io.getStdOut().writer().print("  Written: {s}\n", .{json_path}) catch {};
            } else |_| {
                std.io.getStdErr().writer().print("error: could not write proofpack.json\n", .{}) catch {};
                return 1;
            }
        }

        // Write Markdown
        var md_buf: [8192]u8 = undefined;
        const md_content = pp.toMarkdown(&md_buf);
        {
            var path_buf: [std.fs.max_path_bytes]u8 = undefined;
            var stream = std.io.fixedBufferStream(&path_buf);
            stream.writer().print("{s}/proofpack.md", .{out_dir}) catch {};
            const md_path = stream.getWritten();
            if (std.fs.cwd().createFile(md_path, .{})) |f| {
                defer f.close();
                f.writeAll(md_content) catch {};
                std.io.getStdOut().writer().print("  Written: {s}\n", .{md_path}) catch {};
            } else |_| {
                std.io.getStdErr().writer().print("error: could not write proofpack.md\n", .{}) catch {};
                return 1;
            }
        }

        std.io.getStdOut().writer().print("\nProofpack exported to: {s}\n", .{out_dir}) catch {};
        return 0;
    }
    std.io.getStdErr().writer().print("error: unknown proofpack subcommand '{s}'\n", .{args.subcommand}) catch {};
    return 2;
}
