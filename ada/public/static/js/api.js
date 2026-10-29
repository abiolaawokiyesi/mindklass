/**
 * Thin API client. Everything the browser needs, nothing it shouldn't have:
 * no keys, no direct provider calls.
 */

const j = async (url, opts) => {
  const res = await fetch(url, { headers: { 'content-type': 'application/json' }, ...opts })
  if (!res.ok) throw new Error(`${res.status}`)
  return res.json()
}

export const api = {
  health: () => j('/api/health'),
  courses: () => j('/api/courses'),
  course: (id) => j(`/api/courses/${id}`),
  lesson: (id) => j(`/api/lessons/${id}`),
  languages: () => j('/api/languages'),
  startSession: (body) => j('/api/session', { method: 'POST', body: JSON.stringify(body) }),
  mastery: (learnerId) => j(`/api/mastery/${learnerId}`),
  recordMastery: (body) => j('/api/mastery', { method: 'POST', body: JSON.stringify(body) }),
  search: (q) => j(`/api/search?q=${encodeURIComponent(q)}`),

  /**
   * Streams a tutor turn. Calls handlers as NDJSON events arrive.
   * Returns an abort function so the learner can interrupt mid-sentence.
   */
  chat(body, handlers = {}) {
    const ctrl = new AbortController()
    ;(async () => {
      try {
        const res = await fetch('/api/chat', {
          method: 'POST',
          headers: { 'content-type': 'application/json' },
          body: JSON.stringify(body),
          signal: ctrl.signal
        })
        if (!res.ok || !res.body) throw new Error(`chat_${res.status}`)
        const reader = res.body.getReader()
        const dec = new TextDecoder()
        let buf = ''
        while (true) {
          const { done, value } = await reader.read()
          if (done) break
          buf += dec.decode(value, { stream: true })
          const lines = buf.split('\n')
          buf = lines.pop() ?? ''
          for (const line of lines) {
            if (!line.trim()) continue
            try {
              handlers.onEvent?.(JSON.parse(line))
            } catch { /* ignore malformed frame */ }
          }
        }
        handlers.onDone?.()
      } catch (e) {
        if (e.name !== 'AbortError') handlers.onError?.(e)
        else handlers.onAbort?.()
      }
    })()
    return () => ctrl.abort()
  }
}
