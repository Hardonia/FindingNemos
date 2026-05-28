// SPDX-License-Identifier: Apache-2.0
// FindingNemos — Daemon HTTP Server

const std = @import("std");
const health = @import("health.zig");
const json = @import("../core/json.zig");
const app_mod = @import("../core/app.zig");

pub const ServerOptions = struct {
    port: u16 = 8080,
    host: []const u8 = "127.0.0.1",
};

pub const Server = struct {
    allocator: std.mem.Allocator,
    options: ServerOptions,
    tcp_server: std.net.Server,
    running: std.atomic.Value(bool),
    thread: ?std.Thread = null,

    pub fn init(allocator: std.mem.Allocator, options: ServerOptions) !*Server {
        const addr = try std.net.Address.resolveIp(options.host, options.port);
        const tcp_server = try addr.listen(.{
            .reuse_address = true,
        });

        const self = try allocator.create(Server);
        self.* = .{
            .allocator = allocator,
            .options = options,
            .tcp_server = tcp_server,
            .running = std.atomic.Value(bool).init(false),
        };
        return self;
    }

    pub fn start(self: *Server) !void {
        self.running.store(true, .seq_cst);
        self.thread = try std.Thread.spawn(.{}, acceptLoop, .{self});
    }

    pub fn stop(self: *Server) void {
        self.running.store(false, .seq_cst);
        // Closing the underlying socket interrupts accept()
        self.tcp_server.stream.close();
        if (self.thread) |t| {
            t.join();
            self.thread = null;
        }
    }

    pub fn deinit(self: *Server) void {
        self.stop();
        self.allocator.destroy(self);
    }

    fn acceptLoop(self: *Server) void {
        while (self.running.load(.seq_cst)) {
            const conn = self.tcp_server.accept() catch |err| {
                if (!self.running.load(.seq_cst)) return; // Stopped
                std.log.err("accept failed: {}", .{err});
                continue;
            };

            handleConnection(self, conn) catch |err| {
                std.log.err("handle connection error: {}", .{err});
            };
        }
    }

    fn handleConnection(self: *Server, conn: std.net.Server.Connection) !void {
        defer conn.stream.close();

        var read_buffer: [4096]u8 = undefined;
        var http_server = std.http.Server.init(conn, &read_buffer);

        var request = http_server.receiveHead() catch |err| switch (err) {
            error.HttpConnectionClosing => return,
            else => return err,
        };

        const target = request.head.target;
        const method = request.head.method;

        if (std.mem.eql(u8, target, "/api/v1/health") and method == .GET) {
            try handleHealth(self, &request);
        } else if (std.mem.eql(u8, target, "/api/v1/status") and method == .GET) {
            try handleStatus(self, &request);
        } else {
            try handleNotFound(&request);
        }
    }

    fn handleHealth(_: *Server, request: *std.http.Server.Request) !void {
        var report = health.HealthReport{};
        report.addCheck("daemon", .healthy, "HTTP server running");
        report.computeOverall();

        var buf: [512]u8 = undefined;
        var w = json.JsonWriter.init(&buf);
        w.beginObject();
        w.field("status", report.status.label());
        w.endObject();

        const body = w.getWritten();

        try request.respond(body, .{
            .status = .ok,
            .extra_headers = &.{
                .{ .name = "Content-Type", .value = "application/json" },
            },
        });
    }

    fn handleStatus(_: *Server, request: *std.http.Server.Request) !void {
        var buf: [512]u8 = undefined;
        var w = json.JsonWriter.init(&buf);
        w.beginObject();
        w.field("version", app_mod.version);
        w.field("app", app_mod.name);
        w.field("status", "running");
        w.endObject();

        const body = w.getWritten();

        try request.respond(body, .{
            .status = .ok,
            .extra_headers = &.{
                .{ .name = "Content-Type", .value = "application/json" },
            },
        });
    }

    fn handleNotFound(request: *std.http.Server.Request) !void {
        try request.respond("{\"error\":\"not found\"}", .{
            .status = .not_found,
            .extra_headers = &.{
                .{ .name = "Content-Type", .value = "application/json" },
            },
        });
    }
};

test "server init" {
    const allocator = std.testing.allocator;
    const server = try Server.init(allocator, .{ .port = 0 }); // OS assigned port
    defer server.deinit();
}
