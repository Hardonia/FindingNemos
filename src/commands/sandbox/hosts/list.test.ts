// SPDX-FileCopyrightText: Copyright (c) 2026 NVIDIA CORPORATION & AFFILIATES. All rights reserved.
// SPDX-License-Identifier: Apache-2.0

import { beforeEach, describe, expect, it, vi } from "vitest";

const listSandboxHostAliases = vi.hoisted(() => vi.fn().mockResolvedValue(undefined));

vi.mock("../../../lib/actions/sandbox/host-aliases", () => ({
  listSandboxHostAliases,
}));

import HostsListCommand from "./list";

const rootDir = process.cwd();

describe("sandbox hosts list oclif command", () => {
  beforeEach(() => {
    listSandboxHostAliases.mockClear();
    vi.spyOn(console, "error").mockImplementation(() => {});
    process.exitCode = undefined;
  });

  it("lists host aliases for a sandbox", async () => {
    await HostsListCommand.run(["alpha"], rootDir);
    expect(listSandboxHostAliases).toHaveBeenCalledWith("alpha");
  });

  it("handles expected host alias errors by failing gracefully", async () => {
    const error = {
      name: "HostAliasesCommandError",
      lines: ["Expected failure"],
      exitCode: 42
    };
    listSandboxHostAliases.mockImplementation(() => {
      throw error;
    });

    await HostsListCommand.run(["alpha"], rootDir);

    expect(listSandboxHostAliases).toHaveBeenCalledWith("alpha");
    expect(process.exitCode).toBe(42);
    expect(console.error).toHaveBeenCalledWith("Expected failure");
  });

  it("re-throws unexpected errors", async () => {
    const error = new Error("Unexpected crash");
    listSandboxHostAliases.mockImplementation(() => {
      throw error;
    });

    await expect(HostsListCommand.run(["alpha"], rootDir)).rejects.toThrow("Unexpected crash");
    expect(listSandboxHostAliases).toHaveBeenCalledWith("alpha");
  });
});
