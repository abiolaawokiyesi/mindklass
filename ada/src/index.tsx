import { Hono } from 'hono'
import { cors } from 'hono/cors'
import type { Env } from './lib/db'
import { courseIndex, findCourse, findLesson, COURSES } from './kb/courses'
import { LANGS, langByCode, langCodes } from './lib/languages'
import { loadChunks, searchChunks } from './lib/retrieval'
import { buildPlan, groundedTurn, toSentences, type Turn, type Strategy } from './lib/pedagogy'
import { streamChat, looksLikeRefusal, providerStatus } from './lib/llm'
import { cueFor } from './lib/avatarcues'
import { synthesize } from './lib/tts'
import { verifySupabaseJwt, bearer } from './lib/auth'
import {
  ensureLearner,
  startSession,
  appendTurn,
  updateMastery,
  getMastery
} from './lib/db'
import { shell } from './ui/shell'

const app = new Hono<{ Bindings: Env }>()

app.use('/api/*', cors({ origin: '*', allowMethods: ['GET', 'POST', 'OPTIONS'], allowHeaders: ['content-type', 'authorization'] }))

/* ------------------------------------------------------------------ health */

app.get('/api/health', async (c) => {
  const env = c.env
  let dbOk = false
  let curriculumChunks = 0
  if (env.DB) {
    try {
      const r = await env.DB.prepare('SELECT COUNT(*) AS n FROM kb_chunk').first<{ n: number }>()
      dbOk = true
      curriculumChunks = r?.n ?? 0
    } catch {
      dbOk = false
    }
  }
  return c.json({
    ok: true,
    version: '1.0.0',
    engine: 'mindklass-avatar',
    tutor: providerStatus(env),
    // Honest capability report: the client uses this to tell the teacher what
    // will happen when a lesson starts.
    tts: env.TTS_PROVIDER && env.TTS_API_KEY ? { mode: 'neural', provider: env.TTS_PROVIDER } : { mode: 'browser' },
    db: { bound: Boolean(env.DB), reachable: dbOk, curriculumChunks },
    auth: { verified: Boolean(env.SUPABASE_JWT_SECRET) },
    languages: langCodes(),
    courses: COURSES.length
  })
})

/* --------------------------------------------------------------- curriculum */

app.get('/api/courses', (c) => c.json({ courses: courseIndex() }))

app.get('/api/courses/:id', (c) => {
  const course = findCourse(c.req.param('id'))
  if (!course) return c.json({ error: 'not_found' }, 404)
  return c.json({
    id: course.id,
    title: course.title,
    subject: course.subject,
    level: course.level,
    accent: course.accent,
    blurb: course.blurb,
    lessons: course.lessons.map((l) => ({
      id: l.id,
      title: l.title,
      minutes: l.minutes,
      objectives: l.objectives
    }))
  })
})

app.get('/api/lessons/:id', (c) => {
  const found = findLesson(c.req.param('id'))
  if (!found) return c.json({ error: 'not_found' }, 404)
  return c.json({ course: findCourse(found.course.id), lesson: found.lesson })
})

app.get('/api/languages', (c) =>
  c.json({
    languages: LANGS.map(({ code, label, native, bcp47, rtl }) => ({ code, label, native, bcp47, rtl: !!rtl })),
    // Tells the browser what it can realistically speak today, so the UI can be
    // honest about needing a neural voice for some languages.
    neuralAvailable: Boolean(c.env.TTS_PROVIDER && c.env.TTS_API_KEY)
  })
)

/* ----------------------------------------------------------------- session */

app.post('/api/session', async (c) => {
  const body = await c.req.json<{ lang?: string; lessonId?: string; personaId?: string; name?: string }>().catch(() => ({}))
  const token = bearer(c)
  const ident = token ? await verifySupabaseJwt(token, c.env.SUPABASE_JWT_SECRET) : null
  const uid = ident?.uid ?? `guest:${crypto.randomUUID()}`
  const learnerId = await ensureLearner(c.env.DB, uid, ident?.name ?? body.name ?? null, body.lang ?? 'en')
  const sessionId = await startSession(c.env.DB, {
    learnerId,
    personaId: body.personaId ?? 'ada',
    lessonId: body.lessonId ?? null,
    lang: body.lang ?? 'en'
  })
  const lang = langByCode(body.lang ?? 'en')
  return c.json({
    sessionId,
    learnerId,
    uid,
    greeted: Boolean(sessionId),
    greeting: lang.greeting,
    lang: lang.code,
    bcp47: lang.bcp47
  })
})

/* -------------------------------------------------------------------- chat */
/**
 * Streams a tutor turn as NDJSON so the avatar can start speaking on the first
 * sentence instead of waiting for the whole reply. Events:
 *   {type:'meta'}   strategy, cue, sources, mode
 *   {type:'delta'}  incremental text
 *   {type:'done'}   full text, mode, latency
 *   {type:'error'}  recoverable failure (client shows a soft notice)
 */
app.post('/api/chat', async (c) => {
  const body = await c.req
    .json<{
      message?: string
      lang?: string
      courseId?: string | null
      lessonId?: string | null
      sessionId?: number | null
      learnerId?: number | null
      history?: Turn[]
      name?: string | null
      forceGrounded?: boolean
    }>()
    .catch(() => ({}))

  const message = (body.message ?? '').trim().slice(0, 2000)
  if (!message) return c.json({ error: 'empty_message' }, 400)

  const lang = langByCode(body.lang ?? 'en')
  const chunks = await loadChunks(c.env.DB, body.courseId ?? null)
  const mastery = body.lessonId ? await getMastery(c.env.DB, body.learnerId ?? null, body.lessonId) : null

  const plan = buildPlan({
    message,
    history: body.history ?? [],
    lang,
    courseId: body.courseId ?? null,
    lessonId: body.lessonId ?? null,
    mastery,
    learnerName: body.name ?? null,
    chunks
  })

  const cue = cueFor(plan.strategy as Strategy)
  const sessionId = body.sessionId ?? null
  void appendTurn(c.env.DB, { sessionId, role: 'user', content: message, lang: lang.code })

  const encoder = new TextEncoder()
  const started = Date.now()
  const useModel = !body.forceGrounded && Boolean(c.env.OPENAI_API_KEY)

  const stream = new ReadableStream<Uint8Array>({
    async start(controller) {
      const send = (obj: unknown) => controller.enqueue(encoder.encode(JSON.stringify(obj) + '\n'))

      send({
        type: 'meta',
        strategy: plan.strategy,
        rationale: plan.rationale,
        cue,
        courseId: plan.courseId,
        sources: plan.hits.map((h) => ({ label: h.label, lessonId: h.lessonId, course: h.courseTitle })),
        mode: useModel ? 'model' : 'grounded',
        lang: { code: lang.code, bcp47: lang.bcp47, rtl: !!lang.rtl, native: lang.native },
        spokenLanguage: lang.bcp47
      })

      let full = ''
      let mode: 'model' | 'grounded' = 'grounded'

      if (useModel) {
        try {
          let buffer = ''
          for await (const delta of streamChat(c.env, plan.messages, { temperature: 0.6, maxTokens: 700 })) {
            full += delta
            buffer += delta
            // Refusal detection: providers can return quota notices as content.
            if (full.length < 160 && looksLikeRefusal(full)) throw new Error('PROVIDER_REFUSAL')
            // Flush complete sentences early: the avatar starts talking sooner.
            const m = buffer.match(/^([\s\S]*?[.!?…])\s+/)
            if (m) {
              send({ type: 'delta', text: m[1] + ' ' })
              buffer = buffer.slice(m[0].length)
            }
          }
          if (buffer.trim()) send({ type: 'delta', text: buffer })
          mode = 'model'
        } catch {
          // Any provider problem drops silently to the grounded tutor, which is
          // real curriculum teaching — not an error page in front of a learner.
          full = ''
        }
      }

      if (!full.trim()) {
        const g = groundedTurn({
          message,
          history: body.history ?? [],
          lang,
          courseId: body.courseId ?? null,
          lessonId: body.lessonId ?? null,
          mastery,
          learnerName: body.name ?? null,
          chunks
        })
        full = g.text
        mode = 'grounded'
        for (const s of toSentences(full)) send({ type: 'delta', text: s + ' ' })
      }

      // Correct the cue if we fell back to a different move than planned.
      if (mode === 'grounded' && cue.expression === 'focused') {
        send({ type: 'meta', patch: true, cue: { ...cue, expression: 'warm', energy: 0.45 } })
      }

      void appendTurn(c.env.DB, {
        sessionId,
        role: 'assistant',
        content: full,
        lang: lang.code,
        strategy: plan.strategy,
        grounded: mode === 'grounded'
      })

      send({ type: 'done', text: full, mode, latencyMs: Date.now() - started, strategy: plan.strategy })
      controller.close()
    }
  })

  return new Response(stream, {
    headers: {
      'content-type': 'application/x-ndjson; charset=utf-8',
      'cache-control': 'no-store',
      'x-accel-buffering': 'no'
    }
  })
})

/* --------------------------------------------------------------------- tts */

app.post('/api/tts', async (c) => {
  const body = await c.req
    .json<{ text?: string; lang?: string; voice?: string }>()
    .catch(() => ({}))
  const text = (body.text ?? '').trim()
  if (!text) return c.json({ error: 'empty_text' }, 400)

  const lang = langByCode(body.lang ?? 'en')
  const result = await synthesize({
    text,
    langCode: lang.code,
    bcp47: lang.bcp47,
    provider: c.env.TTS_PROVIDER,
    apiKey: c.env.TTS_API_KEY,
    baseUrl: c.env.TTS_BASE_URL,
    voiceMap: c.env.TTS_VOICE_MAP
  })

  if (!result.ok) {
    // 200 with a machine-readable fallback marker rather than 501: a non-2xx here
    // would log a console error on every single sentence a learner hears, and this
    // is an expected configuration state, not a failure.
    return c.json({ fallback: 'browser', reason: result.reason })
  }

  return new Response(result.audio, {
    headers: {
      'content-type': result.contentType,
      'cache-control': 'public, max-age=86400',
      'x-tts-provider': result.provider,
      'x-tts-voice': result.voice
    }
  })
})

/* ----------------------------------------------------------------- mastery */

app.post('/api/mastery', async (c) => {
  const body = await c.req.json<{ learnerId?: number; topicId?: string; correct?: boolean }>().catch(() => ({}))
  if (!body.learnerId || !body.topicId) return c.json({ error: 'bad_request' }, 400)
  const next = await updateMastery(c.env.DB, body.learnerId, body.topicId, Boolean(body.correct))
  return c.json({ mastery: next, persisted: Boolean(next) })
})

app.get('/api/mastery/:learnerId', async (c) => {
  if (!c.env.DB) return c.json({ mastery: [] })
  try {
    const { results } = await c.env.DB.prepare(
      'SELECT topic_id, score, attempts, last_seen FROM mastery WHERE learner_id = ? ORDER BY last_seen DESC LIMIT 50'
    )
      .bind(Number(c.req.param('learnerId')))
      .all()
    return c.json({ mastery: results ?? [] })
  } catch {
    return c.json({ mastery: [] })
  }
})

/* -------------------------------------------------------------- kb indexing */

/**
 * Idempotent curriculum mirror. Runs on deploy or on demand; keeps retrieval in
 * SQL as the corpus grows, and gives teachers a way to force-refresh content.
 */
app.post('/api/kb/seed', async (c) => {
  if (!c.env.DB) return c.json({ error: 'no_db' }, 400)
  let chunks = 0
  let lessons = 0
  try {
    for (const course of COURSES) {
      for (const lesson of course.lessons) {
        await c.env.DB.prepare(
          `INSERT INTO kb_lesson (lesson_id, course_id, payload) VALUES (?, ?, ?)
           ON CONFLICT(lesson_id) DO UPDATE SET payload = excluded.payload, updated_at = CURRENT_TIMESTAMP`
        )
          .bind(lesson.id, course.id, JSON.stringify(lesson))
          .run()
        lessons++

        const rows = [
          ...lesson.chunks.map((ch, i) => ({ idx: i, title: ch.title, body: ch.body })),
          ...lesson.misconceptions.map((m, i) => ({
            idx: 1000 + i,
            title: `Common misconception in ${lesson.title}`,
            body: `Misconception: ${m.wrong} Correction: ${m.right}`
          })),
          ...lesson.glossary.map((g, i) => ({ idx: 2000 + i, title: `Definition: ${g.term}`, body: `${g.term} — ${g.meaning}` }))
        ]
        for (const r of rows) {
          const keywords = `${r.title} ${r.body} ${lesson.title} ${course.title}`.toLowerCase()
          await c.env.DB.prepare(
            `INSERT INTO kb_chunk (course_id, lesson_id, chunk_idx, title, body, keywords) VALUES (?, ?, ?, ?, ?, ?)
             ON CONFLICT(lesson_id, chunk_idx) DO UPDATE SET title = excluded.title, body = excluded.body, keywords = excluded.keywords`
          )
            .bind(course.id, lesson.id, r.idx, r.title, r.body, keywords)
            .run()
          chunks++
        }
      }
    }
    return c.json({ ok: true, lessons, chunks })
  } catch (e) {
    return c.json({ error: 'seed_failed', detail: (e as Error).message.slice(0, 200) }, 500)
  }
})

/* ------------------------------------------------------- search (dev aid) */

app.get('/api/search', async (c) => {
  const q = c.req.query('q') ?? ''
  const chunks = await loadChunks(c.env.DB)
  const hits = searchChunks(chunks, q, { limit: Number(c.req.query('limit') ?? 5) })
  return c.json({
    query: q,
    hits: hits.map((h) => ({
      score: Number(h.score.toFixed(3)),
      lesson: h.chunk.lessonId,
      label: h.chunk.label,
      body: h.chunk.body.slice(0, 240)
    }))
  })
})

/* -------------------------------------------------------------------- pages */

app.get('/', (c) => c.html(shell({})))
app.get('/classroom', (c) => c.html(shell({ initialLesson: c.req.query('lesson') ?? null })))
app.get('/embed', (c) => c.html(shell({ embed: true, initialLesson: c.req.query('lesson') ?? null })))

app.get('/api/*', (c) => c.json({ error: 'not_found' }, 404))

export default app
