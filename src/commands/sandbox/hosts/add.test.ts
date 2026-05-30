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
    addSandboxHostAlias: vi.fn(),
    HostAliasFailure,
  };
});

vi.mock("../../../lib/actions/sandbox/host-aliases", () => ({
  addSandboxHostAlias: mocks.addSandboxHostAlias,
}));

import HostsAddCommand from "./add";

const rootDir = process.cwd();

describe("sandbox:hosts:add", () => {
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

  it("calls addSandboxHostAlias with correct arguments", async () => {
    await HostsAddCommand.run(["alpha", "searxng.local", "192.168.1.105"], rootDir);
    expect(mocks.addSandboxHostAlias).toHaveBeenCalledWith("alpha", {
      hostname: "searxng.local",
      ip: "192.168.1.105",
      dryRun: false,
    });
  });

  it("handles dry-run flag", async () => {
    await HostsAddCommand.run(["alpha", "searxng.local", "192.168.1.105", "--dry-run"], rootDir);
    expect(mocks.addSandboxHostAlias).toHaveBeenCalledWith("alpha", {
      hostname: "searxng.local",
      ip: "192.168.1.105",
      dryRun: true,
    });
  });

  it("handles HostAliasFailure correctly", async () => {
    mocks.addSandboxHostAlias.mockImplementationOnce(() => {
      throw new mocks.HostAliasFailure(["test error"], 2);
    });

    await expect(HostsAddCommand.run(["alpha", "searxng.local", "192.168.1.105"], rootDir)).resolves.toBeUndefined();
    expect(process.exitCode).toBe(2);
    expect(failSpy).toHaveBeenCalledWith("test error");
  });

  it("throws other errors", async () => {
    const error = new Error("Generic error");
    mocks.addSandboxHostAlias.mockImplementationOnce(() => {
      throw error;
    });

    await expect(HostsAddCommand.run(["alpha", "searxng.local", "192.168.1.105"], rootDir)).rejects.toThrow("Generic error");
  });
});
