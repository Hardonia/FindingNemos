// SPDX-FileCopyrightText: Copyright (c) 2026 NVIDIA CORPORATION & AFFILIATES. All rights reserved.
// SPDX-License-Identifier: Apache-2.0

export function isNonInteractiveEnv(): boolean {
  return process.env.NEMOCLAW_NON_INTERACTIVE === "1";
}
