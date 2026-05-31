// SPDX-FileCopyrightText: Copyright (c) 2026 NVIDIA CORPORATION & AFFILIATES. All rights reserved.
// SPDX-License-Identifier: Apache-2.0

import { beforeEach, describe, expect, it, vi } from "vitest";

const runSandboxSnapshot = vi.hoisted(() => vi.fn().mockResolvedValue(undefined));

vi.mock("../../lib/actions/sandbox/snapshot", () => ({
  runSandboxSnapshot,
}));

import SnapshotCommand from "./snapshot";
import SnapshotCreateCommand from "./snapshot/create";
import SnapshotListCommand from "./snapshot/list";
import SnapshotRestoreCommand from "./snapshot/restore";

const rootDir = process.cwd();

describe("snapshot oclif commands", () => {
  beforeEach(() => {
    runSandboxSnapshot.mockClear();
  });

  it("shows parent snapshot usage through the action", async () => {
    await SnapshotCommand.run(["alpha"], rootDir);

    expect(runSandboxSnapshot).toHaveBeenCalledWith("alpha", { kind: "help" });
  });

  it("rejects unknown parent snapshot args before dispatch", async () => {
    await expect(SnapshotCommand.run(["alpha", "bogus"], rootDir)).rejects.toThrow(/bogus/);

    expect(runSandboxSnapshot).not.toHaveBeenCalled();
  });

  it("runs snapshot list through typed action options", async () => {
    await SnapshotListCommand.run(["alpha"], rootDir);

    expect(runSandboxSnapshot).toHaveBeenCalledWith("alpha", { kind: "list" });
  });

  it("runs snapshot restore with an optional selector and target", async () => {
    await SnapshotRestoreCommand.run(["alpha", "v2", "--to", "beta"], rootDir);

    expect(runSandboxSnapshot).toHaveBeenCalledWith("alpha", {
      kind: "restore",
      selector: "v2",
      to: "beta",
      force: undefined,
      yes: undefined,
    });
  });

  it("threads --force and --yes into the typed restore action (#3756)", async () => {
    await SnapshotRestoreCommand.run(["alpha", "--to", "beta", "--force", "--yes"], rootDir);

    expect(runSandboxSnapshot).toHaveBeenCalledWith("alpha", {
      kind: "restore",
      selector: undefined,
      to: "beta",
      force: true,
      yes: true,
    });
  });

  it("runs snapshot create with an optional label", async () => {
    await SnapshotCreateCommand.run(["alpha", "--name", "before-upgrade"], rootDir);

    expect(runSandboxSnapshot).toHaveBeenCalledWith("alpha", {
      kind: "create",
      name: "before-upgrade",
    });
  });

  it("list handles SnapshotCommandError cleanly", async () => {
    const errorLogSpy = vi.spyOn(console, "error").mockImplementation(() => {});

    const originalExitCode = process.exitCode;
    process.exitCode = undefined;

    runSandboxSnapshot.mockRejectedValue({
      name: "SnapshotCommandError",
      exitCode: 42,
      lines: ["Line 1", "Line 2"],
    });

    await SnapshotListCommand.run(["alpha"], rootDir);

    expect(errorLogSpy).toHaveBeenCalledWith("Line 1");
    expect(errorLogSpy).toHaveBeenCalledWith("Line 2");
    expect(process.exitCode).toBe(42);

    errorLogSpy.mockRestore();
    process.exitCode = originalExitCode;
  });

  it("list re-throws non-SnapshotCommandError errors", async () => {
    const error = new Error("Boom");
    runSandboxSnapshot.mockRejectedValue(error);

    await expect(SnapshotListCommand.run(["alpha"], rootDir)).rejects.toThrow("Boom");
  });
});
