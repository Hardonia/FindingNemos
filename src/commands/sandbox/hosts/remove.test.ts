// SPDX-FileCopyrightText: Copyright (c) 2026 NVIDIA CORPORATION & AFFILIATES. All rights reserved.
// SPDX-License-Identifier: Apache-2.0

import { afterEach, beforeEach, describe, expect, it, vi } from "vitest";

const mocks = vi.hoisted(() => {
  class HostAliasFailure extends Error {
    name = "HostAliasesCommandError";
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
    removeSandboxHostAlias: vi.fn(),
    HostAliasFailure,
  };
});

vi.mock("../../../lib/actions/sandbox/host-aliases", () => ({
  removeSandboxHostAlias: mocks.removeSandboxHostAlias,
}));

import HostsRemoveCommand from "./remove";

const rootDir = process.cwd();

describe("sandbox:hosts:remove", () => {
  let failSpy: any;

  beforeEach(() => {
    vi.clearAllMocks();
    failSpy = vi.spyOn(console, "error").mockImplementation(() => undefined);
    process.exitCode = undefined;
  });

  afterEach(() => {
    failSpy.mockRestore();
    process.exitCode = undefined;
  });

  it("calls removeSandboxHostAlias with correct arguments", async () => {
    await HostsRemoveCommand.run(["alpha", "searxng.local"], rootDir);
    expect(mocks.removeSandboxHostAlias).toHaveBeenCalledWith("alpha", {
      hostname: "searxng.local",
      dryRun: false,
    });
  });

  it("handles dry-run flag", async () => {
    await HostsRemoveCommand.run(["alpha", "searxng.local", "--dry-run"], rootDir);
    expect(mocks.removeSandboxHostAlias).toHaveBeenCalledWith("alpha", {
      hostname: "searxng.local",
      dryRun: true,
    });
  });

  it("handles HostAliasFailure correctly", async () => {
    mocks.removeSandboxHostAlias.mockImplementationOnce(() => {
      throw new mocks.HostAliasFailure(["test error"], 2);
    });

    await expect(HostsRemoveCommand.run(["alpha", "searxng.local"], rootDir)).resolves.toBeUndefined();
    expect(process.exitCode).toBe(2);
    expect(failSpy).toHaveBeenCalledWith("test error");
  });

  it("throws other errors", async () => {
    const error = new Error("Generic error");
    mocks.removeSandboxHostAlias.mockImplementationOnce(() => {
      throw error;
    });

    await expect(HostsRemoveCommand.run(["alpha", "searxng.local"], rootDir)).rejects.toThrow("Generic error");
  });
});
