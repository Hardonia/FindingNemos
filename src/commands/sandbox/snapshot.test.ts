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

  it("handles SnapshotCommandError in list command by failing with lines", async () => {
    const errorLog = vi.spyOn(console, "error").mockImplementation(() => undefined);
    try {
      const err = new Error("Test failed");
      err.name = "SnapshotCommandError";
      (err as any).exitCode = 99;
      (err as any).lines = ["First error line", "Second error line"];
      runSandboxSnapshot.mockRejectedValueOnce(err);

      await SnapshotListCommand.run(["alpha"], rootDir);

      expect(errorLog).toHaveBeenCalledWith("First error line");
      expect(errorLog).toHaveBeenCalledWith("Second error line");
      expect(process.exitCode).toBe(99);
    } finally {
      errorLog.mockRestore();
    }
  });

  it("re-throws standard errors in list command", async () => {
    const err = new Error("Standard error");
    runSandboxSnapshot.mockRejectedValueOnce(err);

    await expect(SnapshotListCommand.run(["alpha"], rootDir)).rejects.toThrow("Standard error");
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
});
