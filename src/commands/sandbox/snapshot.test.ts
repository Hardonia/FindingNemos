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

  it("handles known snapshot command errors gracefully during create", async () => {
    const error = new Error("Intentional");
    Object.assign(error, {
      name: "SnapshotCommandError",
      exitCode: 42,
      lines: ["alpha error", "beta error"],
    });
    runSandboxSnapshot.mockRejectedValueOnce(error);

    const previousExitCode = process.exitCode;
    process.exitCode = undefined;
    const consoleError = vi.spyOn(console, "error").mockImplementation(() => {});

    try {
      await expect(SnapshotCreateCommand.run(["alpha"], rootDir)).resolves.toBeUndefined();
      expect(process.exitCode).toBe(42);
      expect(consoleError).toHaveBeenCalledWith("alpha error");
      expect(consoleError).toHaveBeenCalledWith("beta error");
    } finally {
      process.exitCode = previousExitCode;
      consoleError.mockRestore();
    }
  });

  it("re-throws unknown errors from the snapshot action during create", async () => {
    const error = new Error("Generic error");
    runSandboxSnapshot.mockRejectedValueOnce(error);

    await expect(SnapshotCreateCommand.run(["alpha"], rootDir)).rejects.toThrow("Generic error");
  });

  it("handles known snapshot command errors gracefully during restore", async () => {
    const error = new Error("Intentional");
    Object.assign(error, {
      name: "SnapshotCommandError",
      exitCode: 42,
      lines: ["alpha error", "beta error"],
    });
    runSandboxSnapshot.mockRejectedValueOnce(error);

    const previousExitCode = process.exitCode;
    process.exitCode = undefined;
    const consoleError = vi.spyOn(console, "error").mockImplementation(() => {});

    try {
      await expect(SnapshotRestoreCommand.run(["alpha"], rootDir)).resolves.toBeUndefined();
      expect(process.exitCode).toBe(42);
      expect(consoleError).toHaveBeenCalledWith("alpha error");
      expect(consoleError).toHaveBeenCalledWith("beta error");
    } finally {
      process.exitCode = previousExitCode;
      consoleError.mockRestore();
    }
  });

  it("re-throws unknown errors from the snapshot action during restore", async () => {
    const error = new Error("Generic error");
    runSandboxSnapshot.mockRejectedValueOnce(error);

    await expect(SnapshotRestoreCommand.run(["alpha"], rootDir)).rejects.toThrow("Generic error");
  });

  it("handles known snapshot command errors gracefully during list", async () => {
    const error = new Error("Intentional");
    Object.assign(error, {
      name: "SnapshotCommandError",
      exitCode: 42,
      lines: ["alpha error", "beta error"],
    });
    runSandboxSnapshot.mockRejectedValueOnce(error);

    const previousExitCode = process.exitCode;
    process.exitCode = undefined;
    const consoleError = vi.spyOn(console, "error").mockImplementation(() => {});

    try {
      await expect(SnapshotListCommand.run(["alpha"], rootDir)).resolves.toBeUndefined();
      expect(process.exitCode).toBe(42);
      expect(consoleError).toHaveBeenCalledWith("alpha error");
      expect(consoleError).toHaveBeenCalledWith("beta error");
    } finally {
      process.exitCode = previousExitCode;
      consoleError.mockRestore();
    }
  });

  it("re-throws unknown errors from the snapshot action during list", async () => {
    const error = new Error("Generic error");
    runSandboxSnapshot.mockRejectedValueOnce(error);

    await expect(SnapshotListCommand.run(["alpha"], rootDir)).rejects.toThrow("Generic error");
  });

  it("handles known snapshot command errors gracefully during parent command", async () => {
    const error = new Error("Intentional");
    Object.assign(error, {
      name: "SnapshotCommandError",
      exitCode: 42,
      lines: ["alpha error", "beta error"],
    });
    runSandboxSnapshot.mockRejectedValueOnce(error);

    const previousExitCode = process.exitCode;
    process.exitCode = undefined;
    const consoleError = vi.spyOn(console, "error").mockImplementation(() => {});

    try {
      await expect(SnapshotCommand.run(["alpha"], rootDir)).resolves.toBeUndefined();
      expect(process.exitCode).toBe(42);
      expect(consoleError).toHaveBeenCalledWith("alpha error");
      expect(consoleError).toHaveBeenCalledWith("beta error");
    } finally {
      process.exitCode = previousExitCode;
      consoleError.mockRestore();
    }
  });

  it("re-throws unknown errors from the snapshot action during parent command", async () => {
    const error = new Error("Generic error");
    runSandboxSnapshot.mockRejectedValueOnce(error);

    await expect(SnapshotCommand.run(["alpha"], rootDir)).rejects.toThrow("Generic error");
  });
});
