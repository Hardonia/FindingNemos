// SPDX-License-Identifier: Apache-2.0
// FindingNemos — daemon protocol

pub const Request = struct {
    command: []const u8,
    args: ?[]const u8 = null,
};

pub const Response = struct {
    status: []const u8,
    data: ?[]const u8 = null,
    error_msg: ?[]const u8 = null,
};
