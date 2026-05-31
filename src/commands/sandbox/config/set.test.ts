// SPDX-FileCopyrightText: Copyright (c) 2026 NVIDIA CORPORATION & AFFILIATES. All rights reserved.
// SPDX-License-Identifier: Apache-2.0

import { describe, expect, it, vi } from "vitest";
import { SandboxConfigError } from "../../../lib/sandbox/config";
import SandboxConfigSetCommand from "./set";

vi.mock("../../../lib/sandbox/config", () => {
  return {
    configSet: vi.fn(),
    SandboxConfigError: class SandboxConfigError extends Error {
      lines: readonly string[];
      exitCode: number;
      constructor(lines: string | readonly string[], exitCode = 1) {
        const normalized = Array.isArray(lines) ? lines : [lines];
        super(normalized.join("\n"));
        this.name = "SandboxConfigError";
        this.lines = normalized;
        this.exitCode = exitCode;
      }
    },
  };
});

import * as sandboxConfig from "../../../lib/sandbox/config";

describe("sandbox:config:set", () => {
  it("calls failWithLines when configSet throws SandboxConfigError", async () => {
    const errorSpy = vi.spyOn(console, "error").mockImplementation(() => {});
    const configSetSpy = vi
      .mocked(sandboxConfig.configSet)
      .mockRejectedValue(new SandboxConfigError(["Config error line 1"], 2));
    const previousExitCode = process.exitCode;
    process.exitCode = undefined;

    try {
      await SandboxConfigSetCommand.run(["alpha", "--key", "k1", "--value", "v1"], process.cwd());
      expect(process.exitCode).toBe(2);
      expect(errorSpy).toHaveBeenCalledWith("Config error line 1");
    } finally {
      process.exitCode = previousExitCode;
      configSetSpy.mockRestore();
      errorSpy.mockRestore();
    }
  });

  it("rethrows other errors", async () => {
    const configSetSpy = vi.mocked(sandboxConfig.configSet).mockRejectedValue(new Error("Unexpected error"));

    try {
      await expect(SandboxConfigSetCommand.run(["alpha", "--key", "k1", "--value", "v1"], process.cwd())).rejects.toThrow(
        "Unexpected error",
      );
    } finally {
      configSetSpy.mockRestore();
    }
  });
});
