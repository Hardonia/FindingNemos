// SPDX-License-Identifier: Apache-2.0

pub const FindingNemosError = error{
    OperationalFailure,
    InvalidUserInput,
    InvalidConfig,
    DependencyUnavailable,
    PolicyDenied,
    DegradedStateDetected,
    InternalInvariantViolation,
    NotImplemented,
};

pub const ExitCode = enum(u8) {
    success = 0,
    operational_failure = 1,
    invalid_user_input_or_config = 2,
    dependency_unavailable = 3,
    policy_denied = 4,
    degraded_state = 5,
    internal_invariant_violation = 10,

    pub fn fromError(err: anyerror) ExitCode {
        return switch (err) {
            FindingNemosError.OperationalFailure => .operational_failure,
            FindingNemosError.InvalidUserInput => .invalid_user_input_or_config,
            FindingNemosError.InvalidConfig => .invalid_user_input_or_config,
            FindingNemosError.DependencyUnavailable => .dependency_unavailable,
            FindingNemosError.PolicyDenied => .policy_denied,
            FindingNemosError.DegradedStateDetected => .degraded_state,
            FindingNemosError.InternalInvariantViolation => .internal_invariant_violation,
            else => .operational_failure,
        };
    }
};
