// SPDX-License-Identifier: Apache-2.0
const std = @import("std");

pub const Command = enum {
    version,
    doctor,
    status,
    init,
    config_validate,
    daemon_run,
    daemon_status,
    worker_list,
    worker_start,
    worker_stop,
    worker_logs,
    model_list,
    model_route,
    policy_check,
    proofpack_export,
    unknown,
};
