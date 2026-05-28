// SPDX-License-Identifier: Apache-2.0
// FindingNemos — Test index

comptime {
    _ = @import("core/errors.zig");
    _ = @import("core/result.zig");
    _ = @import("core/state.zig");
    _ = @import("core/ids.zig");
    _ = @import("core/time.zig");
    _ = @import("core/paths.zig");
    _ = @import("core/json.zig");
    
    _ = @import("config/toml.zig");
    _ = @import("config/validation.zig");
    
    _ = @import("policy/egress.zig");
    _ = @import("policy/ssrf.zig");
    
    _ = @import("inference/provider.zig");
    _ = @import("inference/router.zig");
    _ = @import("inference/credentials.zig");
    
    _ = @import("proof/proofpack.zig");
    _ = @import("proof/evidence.zig");
    
    _ = @import("supervisor/process.zig");
    _ = @import("supervisor/restart_policy.zig");
    
    _ = @import("daemon/health.zig");
    _ = @import("daemon/server.zig");
    
    _ = @import("cli/cli.zig");
    _ = @import("cli/commands.zig");
}
