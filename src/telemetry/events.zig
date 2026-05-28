// SPDX-License-Identifier: Apache-2.0
// FindingNemos — telemetry events

const time = @import("../core/time.zig");

pub const EventKind = enum {
    startup,
    shutdown,
    worker_started,
    worker_stopped,
    worker_failed,
    config_loaded,
    config_error,
    policy_check,
    route_decision,
    health_check,
    proofpack_exported,
};

pub const Event = struct {
    kind: EventKind,
    timestamp: i64,
    detail: ?[]const u8 = null,

    pub fn now(kind: EventKind, detail: ?[]const u8) Event {
        return .{
            .kind = kind,
            .timestamp = time.epochSeconds(),
            .detail = detail,
        };
    }
};
