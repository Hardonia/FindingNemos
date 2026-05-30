// @ts-nocheck
// SPDX-FileCopyrightText: Copyright (c) 2026 NVIDIA CORPORATION & AFFILIATES. All rights reserved.
// SPDX-License-Identifier: Apache-2.0
//
// Inference endpoint probes — validate that a provider's API responds
// before committing the onboard wizard to a model selection.

const { getCredential, normalizeCredentialValue, resolveProviderCredential } = require("../credentials/store");
const { isWsl } = require("../platform");
const httpProbe = require("../adapters/http/probe");
const {
  getHostDockerInternalProbeFailure,
  isHijackedDockerInternalUrl,
} = require("./onboard-host-docker-internal");
const {
  isNvcfFunctionNotFoundForAccount,
  nvcfFunctionNotFoundMessage,
  shouldForceCompletionsApi,
} = require("../validation");

const {
  getCurlTimingArgs,
  runCurlProbe,
  runChatCompletionsStreamingProbe,
  runStreamingEventProbe,
} = httpProbe;
const trace = require("../trace");

// ── Helpers ──────────────────────────────────────────────────────

// Hostnames that are normally meant for the sandbox/container host boundary.
// host.openshell.internal only resolves inside the OpenShell sandbox network,
// so host-side validation cannot prove reachability for that URL. For ordinary
// verification we still skip these endpoints, but strict tool-call validation
// must fail closed unless the host is probeable from the onboard process.
const SANDBOX_INTERNAL_HOSTS = ["host.openshell.internal"];

function isSandboxInternalUrl(url) {
  try {
    const { hostname } = new URL(String(url));
    return SANDBOX_INTERNAL_HOSTS.includes(hostname);
  } catch {
    return false;
  }
}

function parseJsonObject(body) {
  if (!body) return null;
  try {
    return JSON.parse(body);
  } catch {
    return null;
  }
}

function hasResponsesToolCall(body) {
  const parsed = parseJsonObject(body);
  if (!parsed || !Array.isArray(parsed.output)) return false;

  const stack = [...parsed.output];
  while (stack.length > 0) {
    const item = stack.pop();
    if (!item || typeof item !== "object") continue;
    if (item.type === "function_call" || item.type === "tool_call") return true;
    if (Array.isArray(item.content)) {
      stack.push(...item.content);
    }
  }

  return false;
}

function hasOwn(value, key) {
  return Object.prototype.hasOwnProperty.call(value, key);
}

function hasValidFunctionCallPayload(value) {
  if (!value || typeof value !== "object") return false;
  if (typeof value.name !== "string" || value.name.length === 0) return false;
  if (!hasOwn(value, "arguments")) return false;
  return (
    typeof value.arguments === "string" ||
    (typeof value.arguments === "object" &&
      value.arguments !== null &&
      !Array.isArray(value.arguments))
  );
}

function isStructuredChatCompletionsToolCall(value) {
  if (!value || typeof value !== "object") return false;
  if (value.type !== "function") return false;
  const fn = value.function;
  return hasValidFunctionCallPayload(fn);
}

function containsToolCallLikeValue(value) {
  if (!value || typeof value !== "object") return false;
  if (hasValidFunctionCallPayload(value)) return true;
  if (isStructuredChatCompletionsToolCall(value)) return true;
  if (Array.isArray(value.tool_calls)) {
    return value.tool_calls.some((call) => isStructuredChatCompletionsToolCall(call));
  }
  if (value.message && typeof value.message === "object") {
    return containsToolCallLikeValue(value.message);
  }
  if (Array.isArray(value.choices)) {
    return value.choices.some((choice) => choice && containsToolCallLikeValue(choice));
  }
  return false;
}

function parseStringifiedToolCall(content) {
  if (typeof content !== "string") return null;
  const trimmed = content.trim();
  if (!trimmed.startsWith("{") || !trimmed.endsWith("}")) return null;
  try {
    const parsed = JSON.parse(trimmed);
    return containsToolCallLikeValue(parsed) ? parsed : null;
  } catch {
    return null;
  }
}

function hasChatCompletionsToolCall(body) {
  const parsed = parseJsonObject(body);
  const message = parsed?.choices?.[0]?.message;
  if (!message || typeof message !== "object") return false;
  const toolCalls = message.tool_calls;
  if (!Array.isArray(toolCalls) || toolCalls.length === 0) return false;
  return toolCalls.some((call) => isStructuredChatCompletionsToolCall(call));
}

function hasChatCompletionsToolCallLeak(body) {
  const parsed = parseJsonObject(body);
  const message = parsed?.choices?.[0]?.message;
  if (!message || typeof message !== "object") return false;

  const content = message.content;
  if (typeof content === "string") {
    return Boolean(parseStringifiedToolCall(content));
  }
  if (Array.isArray(content)) {
    return content.some((item) => {
      if (!item || typeof item !== "object") return false;
      const text = typeof item.text === "string" ? item.text : "";
      return Boolean(parseStringifiedToolCall(text));
    });
  }
  return false;
}

function shouldRequireResponsesToolCalling(provider) {
  return (
    provider === "nvidia-prod" || provider === "gemini-api" || provider === "compatible-endpoint"
  );
}

// Google Gemini rejects requests that carry both an Authorization: Bearer
// The Gemini OpenAI-compat endpoint at /v1beta/openai/ requires
// `Authorization: Bearer <KEY>` and rejects `?key=<KEY>` with HTTP 400
// "Missing or invalid Authorization header." The dual-auth rejection
// described in #1960 applies to the native /v1beta/models/...:generateContent
// endpoint, which the onboarder probes do not use. Both callers of this
// helper (probeOpenAiLikeEndpoint, probeResponsesToolCalling) target the
// OpenAI-compat URL, so returning undefined for every provider is correct:
// probes default to Bearer auth and Gemini onboarding succeeds.
function getProbeAuthMode(_provider) {
  return undefined;
}

// Per-validation-probe curl timing. Tighter than the default 60s in
// getCurlTimingArgs() because validation must not hang the wizard for a
// minute on a misbehaving model. See issue #1601 (Bug 3).
function getValidationProbeCurlArgs(opts) {
  if (isWsl(opts)) {
    return ["--connect-timeout", "20", "--max-time", "30"];
  }
  return ["--connect-timeout", "10", "--max-time", "15"];
}

function getDeepSeekV4ProValidationProbeCurlArgs(opts) {
  if (isWsl(opts)) {
    return ["--connect-timeout", "30", "--max-time", "150"];
  }
  return ["--connect-timeout", "20", "--max-time", "120"];
}

function getKimiK26ValidationProbeCurlArgs(opts) {
  if (isWsl(opts)) {
    return ["--connect-timeout", "20", "--max-time", "90"];
  }
  return ["--connect-timeout", "10", "--max-time", "60"];
}

function getCurlMaxTimeSeconds(args) {
  const maxTimeIndex = args.indexOf("--max-time");
  if (maxTimeIndex === -1) return 30;
  const value = Number(args[maxTimeIndex + 1]);
  return Number.isFinite(value) && value > 0 ? value : 30;
}

function getProbeProcessTimeoutMs(args) {
  return (getCurlMaxTimeSeconds(args) + 5) * 1000;
}

// 429 = Too Many Requests; 502/503/504 = upstream gateway/availability flakes
// (NVIDIA Endpoints and other hosted providers periodically emit these for
// minutes at a time). All four are transient — retry with backoff before
// surfacing a hard failure to the wizard. See issues #2980 and #3033.
const RETRIABLE_HTTP_PROBE_STATUSES = new Set([429, 502, 503, 504]);
const HTTP_PROBE_RETRY_DELAYS_MS = [5_000, 15_000, 30_000];

function sleepSync(ms) {
  if (ms <= 0) return;
  // Skip real waits under vitest so retry-loop coverage doesn't burn 50s of
  // wall-clock per test. process.env.VITEST is set automatically by the
  // test runner.
  if (process.env.VITEST === "true" || process.env.NEMOCLAW_TEST_NO_SLEEP === "1") return;
  Atomics.wait(new Int32Array(new SharedArrayBuffer(4)), 0, 0, ms);
}

function shouldRetryHttpProbe(result) {
  return (
    result &&
    !result.ok &&
    result.curlStatus === 0 &&
    RETRIABLE_HTTP_PROBE_STATUSES.has(result.httpStatus)
  );
}

function isCurlTimeout(result) {
  return result && !result.ok && result.curlStatus === 28;
}

function executeProbeWithHttpRetry(probe) {
  return trace.withTraceSpan(
    "nemoclaw.inference.validation_probe",
    { probe_name: probe.name, api: probe.api || null },
    () => {
      let attempt = 1;
      let result = probe.execute();
      trace.addTraceEvent("probe_result", {
        attempt,
        ok: result.ok,
        http_status: result.httpStatus,
        curl_status: result.curlStatus,
      });
      for (const delayMs of HTTP_PROBE_RETRY_DELAYS_MS) {
        if (!shouldRetryHttpProbe(result)) break;
        console.log(
          `  ${probe.name} validation returned HTTP ${result.httpStatus}; retrying in ${Math.round(delayMs / 1000)}s...`,
        );
        trace.addTraceEvent("probe_retry_sleep", { delay_ms: delayMs, http_status: result.httpStatus });
        sleepSync(delayMs);
        attempt += 1;
        result = probe.execute();
        trace.addTraceEvent("probe_result", {
          attempt,
          ok: result.ok,
          http_status: result.httpStatus,
          curl_status: result.curlStatus,
        });
      }
      return result;
    },
  );
}

// ── Responses API probe ──────────────────────────────────────────

function probeResponsesToolCalling(endpointUrl, model, apiKey, options = {}) {
  const useQueryParam = options.authMode === "query-param";
  const normalizedKey = apiKey ? normalizeCredentialValue(apiKey) : "";
  const baseUrl = String(endpointUrl).replace(/\/+$/, "");
  const authHeader =
    !useQueryParam && normalizedKey ? ["-H", `Authorization: Bearer ${normalizedKey}`] : [];
  const url =
    useQueryParam && normalizedKey
      ? `${baseUrl}/responses?key=${encodeURIComponent(normalizedKey)}`
      : `${baseUrl}/responses`;
  const result = runCurlProbe([
    "-sS",
    ...getValidationProbeCurlArgs(),
    "-H",
    "Content-Type: application/json",
    ...authHeader,
    "-d",
    JSON.stringify({
      model,
      input: "Call the emit_ok function with value OK. Do not answer with plain text.",
      tool_choice: "required",
      tools: [
        {
          type: "function",
          name: "emit_ok",
          description: "Returns the probe value for validation.",
          parameters: {
            type: "object",
            properties: {
              value: { type: "string" },
            },
            required: ["value"],
            additionalProperties: false,
          },
        },
      ],
    }),
    url,
  ]);

  if (!result.ok) {
    return result;
  }
  if (hasResponsesToolCall(result.body)) {
    return result;
  }
  return {
    ok: false,
    httpStatus: result.httpStatus,
    curlStatus: result.curlStatus,
    body: result.body,
    stderr: result.stderr,
    message: `HTTP ${result.httpStatus}: Responses API did not return a tool call`,
  };
}

function probeChatCompletionsToolCalling(endpointUrl, model, apiKey, options = {}) {
  const useQueryParam = options.authMode === "query-param";
  const normalizedKey = apiKey ? normalizeCredentialValue(apiKey) : "";
  const baseUrl = String(endpointUrl).replace(/\/+$/, "");
  const authHeader = !useQueryParam && normalizedKey
    ? ["-H", `Authorization: Bearer ${normalizedKey}`]
    : [];
  const url = useQueryParam && normalizedKey
    ? `${baseUrl}/chat/completions?key=${encodeURIComponent(normalizedKey)}`
    : `${baseUrl}/chat/completions`;
  const timingArgs = options.timingArgs ?? getValidationProbeCurlArgs();
  const result = runCurlProbe([
    "-sS",
    ...timingArgs,
    "-H",
    "Content-Type: application/json",
    ...authHeader,
    "-d",
    JSON.stringify({
      model,
      messages: [
        {
          role: "system",
          content:
            "You are a tool-calling assistant. When tools are available and the user asks for an action, call a tool.",
        },
        {
          role: "user",
          content:
            "Send hello to the current session. Use the sessions_send tool and do not answer in plain text.",
        },
      ],
      tools: [
        {
          type: "function",
          function: {
            name: "sessions_send",
            description: "Send a message to the active chat session.",
            parameters: {
              type: "object",
              properties: { message: { type: "string" } },
              required: ["message"],
              additionalProperties: false,
            },
          },
        },
        {
          type: "function",
          function: {
            name: "memory_search",
            description: "Search memory for relevant prior context.",
            parameters: {
              type: "object",
              properties: { query: { type: "string" } },
              required: ["query"],
              additionalProperties: false,
            },
          },
        },
        {
          type: "function",
          function: {
            name: "web_fetch",
            description: "Fetch a URL and summarize the result.",
            parameters: {
              type: "object",
              properties: { url: { type: "string" } },
              required: ["url"],
              additionalProperties: false,
            },
          },
        },
      ],
      tool_choice: "required",
      temperature: 0,
    }),
    url,
  ]);

  if (!result.ok) {
    return result;
  }
  if (hasChatCompletionsToolCall(result.body)) {
    return result;
  }
  if (hasChatCompletionsToolCallLeak(result.body)) {
    return {
      ok: false,
      httpStatus: result.httpStatus,
      curlStatus: result.curlStatus,
      body: result.body,
      stderr: result.stderr,
      message:
        `HTTP ${result.httpStatus}: Chat Completions leaked tool calls into plain text content. ` +
        "Use an endpoint/runtime that returns structured tool_calls (for Hermes on local inference, " +
        "prefer vLLM with --tool-call-parser hermes).",
    };
  }
  return {
    ok: false,
    httpStatus: result.httpStatus,
    curlStatus: result.curlStatus,
    body: result.body,
    stderr: result.stderr,
    message: `HTTP ${result.httpStatus}: Chat Completions did not return a tool call`,
  };
}

// ── OpenAI-like probe ────────────────────────────────────────────
function isDeepSeekV4ProModel(model) {
  return String(model || "").toLowerCase() === "deepseek-ai/deepseek-v4-pro";
}

function isKimiK26Model(model) {
  return String(model || "").toLowerCase() === "moonshotai/kimi-k2.6";
}

function getChatCompletionsProbePayload(model) {
  const payload = {
    model,
    messages: [{ role: "user", content: "Reply with exactly: OK" }],
  };

  if (isDeepSeekV4ProModel(model)) {
    return {
      ...payload,
      temperature: 1,
      top_p: 0.95,
      max_tokens: 8192,
      chat_template_kwargs: { thinking: false },
      stream: true,
    };
  }

  if (isKimiK26Model(model)) {
    return {
      ...payload,
      max_tokens: 8,
      chat_template_kwargs: { thinking: false },
    };
  }

  return payload;
}

export function getChatCompletionsProbeCurlArgs({
  authHeader,
  model,
  url,
  isWsl: isWslOverride,
}) {
  const platformOptions =
    typeof isWslOverride === "boolean" ? { isWsl: isWslOverride } : undefined;
  const timingArgs = (() => {
    if (isDeepSeekV4ProModel(model)) return getDeepSeekV4ProValidationProbeCurlArgs(platformOptions);
    if (isKimiK26Model(model)) return getKimiK26ValidationProbeCurlArgs(platformOptions);
    return getValidationProbeCurlArgs(platformOptions);
  })();
  return [
    "-sS",
    ...timingArgs,
    "-H",
    "Content-Type: application/json",
    ...authHeader,
    "-d",
    JSON.stringify(getChatCompletionsProbePayload(model)),
    url,
  ];
}

function runChatCompletionsProbe({ authHeader, model, url, isWsl: isWslOverride }) {
  const args = getChatCompletionsProbeCurlArgs({
    authHeader,
    model,
    url,
    isWsl: isWslOverride,
  });
  if (isDeepSeekV4ProModel(model)) {
    return runChatCompletionsStreamingProbe(args, {
      timeoutMs: getProbeProcessTimeoutMs(args),
    });
  }
  return runCurlProbe(args);
}


function buildProbeAuth(endpointUrl, apiKey, authMode) {
  const useQueryParam = authMode === "query-param";
  const normalizedKey = apiKey ? normalizeCredentialValue(apiKey) : "";
  const baseUrl = String(endpointUrl).replace(/\/+$/, "");
  const authHeader =
    !useQueryParam && normalizedKey ? ["-H", `Authorization: Bearer ${normalizedKey}`] : [];
  const appendKey = (urlPath) =>
    useQueryParam && normalizedKey
      ? `${baseUrl}${urlPath}?key=${encodeURIComponent(normalizedKey)}`
      : `${baseUrl}${urlPath}`;
  return { authHeader, appendKey };
}

function buildProbesList(endpointUrl, model, apiKey, options, authHeader, appendKey) {
  const responsesProbe =
    options.requireResponsesToolCalling === true
      ? {
          name: "Responses API with tool calling",
          api: "openai-responses",
          execute: () =>
            probeResponsesToolCalling(endpointUrl, model, apiKey, { authMode: options.authMode }),
        }
      : {
          name: "Responses API",
          api: "openai-responses",
          execute: () =>
            runCurlProbe([
              "-sS",
              ...getValidationProbeCurlArgs(),
              "-H",
              "Content-Type: application/json",
              ...authHeader,
              "-d",
              JSON.stringify({
                model,
                input: "Reply with exactly: OK",
              }),
              appendKey("/responses"),
            ]),
        };

  const chatCompletionsProbe = {
    name: "Chat Completions API",
    api: "openai-completions",
    execute: () =>
      options.requireChatCompletionsToolCalling === true
        ? probeChatCompletionsToolCalling(endpointUrl, model, apiKey, {
            authMode: options.authMode,
          })
        : runChatCompletionsProbe({
            authHeader,
            model,
            url: appendKey("/chat/completions"),
            isWsl: options.isWsl,
          }),
  };

  return options.skipResponsesProbe
    ? [chatCompletionsProbe]
    : [responsesProbe, chatCompletionsProbe];
}

function processStreamingProbe(probe, model, authHeader, appendKey) {
  const streamResult = runStreamingEventProbe([
    "-sS",
    ...getValidationProbeCurlArgs(),
    "-H",
    "Content-Type: application/json",
    ...authHeader,
    "-d",
    JSON.stringify({
      model,
      input: "Reply with exactly: OK",
      stream: true,
    }),
    appendKey("/responses"),
  ]);

  if (!streamResult.ok && streamResult.missingEvents.length > 0) {
    console.log(`  ℹ ${streamResult.message}`);
    return {
      status: "fallback",
      failure: {
        name: probe.name + " (streaming)",
        httpStatus: 0,
        curlStatus: 0,
        message: streamResult.message,
        body: "",
      },
    };
  }

  if (!streamResult.ok) {
    return {
      status: "error",
      result: {
        ok: false,
        message: `${probe.name} (streaming): ${streamResult.message}`,
        failures: [
          {
            name: probe.name + " (streaming)",
            httpStatus: 0,
            curlStatus: 0,
            message: streamResult.message,
            body: "",
          },
        ],
      },
    };
  }

  return { status: "ok" };
}

function executeProbeRetries(endpointUrl, model, apiKey, options, failures) {
  const isTimeoutOrConnFailure = (cs) => cs === 28 || cs === 6 || cs === 7;
  const isRetriableProbeResult = (result) =>
    isTimeoutOrConnFailure(result.curlStatus) ||
    RETRIABLE_HTTP_PROBE_STATUSES.has(result.httpStatus);

  if (!failures.some((failure) => isTimeoutOrConnFailure(failure.curlStatus))) {
    return { retriedAfterTimeout: false, retryResult: null };
  }

  const baseArgs = getValidationProbeCurlArgs();
  const doubledArgs = baseArgs.map((arg) => (/^\d+$/.test(arg) ? String(Number(arg) * 2) : arg));
  const buildRetryArgs = () => [
    "-sS",
    ...doubledArgs,
    "-H",
    "Content-Type: application/json",
    ...(apiKey ? ["-H", `Authorization: Bearer ${normalizeCredentialValue(apiKey)}`] : []),
    "-d",
    JSON.stringify(getChatCompletionsProbePayload(model)),
    `${String(endpointUrl).replace(/\/+$/, "")}/chat/completions`,
  ];

  const runRetryProbe = () =>
    options.requireChatCompletionsToolCalling === true
      ? probeChatCompletionsToolCalling(endpointUrl, model, apiKey, {
          authMode: options.authMode,
          timingArgs: doubledArgs,
        })
      : runCurlProbe(buildRetryArgs());

  let retryResult = runRetryProbe();
  if (retryResult.ok) {
    return { retriedAfterTimeout: true, retryResult };
  }

  for (const delayMs of HTTP_PROBE_RETRY_DELAYS_MS) {
    if (!isRetriableProbeResult(retryResult)) break;
    const reason = isTimeoutOrConnFailure(retryResult.curlStatus)
      ? "timed out"
      : `returned HTTP ${retryResult.httpStatus}`;
    console.log(
      `  Chat Completions API validation ${reason}; retrying in ${Math.round(delayMs / 1000)}s...`
    );
    sleepSync(delayMs);
    retryResult = runRetryProbe();
    if (retryResult.ok) {
      return { retriedAfterTimeout: true, retryResult };
    }
  }

  if (options.requireChatCompletionsToolCalling === true) {
    failures.push({
      name: "Chat Completions API with tool calling (retry)",
      httpStatus: retryResult.httpStatus,
      curlStatus: retryResult.curlStatus,
      message: retryResult.message,
      body: retryResult.body,
    });
  }

  return { retriedAfterTimeout: true, retryResult: null };
}

function buildFinalErrorResult(model, failures, retriedAfterTimeout) {
  const accountFailure = failures.find(
    (failure) =>
      isNvcfFunctionNotFoundForAccount(failure.message) ||
      isNvcfFunctionNotFoundForAccount(failure.body),
  );
  if (accountFailure) {
    return {
      ok: false,
      message: nvcfFunctionNotFoundMessage(model),
      failures,
    };
  }

  const baseMessage = failures.map((failure) => `${failure.name}: ${failure.message}`).join(" | ");
  const wslHint =
    isWsl() && retriedAfterTimeout
      ? " · WSL2 detected — network verification may be slower than expected. " +
        "Run `nemoclaw onboard` with the `--skip-verify` flag if this endpoint is known to be reachable."
      : "";
  return {
    ok: false,
    message: baseMessage + wslHint,
    failures,
  };
}

function probeOpenAiLikeEndpoint(endpointUrl, model, apiKey, options = {}) {
  if (isHijackedDockerInternalUrl(endpointUrl) && options.allowHostDockerInternal !== true) {
    return getHostDockerInternalProbeFailure();
  }

  if (isSandboxInternalUrl(endpointUrl)) {
    const { hostname } = new URL(String(endpointUrl));
    if (options.requireChatCompletionsToolCalling !== true) {
      return {
        ok: true,
        api: null,
        label: null,
        note: `${hostname} only resolves inside the sandbox — validation skipped. If the endpoint is unreachable at runtime, re-run onboard with a routable URL.`,
      };
    }
    return {
      ok: false,
      message: `${hostname} only resolves inside the sandbox and cannot be validated for required structured Chat Completions tool calls from the host. Use a routable endpoint URL and retry onboard.`,
      failures: [
        {
          name: "Chat Completions API with tool calling",
          httpStatus: 0,
          curlStatus: 0,
          message: "sandbox-internal endpoint cannot be strictly validated from host",
          body: "",
        },
      ],
    };
  }

  const { authHeader, appendKey } = buildProbeAuth(endpointUrl, apiKey, options.authMode);
  const probes = buildProbesList(endpointUrl, model, apiKey, options, authHeader, appendKey);
  const failures = [];

  for (const probe of probes) {
    const result = executeProbeWithHttpRetry(probe);
    if (result.ok) {
      if (probe.api === "openai-responses" && options.probeStreaming === true) {
        const streamStatus = processStreamingProbe(probe, model, authHeader, appendKey);
        if (streamStatus.status === "fallback") {
          failures.push(streamStatus.failure);
          continue;
        }
        if (streamStatus.status === "error") {
          return streamStatus.result;
        }
      }
      return { ok: true, api: probe.api, label: probe.name };
    }
    if (
      probe.api === "openai-completions" &&
      isDeepSeekV4ProModel(model) &&
      isCurlTimeout(result)
    ) {
      const warning =
        "DeepSeek V4 Pro validation timed out before the stream returned data; continuing with NVIDIA Endpoints because this model can take longer than the onboarding probe budget to emit its first token.";
      console.log(`  ⚠ ${warning}`);
      return {
        ok: true,
        api: probe.api,
        label: probe.name,
        warning,
        validated: false,
      };
    }
    failures.push({
      name: probe.name,
      httpStatus: result.httpStatus,
      curlStatus: result.curlStatus,
      message: result.message,
      body: result.body,
    });
  }

  const { retriedAfterTimeout, retryResult } = executeProbeRetries(
    endpointUrl,
    model,
    apiKey,
    options,
    failures
  );

  if (retryResult && retryResult.ok) {
    return { ok: true, api: "openai-completions", label: "Chat Completions API" };
  }

  return buildFinalErrorResult(model, failures, retriedAfterTimeout);
}
// ── Anthropic probe ──────────────────────────────────────────────

function probeAnthropicEndpoint(endpointUrl, model, apiKey) {
  const result = runCurlProbe([
    "-sS",
    ...getCurlTimingArgs(),
    "-H",
    `x-api-key: ${normalizeCredentialValue(apiKey)}`,
    "-H",
    "anthropic-version: 2023-06-01",
    "-H",
    "content-type: application/json",
    "-d",
    JSON.stringify({
      model,
      max_tokens: 16,
      messages: [{ role: "user", content: "Reply with exactly: OK" }],
    }),
    `${String(endpointUrl).replace(/\/+$/, "")}/v1/messages`,
  ]);
  if (result.ok) {
    return { ok: true, api: "anthropic-messages", label: "Anthropic Messages API" };
  }
  return {
    ok: false,
    message: result.message,
    failures: [
      {
        name: "Anthropic Messages API",
        httpStatus: result.httpStatus,
        curlStatus: result.curlStatus,
        message: result.message,
      },
    ],
  };
}

module.exports = {
  isSandboxInternalUrl,
  isHijackedDockerInternalUrl,
  parseJsonObject,
  hasResponsesToolCall,
  hasChatCompletionsToolCall,
  hasChatCompletionsToolCallLeak,
  shouldRequireResponsesToolCalling,
  getProbeAuthMode,
  getValidationProbeCurlArgs,
  getDeepSeekV4ProValidationProbeCurlArgs,
  getKimiK26ValidationProbeCurlArgs,
  getChatCompletionsProbePayload,
  getChatCompletionsProbeCurlArgs,
  probeResponsesToolCalling,
  probeChatCompletionsToolCalling,
  probeOpenAiLikeEndpoint,
  probeAnthropicEndpoint,
  RETRIABLE_HTTP_PROBE_STATUSES,
};

function shouldSmokeOpenAiLikeOnboardRoute(provider) {
  const { REMOTE_PROVIDER_CONFIG } = require("../onboard/providers");
  if (provider === "nvidia-nim" || provider === "nvidia-router") return true;
  return Object.values(REMOTE_PROVIDER_CONFIG).some(
    (entry) => entry.providerName === provider && entry.providerType === "openai",
  );
}

function verifyOnboardInferenceSmoke(options) {
  if (!options.forceOpenAiLike && !shouldSmokeOpenAiLikeOnboardRoute(options.provider)) return;
  if (process.env.VITEST === "true") return;

  const endpointUrl = options.endpointUrl || require("./config").INFERENCE_ROUTE_URL;
  const credentialEnv = options.credentialEnv || null;
  const apiKey = credentialEnv
    ? resolveProviderCredential(credentialEnv) || getCredential(credentialEnv) || ""
    : "";
  const probe = probeOpenAiLikeEndpoint(endpointUrl, options.model, apiKey, {
    authMode: getProbeAuthMode(options.provider),
    skipResponsesProbe: true,
  });

  if (probe.ok) {
    console.log(`  ✓ Inference smoke passed: ${options.provider} / ${options.model}`);
    return;
  }

  const { compactText } = require("../core/url-utils");
  const { redact } = require("../runner");
  console.error("  Onboard inference smoke check failed.");
  console.error(`  Provider: ${options.provider}`);
  console.error(`  Model: ${options.model}`);
  console.error(`  API base: ${endpointUrl}`);
  if (credentialEnv) console.error("  Credential env: configured");
  console.error(`  Upstream error: ${compactText(redact(probe.message || "unknown inference failure"))}`);
  process.exit(1);
}

module.exports.shouldSmokeOpenAiLikeOnboardRoute = shouldSmokeOpenAiLikeOnboardRoute;
module.exports.verifyOnboardInferenceSmoke = verifyOnboardInferenceSmoke;
