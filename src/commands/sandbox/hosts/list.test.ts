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
    listSandboxHostAliases: vi.fn(),
    HostAliasFailure,
  };
});

vi.mock("../../../lib/actions/sandbox/host-aliases", () => ({
  listSandboxHostAliases: mocks.listSandboxHostAliases,
}));

import HostsListCommand from "./list";

const rootDir = process.cwd();

describe("sandbox:hosts:list", () => {
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

  it("calls listSandboxHostAliases with correct arguments", async () => {
    await HostsListCommand.run(["alpha"], rootDir);
    expect(mocks.listSandboxHostAliases).toHaveBeenCalledWith("alpha");
  });

  it("handles HostAliasFailure correctly", async () => {
    mocks.listSandboxHostAliases.mockImplementationOnce(() => {
      throw new mocks.HostAliasFailure(["test error"], 2);
    });

    await expect(HostsListCommand.run(["alpha"], rootDir)).resolves.toBeUndefined();
    expect(process.exitCode).toBe(2);
    expect(failSpy).toHaveBeenCalledWith("test error");
  });

  it("throws other errors", async () => {
    const error = new Error("Generic error");
    mocks.listSandboxHostAliases.mockImplementationOnce(() => {
      throw error;
    });

    await expect(HostsListCommand.run(["alpha"], rootDir)).rejects.toThrow("Generic error");
  });
});
