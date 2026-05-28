// SPDX-License-Identifier: Apache-2.0
// FindingNemos — health check

const std = @import("std");

pub const HealthStatus = enum {
    healthy,
    degraded,
    unhealthy,
    unknown,

    pub fn label(self: HealthStatus) []const u8 {
        return @tagName(self);
    }
};

pub const HealthReport = struct {
    status: HealthStatus = .unknown,
    version: []const u8 = "0.1.0",
    uptime_secs: ?i64 = null,
    checks: [4]?ComponentCheck = .{ null, null, null, null },
    check_count: usize = 0,

    pub const ComponentCheck = struct {
        name: []const u8,
        status: HealthStatus,
        detail: ?[]const u8 = null,
    };

    pub fn addCheck(self: *HealthReport, name: []const u8, status: HealthStatus, detail: ?[]const u8) void {
        if (self.check_count < 4) {
            self.checks[self.check_count] = .{ .name = name, .status = status, .detail = detail };
            self.check_count += 1;
        }
    }

    pub fn computeOverall(self: *HealthReport) void {
        var any_degraded = false;
        var any_unhealthy = false;
        for (self.checks[0..self.check_count]) |maybe_c| {
            if (maybe_c) |c| {
                if (c.status == .unhealthy) any_unhealthy = true;
                if (c.status == .degraded) any_degraded = true;
            }
        }
        if (any_unhealthy) {
            self.status = .unhealthy;
        } else if (any_degraded) {
            self.status = .degraded;
        } else {
            self.status = .healthy;
        }
    }
};

// ---------------------------------------------------------------------------
test "health report aggregation" {
    var report = HealthReport{};
    report.addCheck("config", .healthy, null);
    report.addCheck("daemon", .degraded, "not running");
    report.computeOverall();
    try std.testing.expectEqual(HealthStatus.degraded, report.status);
}

test "all healthy" {
    var report = HealthReport{};
    report.addCheck("config", .healthy, null);
    report.computeOverall();
    try std.testing.expectEqual(HealthStatus.healthy, report.status);
}
