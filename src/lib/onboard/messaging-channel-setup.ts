// SPDX-FileCopyrightText: Copyright (c) 2026 NVIDIA CORPORATION & AFFILIATES. All rights reserved.
// SPDX-License-Identifier: Apache-2.0

import {
  normalizeCredentialValue,
  prompt,
  saveCredential,
} from "../credentials/store";
import { normalizeMessagingChannelConfigValue } from "../messaging-channel-config";
import { channelHasStaticToken, type ChannelDef } from "../sandbox/channels";
import { dispatchHostQrLogin } from "./host-qr-dispatch";
import {
  getMessagingToken,
  isMessagingTokenFormatValid,
} from "./messaging-token";

type ChannelEntry = { name: string } & ChannelDef;

const getMessagingConfigValue = (envKey: string): string | null =>
  normalizeMessagingChannelConfigValue(envKey, process.env[envKey]);

function getExistingMessagingToken(
  ch: ChannelEntry,
  envKey: string | undefined,
  label: "token" | "app token",
): string | null {
  const token = getMessagingToken(envKey);
  if (token && !isMessagingTokenFormatValid(ch, envKey, token)) {
    console.log(`  ✗ Invalid existing ${ch.name} ${label} ignored.`);
    return null;
  }
  return token;
}

/**
 * Prompt for token + per-channel config (app token, server ID, mention
 * mode, allowlist IDs) for each selected messaging channel. Mutates
 * `process.env` for non-secret config and saves credentials via
 * `saveCredential`. Channels where the user declined or supplied an
 * invalid token are removed from `enabled`.
 *
 * Extracted from `setupMessagingChannels` in onboard.ts so the
 * per-channel interactive loop lives outside the top-level entrypoint
 * (src/lib/onboard.ts file-growth budget).
 */
async function setupChannelAuth(ch: ChannelEntry, enabled: Set<string>): Promise<boolean> {
  if (channelHasStaticToken(ch) && getExistingMessagingToken(ch, ch.envKey, "token")) {
    console.log(`  ✓ ${ch.name} — already configured`);
    return true;
  }
  if (ch.loginMethod === "host-qr") {
    console.log("");
    console.log(`  ${ch.help}`);
    const outcome = await dispatchHostQrLogin(ch);
    if (!outcome.ok) {
      console.log(`  Skipped ${ch.name} (${outcome.reason})`);
      enabled.delete(ch.name);
      return false;
    }
    const suffix = outcome.summary ? ` (${outcome.summary})` : "";
    console.log(`  ✓ ${ch.name} token saved${suffix}`);
    return true;
  }
  if (ch.loginMethod === "in-sandbox-qr") {
    console.log("");
    console.log(`  ${ch.help}`);
    console.log(
      `  ✓ ${ch.name} enabled — complete QR pairing from inside the sandbox after rebuild.`,
    );
    return true;
  }
  if (!channelHasStaticToken(ch)) return false;
  console.log("");
  console.log(`  ${ch.help}`);
  const token = normalizeCredentialValue(await prompt(`  ${ch.label}: `, { secret: true }));
  if (token && ch.tokenFormat && !ch.tokenFormat.test(token)) {
    console.log(
      `  ✗ Invalid format. ${ch.tokenFormatHint || "Check the token and try again."}`,
    );
    console.log(`  Skipped ${ch.name} (invalid token format)`);
    enabled.delete(ch.name);
    return false;
  }
  if (token) {
    saveCredential(ch.envKey, token);
    process.env[ch.envKey] = token;
    console.log(`  ✓ ${ch.name} token saved`);
    return true;
  }
  console.log(`  Skipped ${ch.name} (no token entered)`);
  enabled.delete(ch.name);
  return false;
}

async function setupChannelAppToken(ch: ChannelEntry, enabled: Set<string>): Promise<boolean> {
  if (!ch.appTokenEnvKey) return true;
  const existingAppToken = getExistingMessagingToken(ch, ch.appTokenEnvKey, "app token");
  if (existingAppToken) {
    console.log(`  ✓ ${ch.name} app token — already configured`);
    return true;
  }
  console.log("");
  console.log(`  ${ch.appTokenHelp}`);
  const appToken = normalizeCredentialValue(
    await prompt(`  ${ch.appTokenLabel}: `, { secret: true }),
  );
  if (appToken && ch.appTokenFormat && !ch.appTokenFormat.test(appToken)) {
    console.log(
      `  ✗ Invalid format. ${ch.appTokenFormatHint || "Check the token and try again."}`,
    );
    console.log(`  Skipped ${ch.name} app token (invalid token format)`);
    enabled.delete(ch.name);
    return false;
  }
  if (appToken) {
    saveCredential(ch.appTokenEnvKey, appToken);
    process.env[ch.appTokenEnvKey] = appToken;
    console.log(`  ✓ ${ch.name} app token saved`);
    return true;
  }
  console.log(`  Skipped ${ch.name} app token (Socket Mode requires both tokens)`);
  enabled.delete(ch.name);
  return false;
}

async function setupChannelServerId(ch: ChannelEntry): Promise<void> {
  if (!ch.serverIdEnvKey) return;
  const existingServerIds = getMessagingConfigValue(ch.serverIdEnvKey) || "";
  if (existingServerIds) {
    process.env[ch.serverIdEnvKey] = existingServerIds;
    console.log(`  ✓ ${ch.name} — server ID already set: ${existingServerIds}`);
  } else {
    console.log(`  ${ch.serverIdHelp}`);
    const serverId = (await prompt(`  ${ch.serverIdLabel}: `)).trim();
    if (serverId) {
      process.env[ch.serverIdEnvKey] = serverId;
      console.log(`  ✓ ${ch.name} server ID saved`);
    } else {
      console.log(`  Skipped ${ch.name} server ID (guild channels stay disabled)`);
    }
  }
}

async function setupChannelMentionControl(ch: ChannelEntry): Promise<void> {
  const requireMentionKey = ch.requireMentionEnvKey;
  if (!requireMentionKey || (ch.serverIdEnvKey && !process.env[ch.serverIdEnvKey])) return;

  const existingRequireMention = getMessagingConfigValue(requireMentionKey);
  if (existingRequireMention === "0" || existingRequireMention === "1") {
    process.env[requireMentionKey] = existingRequireMention;
    const mode = existingRequireMention === "0" ? "all messages" : "@mentions only";
    console.log(`  ✓ ${ch.name} — reply mode already set: ${mode}`);
  } else {
    console.log(`  ${ch.requireMentionHelp}`);
    const answer = (await prompt("  Reply only when @mentioned? [Y/n]: ")).trim().toLowerCase();
    const value = answer === "n" || answer === "no" ? "0" : "1";
    process.env[requireMentionKey] = value;
    const mode = value === "0" ? "all messages" : "@mentions only";
    console.log(`  ✓ ${ch.name} reply mode saved: ${mode}`);
  }
}

async function setupChannelUserId(ch: ChannelEntry): Promise<void> {
  if (!ch.userIdEnvKey || (ch.serverIdEnvKey && !process.env[ch.serverIdEnvKey])) return;

  const existingIds = getMessagingConfigValue(ch.userIdEnvKey) || "";
  if (existingIds) {
    process.env[ch.userIdEnvKey] = existingIds;
    console.log(`  ✓ ${ch.name} — allowed IDs already set: ${existingIds}`);
  } else {
    console.log(`  ${ch.userIdHelp}`);
    const userId = (await prompt(`  ${ch.userIdLabel}: `)).trim();
    if (userId) {
      process.env[ch.userIdEnvKey] = userId;
      console.log(`  ✓ ${ch.name} allowed IDs saved`);
    } else {
      const skippedReason =
        ch.allowIdsMode === "guild"
          ? "any member in the configured server can message the bot"
          : "bot will require manual pairing";
      console.log(`  Skipped ${ch.name} user ID (${skippedReason})`);
    }
  }
}

async function setupChannelChannelId(ch: ChannelEntry): Promise<void> {
  if (!ch.channelIdEnvKey || (ch.serverIdEnvKey && !process.env[ch.serverIdEnvKey])) return;

  const existingChannelIds = getMessagingConfigValue(ch.channelIdEnvKey) || "";
  if (existingChannelIds) {
    process.env[ch.channelIdEnvKey] = existingChannelIds;
    console.log(`  ✓ ${ch.name} — channel IDs already set: ${existingChannelIds}`);
  } else {
    console.log(`  ${ch.channelIdHelp}`);
    const channelIds = (await prompt(`  ${ch.channelIdLabel}: `)).trim();
    if (channelIds) {
      process.env[ch.channelIdEnvKey] = channelIds;
      console.log(`  ✓ ${ch.name} channel IDs saved`);
    } else {
      console.log(`  Skipped ${ch.name} channel IDs (channel @mentions stay disabled)`);
    }
  }
}

export async function setupSelectedMessagingChannels(
  selected: readonly string[],
  enabled: Set<string>,
  messagingChannels: readonly ChannelEntry[],
): Promise<void> {
  for (const name of selected) {
    const ch = messagingChannels.find((c) => c.name === name);
    if (!ch) {
      console.log(`  Unknown channel: ${name}`);
      continue;
    }

    if (!(await setupChannelAuth(ch, enabled))) continue;

    for (const line of ch.setupNotes ?? []) {
      console.log(`  ${line}`);
    }

    if (!(await setupChannelAppToken(ch, enabled))) continue;

    await setupChannelServerId(ch);
    await setupChannelMentionControl(ch);
    await setupChannelUserId(ch);
    await setupChannelChannelId(ch);
  }
}
