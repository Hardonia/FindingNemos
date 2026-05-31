#!/usr/bin/env bash
# SPDX-FileCopyrightText: Copyright (c) 2026 NVIDIA CORPORATION & AFFILIATES. All rights reserved.
# SPDX-License-Identifier: Apache-2.0

# SPDX-License-Identifier: Apache-2.0
# FindingNemos — doctor script
#
# Checks host prerequisites for running FindingNemos.

set -euo pipefail

echo "FindingNemos Doctor (shell)"
echo "==========================="
echo ""

# Check Zig
if command -v zig &>/dev/null; then
  echo "[ok] Zig: $(zig version)"
else
  echo "[FAIL] Zig: not found in PATH"
  echo "  Install from: https://ziglang.org/download/"
fi

# Check Docker
if command -v docker &>/dev/null; then
  echo "[ok] Docker: $(docker --version 2>/dev/null || echo 'installed')"
else
  echo "[??] Docker: not found (optional)"
fi

# Check Git
if command -v git &>/dev/null; then
  echo "[ok] Git: $(git --version)"
else
  echo "[!!] Git: not found"
fi

echo ""
echo "Run 'findingnemos doctor' for runtime-level checks."
