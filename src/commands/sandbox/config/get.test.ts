// SPDX-FileCopyrightText: Copyright (c) 2026 NVIDIA CORPORATION & AFFILIATES. All rights reserved.
// SPDX-License-Identifier: Apache-2.0

import { beforeEach, describe, expect, it, vi } from "vitest";

const mocks = vi.hoisted(() => {
  class SandboxConfigError extends Error {
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
    configGet: vi.fn(),
    SandboxConfigError,
  };
});

vi.mock("../../../lib/sandbox/config", () => ({
  configGet: mocks.configGet,
  SandboxConfigError: mocks.SandboxConfigError,
}));

import SandboxConfigGetCommand from "./get";

const rootDir = process.cwd();

describe("sandbox:config:get command", () => {
  beforeEach(() => {
    vi.clearAllMocks();
  });

  it("calls configGet with correct arguments", async () => {
    await SandboxConfigGetCommand.run(["alpha", "--key", "model", "--format", "yaml"], rootDir);

    expect(mocks.configGet).toHaveBeenCalledWith("alpha", {
      key: "model",
      format: "yaml",
    });
  });

  it("calls configGet with default format when format is not provided", async () => {
    await SandboxConfigGetCommand.run(["alpha", "--key", "model"], rootDir);

    expect(mocks.configGet).toHaveBeenCalledWith("alpha", {
      key: "model",
      format: "json",
    });
  });

  it("handles SandboxConfigError by delegating to failWithLines", async () => {
    mocks.configGet.mockImplementationOnce(() => {
      throw new mocks.SandboxConfigError(["line 1", "line 2"], 42);
    });

    // Mock failWithLines which is inherited from NemoClawCommand
    const failWithLinesSpy = vi.spyOn(SandboxConfigGetCommand.prototype as any, "failWithLines").mockImplementationOnce(() => {
        return;
    });

    await SandboxConfigGetCommand.run(["alpha"], rootDir);

    expect(failWithLinesSpy).toHaveBeenCalledWith(["line 1", "line 2"], 42);
  });

  it("throws other errors normally", async () => {
    const error = new Error("Something else went wrong");
    mocks.configGet.mockImplementationOnce(() => {
      throw error;
    });

    await expect(SandboxConfigGetCommand.run(["alpha"], rootDir)).rejects.toThrow(error);
  });
});
