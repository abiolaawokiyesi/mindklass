// LLM access layer.
//
// Two invariants that matter for a product that must never look broken in front
// of a learner:
//   1. The tutor degrades gracefully. If no key is configured, if the provider
//      rate-limits, or if a request exceeds its budget, the avatar still teaches
//      from approved curriculum content (grounded mode) rather than erroring.
//   2. No credential ever reaches the browser. All model calls happen here.

export type Msg = { role: 'system' | 'user' | 'assistant'; content: string }

export type LlmEnv = {
  OPENAI_API_KEY?: string
  OPENAI_BASE_URL?: string
  AVATAR_LLM_MODEL?: string
}

const DEFAULT_BASE = 'https://api.openai.com/v1'
const DEFAULT_MODEL = 'gpt-5-mini'

export function providerStatus(env: LlmEnv) {
  const configured = Boolean(env.OPENAI_API_KEY)
  return {
    mode: configured ? ('model' as const) : ('grounded' as const),
    model: env.AVATAR_LLM_MODEL || DEFAULT_MODEL,
    // Never expose key material — only whether one exists.
    baseHost: configured ? safeHost(env.OPENAI_BASE_URL || DEFAULT_BASE) : null
  }
}

function safeHost(url: string) {
  try {
    return new URL(url).host
  } catch {
    return 'invalid-url'
  }
}

/** Streaming chat completion. Yields text deltas. Throws on provider failure. */
export async function* streamChat(
  env: LlmEnv,
  messages: Msg[],
  opts: { temperature?: number; maxTokens?: number; signal?: AbortSignal } = {}
): AsyncGenerator<string, void, unknown> {
  if (!env.OPENAI_API_KEY) throw new Error('NO_PROVIDER')
  const base = (env.OPENAI_BASE_URL || DEFAULT_BASE).replace(/\/$/, '')
  const model = env.AVATAR_LLM_MODEL || DEFAULT_MODEL

  const res = await fetch(`${base}/chat/completions`, {
    method: 'POST',
    headers: {
      'content-type': 'application/json',
      authorization: `Bearer ${env.OPENAI_API_KEY}`
    },
    body: JSON.stringify({
      model,
      messages,
      stream: true,
      temperature: opts.temperature ?? 0.6,
      max_tokens: opts.maxTokens ?? 700
    }),
    signal: opts.signal
  })

  if (!res.ok || !res.body) {
    const detail = await res.text().catch(() => '')
    throw new Error(`PROVIDER_${res.status}:${detail.slice(0, 200)}`)
  }

  const reader = res.body.getReader()
  const decoder = new TextDecoder()
  let buf = ''
  let sawContent = false

  while (true) {
    const { done, value } = await reader.read()
    if (done) break
    buf += decoder.decode(value, { stream: true })
    const lines = buf.split('\n')
    buf = lines.pop() ?? ''
    for (const raw of lines) {
      const line = raw.trim()
      if (!line.startsWith('data:')) continue
      const payload = line.slice(5).trim()
      if (payload === '[DONE]') return
      try {
        const json = JSON.parse(payload) as {
          choices?: { delta?: { content?: string } }[]
        }
        const delta = json.choices?.[0]?.delta?.content
        if (delta) {
          sawContent = true
          yield delta
        }
      } catch {
        // Ignore keep-alive or malformed frames.
      }
    }
  }

  // A provider that returns 200 with a polite refusal (quota messages arrive as
  // normal content) is indistinguishable here from a real answer, so callers
  // additionally run `looksLikeRefusal` on the accumulated text.
  if (!sawContent) throw new Error('EMPTY_STREAM')
}

/**
 * Detect provider-level refusal/quota text that arrives as ordinary content.
 * Without this, a learner would hear an error message read aloud by the avatar.
 */
export function looksLikeRefusal(text: string): boolean {
  const t = text.toLowerCase()
  if (!t.trim()) return true
  return (
    t.includes('free-plan credits') ||
    t.includes('credit_exhausted') ||
    t.includes('insufficient quota') ||
    t.includes('exceeded your current quota') ||
    t.includes('please visit https://www.genspark.ai/pricing') ||
    t.includes('api key not valid') ||
    t.includes('invalid_api_key')
  )
}

export async function complete(
  env: LlmEnv,
  messages: Msg[],
  opts: { temperature?: number; maxTokens?: number; signal?: AbortSignal } = {}
): Promise<string> {
  let out = ''
  for await (const d of streamChat(env, messages, opts)) out += d
  return out
}
