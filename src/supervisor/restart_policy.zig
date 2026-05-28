// SPDX-License-Identifier: Apache-2.0
const std = @import("std");

pub const RestartPolicy = enum {
    disabled,
    manual,
    on_failure,
};

pub fn shouldRestart(policy: RestartPolicy, exit_code: u8) bool {
    switch (policy) {
        .disabled => return false,
        .manual => return false,
        .on_failure => return exit_code != 0,
    }
}
