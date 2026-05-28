<!-- SPDX-License-Identifier: Apache-2.0 -->

# Verification & Safety

FindingNemos treats verification as a primary goal.

## The Smoke Test
The primary verification gateway is `scripts/smoke.sh`. This script:
1. Builds the project.
2. Runs all unit tests.
3. Invokes the CLI through its basic commands.
4. Validates configuration parsing.
5. Emits a mock proofpack.

If `smoke.sh` fails, the build is broken.

## Security Scanning
We run `gitleaks` in CI to ensure no hardcoded secrets or API keys make it into the repository. We also rely on Zig's explicit allocators to prevent hidden memory leaks and buffer overflows.

## Release Process
Before tagging a release, maintainers run `scripts/release-check.sh` which encapsulates formatting checks, tests, smoke tests, and secret scanning.
