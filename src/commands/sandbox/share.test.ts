// SPDX-FileCopyrightText: Copyright (c) 2026 NVIDIA CORPORATION & AFFILIATES. All rights reserved.
// SPDX-License-Identifier: Apache-2.0

import { beforeEach, describe, expect, it, vi } from "vitest";

const mocks = vi.hoisted(() => {
  class ShareCommandError extends Error {
    lines: readonly string[];
    exitCode: number;

    constructor(lines: string | readonly string[], exitCode = 1) {
      const normalized = Array.isArray(lines) ? lines : [lines];
      super(normalized.join("\n"));
      this.lines = normalized;
      this.exitCode = exitCode;
    }
  }

  return {
    printShareUsageAndExit: vi.fn(() => {
      throw new ShareCommandError("share usage requested");
    }),
    runShareMount: vi.fn().mockResolvedValue(undefined),
    runShareStatus: vi.fn(),
    runShareUnmount: vi.fn(),
    ShareCommandError,
  };
});

vi.mock("../../lib/share-command", () => ({
  printShareUsageAndExit: mocks.printShareUsageAndExit,
  runShareMount: mocks.runShareMount,
  runShareStatus: mocks.runShareStatus,
  runShareUnmount: mocks.runShareUnmount,
  ShareCommandError: mocks.ShareCommandError,
}));

import ShareCommand from "./share";
import ShareMountCommand from "./share/mount";
import ShareStatusCommand from "./share/status";
import ShareUnmountCommand from "./share/unmount";

const rootDir = process.cwd();

describe("share oclif command adapters", () => {
  beforeEach(() => {
    vi.clearAllMocks();
  });

  it("routes parent share usage through the usage action", async () => {
    const error = vi.spyOn(console, "error").mockImplementation(() => undefined);
    const previousExitCode = process.exitCode;
    process.exitCode = undefined;
    try {
      await expect(ShareCommand.run(["alpha"], rootDir)).resolves.toBeUndefined();
      expect(process.exitCode).toBe(1);
      expect(error).toHaveBeenCalledWith("share usage requested");
      expect(mocks.printShareUsageAndExit).toHaveBeenCalledWith(1);
    } finally {
      process.exitCode = previousExitCode;
      error.mockRestore();
    }
  });

  it("maps share subcommand args to share actions", async () => {
    await ShareMountCommand.run(["alpha", "/workspace", "/tmp/alpha"], rootDir);
    await ShareUnmountCommand.run(["alpha", "/tmp/alpha"], rootDir);
    await ShareStatusCommand.run(["alpha", "/tmp/alpha"], rootDir);

    expect(mocks.runShareMount).toHaveBeenCalledWith({
      sandboxName: "alpha",
      remotePath: "/workspace",
      localMount: "/tmp/alpha",
    });
    expect(mocks.runShareUnmount).toHaveBeenCalledWith({
      sandboxName: "alpha",
      localMount: "/tmp/alpha",
    });
    expect(mocks.runShareStatus).toHaveBeenCalledWith({
      sandboxName: "alpha",
      localMount: "/tmp/alpha",
    });
  });

  it("handles ShareCommandError for mount", async () => {
    mocks.runShareMount.mockImplementationOnce(() => {
      throw new mocks.ShareCommandError(["mount error 1", "mount error 2"], 42);
    });
    const error = vi.spyOn(console, "error").mockImplementation(() => undefined);
    const previousExitCode = process.exitCode;
    process.exitCode = undefined;
    try {
      await expect(ShareMountCommand.run(["alpha", "/workspace", "/tmp/alpha"], rootDir)).resolves.toBeUndefined();
      expect(process.exitCode).toBe(42);
      expect(error).toHaveBeenCalledWith("mount error 1");
      expect(error).toHaveBeenCalledWith("mount error 2");
    } finally {
      process.exitCode = previousExitCode;
      error.mockRestore();
    }
  });

  it("propagates unknown errors for mount", async () => {
    const unknownError = new Error("unknown mount error");
    mocks.runShareMount.mockImplementationOnce(() => {
      throw unknownError;
    });
    await expect(ShareMountCommand.run(["alpha", "/workspace", "/tmp/alpha"], rootDir)).rejects.toThrow(unknownError);
  });

  it("handles ShareCommandError for unmount", async () => {
    mocks.runShareUnmount.mockImplementationOnce(() => {
      throw new mocks.ShareCommandError(["unmount error"], 43);
    });
    const error = vi.spyOn(console, "error").mockImplementation(() => undefined);
    const previousExitCode = process.exitCode;
    process.exitCode = undefined;
    try {
      await expect(ShareUnmountCommand.run(["alpha", "/tmp/alpha"], rootDir)).resolves.toBeUndefined();
      expect(process.exitCode).toBe(43);
      expect(error).toHaveBeenCalledWith("unmount error");
    } finally {
      process.exitCode = previousExitCode;
      error.mockRestore();
    }
  });

  it("propagates unknown errors for unmount", async () => {
    const unknownError = new Error("unknown unmount error");
    mocks.runShareUnmount.mockImplementationOnce(() => {
      throw unknownError;
    });
    await expect(ShareUnmountCommand.run(["alpha", "/tmp/alpha"], rootDir)).rejects.toThrow(unknownError);
  });
});
