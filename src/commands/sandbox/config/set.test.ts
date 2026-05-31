// SPDX-FileCopyrightText: Copyright (c) 2026 NVIDIA CORPORATION & AFFILIATES. All rights reserved.
// SPDX-License-Identifier: Apache-2.0

import { describe, expect, it, vi, beforeEach, afterEach } from "vitest";

import SandboxConfigSetCommand from "./set";
import * as sandboxConfig from "../../../lib/sandbox/config";

vi.mock("../../../lib/sandbox/config", () => {
  return {
    configSet: vi.fn(),
    SandboxConfigError: class SandboxConfigError extends Error {
      lines: string[];
      exitCode: number;
      constructor(lines: string[], exitCode = 1) {
        super(lines.join("\n"));
        this.lines = lines;
        this.exitCode = exitCode;
      }
    },
  };
});

describe("SandboxConfigSetCommand", () => {
  let consoleErrorSpy: ReturnType<typeof vi.spyOn>;
  let processExitCode: number | undefined;

  beforeEach(() => {
    vi.clearAllMocks();
    consoleErrorSpy = vi.spyOn(console, "error").mockImplementation(() => {});
    processExitCode = process.exitCode;
    process.exitCode = undefined;
  });

  afterEach(() => {
    process.exitCode = processExitCode;
  });

  it("calls configSet with proper arguments", async () => {
    await SandboxConfigSetCommand.run([
      "test-sandbox",
      "--key",
      "model",
      "--value",
      "nvidia/nemotron",
      "--restart",
      "--config-accept-new-path"
    ]);

    expect(sandboxConfig.configSet).toHaveBeenCalledWith("test-sandbox", {
      key: "model",
      value: "nvidia/nemotron",
      restart: true,
      acceptNewPath: true,
    });
  });

  it("catches SandboxConfigError and calls failWithLines", async () => {
    const error = new sandboxConfig.SandboxConfigError(["Error line 1", "Error line 2"], 42);
    vi.mocked(sandboxConfig.configSet).mockRejectedValueOnce(error);

    await expect(SandboxConfigSetCommand.run([
      "test-sandbox",
      "--key",
      "model",
      "--value",
      "nvidia/nemotron"
    ])).resolves.toBeUndefined();

    // failWithLines calls console.error for each line and setExitCode
    expect(consoleErrorSpy).toHaveBeenCalledWith("Error line 1");
    expect(consoleErrorSpy).toHaveBeenCalledWith("Error line 2");
    expect(process.exitCode).toBe(42);
  });

  it("re-throws non-SandboxConfigError", async () => {
    const error = new Error("General error");
    vi.mocked(sandboxConfig.configSet).mockRejectedValueOnce(error);

    await expect(SandboxConfigSetCommand.run([
      "test-sandbox",
      "--key",
      "model",
      "--value",
      "nvidia/nemotron"
    ])).rejects.toThrow("General error");
  });
});
