// SPDX-License-Identifier: Apache-2.0
// FindingNemos — proofpack generation
//
// Collects runtime evidence into a structured proofpack for operator review.
// Proofpacks contain: version, config summary, dependency checks, worker state,
// provider state, policy decisions, route traces, and degraded states.
// All secrets are redacted before export.

const std = @import("std");
const json = @import("../core/json.zig");
const time = @import("../core/time.zig");
const app = @import("../core/app.zig");
const state = @import("../core/state.zig");

pub const ProofEvent = struct {
    kind: []const u8,
    timestamp: i64,
    detail: []const u8,
};

pub const Proofpack = struct {
    version: []const u8 = app.version,
    generated_at: i64 = 0,
    config_valid: bool = false,
    config_errors: usize = 0,
    config_warnings: usize = 0,
    docker_available: state.Availability = .unknown,
    openshell_available: state.Availability = .unknown,
    worker_count: usize = 0,
    provider_count: usize = 0,
    degraded_count: usize = 0,
    events: [64]?ProofEvent = .{null} ** 64,
    event_count: usize = 0,

    pub fn addEvent(self: *Proofpack, kind: []const u8, detail: []const u8) void {
        if (self.event_count < 64) {
            self.events[self.event_count] = .{
                .kind = kind,
                .timestamp = time.epochSeconds(),
                .detail = detail,
            };
            self.event_count += 1;
        }
    }

    /// Serialize to JSON in the provided buffer.
    pub fn toJson(self: *const Proofpack, buf: []u8) []const u8 {
        var w = json.JsonWriter.init(buf);
        w.beginObject();
        w.field("version", self.version);
        w.fieldInt("generated_at", self.generated_at);
        w.fieldBool("config_valid", self.config_valid);
        w.fieldInt("config_errors", @intCast(self.config_errors));
        w.fieldInt("config_warnings", @intCast(self.config_warnings));
        w.field("docker_available", self.docker_available.label());
        w.field("openshell_available", self.openshell_available.label());
        w.fieldInt("worker_count", @intCast(self.worker_count));
        w.fieldInt("provider_count", @intCast(self.provider_count));
        w.fieldInt("degraded_count", @intCast(self.degraded_count));
        w.key("events");
        w.beginArray();
        for (self.events[0..self.event_count]) |maybe_e| {
            if (maybe_e) |e| {
                w.beginObject();
                w.field("kind", e.kind);
                w.fieldInt("timestamp", e.timestamp);
                w.field("detail", e.detail);
                w.endObject();
            }
        }
        w.endArray();
        w.endObject();
        return w.getWritten();
    }

    /// Serialize to Markdown in the provided buffer.
    pub fn toMarkdown(self: *const Proofpack, buf: []u8) []const u8 {
        var stream = std.io.fixedBufferStream(buf);
        const wr = stream.writer();
        wr.print("# FindingNemos Proofpack\n\n", .{}) catch {};
        wr.print("**Version:** {s}\n", .{self.version}) catch {};

        var ts_buf: [20]u8 = undefined;
        const ts = time.formatEpoch(self.generated_at, &ts_buf);
        wr.print("**Generated:** {s}\n\n", .{ts}) catch {};

        wr.print("## Config\n\n", .{}) catch {};
        wr.print("- Valid: {}\n", .{self.config_valid}) catch {};
        wr.print("- Errors: {d}\n", .{self.config_errors}) catch {};
        wr.print("- Warnings: {d}\n\n", .{self.config_warnings}) catch {};

        wr.print("## Dependencies\n\n", .{}) catch {};
        wr.print("- Docker: {s}\n", .{self.docker_available.label()}) catch {};
        wr.print("- OpenShell: {s}\n\n", .{self.openshell_available.label()}) catch {};

        wr.print("## Runtime\n\n", .{}) catch {};
        wr.print("- Workers: {d}\n", .{self.worker_count}) catch {};
        wr.print("- Providers: {d}\n", .{self.provider_count}) catch {};
        wr.print("- Degraded: {d}\n\n", .{self.degraded_count}) catch {};

        if (self.event_count > 0) {
            wr.print("## Events\n\n", .{}) catch {};
            for (self.events[0..self.event_count]) |maybe_e| {
                if (maybe_e) |e| {
                    var ev_ts_buf: [20]u8 = undefined;
                    const ev_ts = time.formatEpoch(e.timestamp, &ev_ts_buf);
                    wr.print("- [{s}] {s}: {s}\n", .{ ev_ts, e.kind, e.detail }) catch {};
                }
            }
        }
        return stream.getWritten();
    }
};

/// Create a new proofpack with current timestamp.
pub fn create() Proofpack {
    return .{
        .generated_at = time.epochSeconds(),
    };
}

// ---------------------------------------------------------------------------
test "proofpack JSON serialization" {
    var pp = Proofpack{};
    pp.generated_at = 1704067200;
    pp.config_valid = true;
    pp.addEvent("startup", "system initialized");

    var buf: [2048]u8 = undefined;
    const out = pp.toJson(&buf);
    try std.testing.expect(out.len > 0);
    try std.testing.expect(std.mem.indexOf(u8, out, "\"version\"") != null);
    try std.testing.expect(std.mem.indexOf(u8, out, "\"startup\"") != null);
}

test "proofpack Markdown serialization" {
    var pp = Proofpack{};
    pp.generated_at = 1704067200;
    pp.config_valid = true;

    var buf: [4096]u8 = undefined;
    const out = pp.toMarkdown(&buf);
    try std.testing.expect(out.len > 0);
    try std.testing.expect(std.mem.indexOf(u8, out, "# FindingNemos Proofpack") != null);
}
