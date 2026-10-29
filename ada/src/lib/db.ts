// D1 access helpers. Every write is best-effort: the teaching path must work even
// when the database binding is missing (e.g. a teacher demoing offline), so these
// functions never throw into a request handler.

export type Env = {
  DB?: D1Database
  OPENAI_API_KEY?: string
  OPENAI_BASE_URL?: string
  AVATAR_LLM_MODEL?: string
  SUPABASE_JWT_SECRET?: string
  TTS_PROVIDER?: string
  TTS_API_KEY?: string
  TTS_VOICE_MAP?: string
  TTS_BASE_URL?: string
}

export async function ensureLearner(
  db: D1Database | undefined,
  uid: string,
  name?: string | null,
  lang = 'en'
): Promise<number | null> {
  if (!db) return null
  try {
    const found = await db.prepare('SELECT id FROM learner WHERE supabase_uid = ?').bind(uid).first<{ id: number }>()
    if (found?.id) return found.id
    const ins = await db
      .prepare('INSERT INTO learner (supabase_uid, display_name, native_lang) VALUES (?, ?, ?)')
      .bind(uid, name ?? null, lang)
      .run()
    return Number(ins.meta?.last_row_id) || null
  } catch {
    return null
  }
}

export async function startSession(
  db: D1Database | undefined,
  args: { learnerId: number | null; personaId: string; lessonId?: string | null; lang: string }
): Promise<number | null> {
  if (!db) return null
  try {
    const r = await db
      .prepare('INSERT INTO session (learner_id, persona_id, lesson_id, lang) VALUES (?, ?, ?, ?)')
      .bind(args.learnerId, args.personaId, args.lessonId ?? null, args.lang)
      .run()
    return Number(r.meta?.last_row_id) || null
  } catch {
    return null
  }
}

export async function appendTurn(
  db: D1Database | undefined,
  args: {
    sessionId: number | null
    role: 'user' | 'assistant'
    content: string
    lang: string
    strategy?: string | null
    grounded?: boolean
    tokensIn?: number
    tokensOut?: number
  }
): Promise<void> {
  if (!db || !args.sessionId) return
  try {
    await db
      .prepare(
        'INSERT INTO turn (session_id, role, content, lang, strategy, grounded, tokens_in, tokens_out) VALUES (?, ?, ?, ?, ?, ?, ?, ?)'
      )
      .bind(
        args.sessionId,
        args.role,
        args.content.slice(0, 8000),
        args.lang,
        args.strategy ?? null,
        args.grounded ? 1 : 0,
        args.tokensIn ?? 0,
        args.tokensOut ?? 0
      )
      .run()
    await db.prepare('UPDATE session SET turn_count = turn_count + 1 WHERE id = ?').bind(args.sessionId).run()
  } catch {
    /* telemetry must never break teaching */
  }
}

/** Exponential moving average — cheap, explainable, and good enough to drive UI. */
export async function updateMastery(
  db: D1Database | undefined,
  learnerId: number | null,
  topicId: string,
  correct: boolean
) {
  if (!db || !learnerId) return null
  try {
    const row = await db
      .prepare('SELECT score, attempts FROM mastery WHERE learner_id = ? AND topic_id = ?')
      .bind(learnerId, topicId)
      .first<{ score: number; attempts: number }>()
    const prev = row?.score ?? 0.35
    const next = Math.max(0, Math.min(1, prev * 0.7 + (correct ? 1 : 0) * 0.3))
    if (row) {
      await db
        .prepare('UPDATE mastery SET score = ?, attempts = attempts + 1, last_seen = CURRENT_TIMESTAMP WHERE learner_id = ? AND topic_id = ?')
        .bind(next, learnerId, topicId)
        .run()
    } else {
      await db
        .prepare('INSERT INTO mastery (learner_id, topic_id, score, attempts) VALUES (?, ?, ?, 1)')
        .bind(learnerId, topicId, next)
        .run()
    }
    return { score: next, attempts: (row?.attempts ?? 0) + 1 }
  } catch {
    return null
  }
}

export async function getMastery(db: D1Database | undefined, learnerId: number | null, topicId: string) {
  if (!db || !learnerId) return null
  try {
    return await db
      .prepare('SELECT score, attempts FROM mastery WHERE learner_id = ? AND topic_id = ?')
      .bind(learnerId, topicId)
      .first<{ score: number; attempts: number }>()
  } catch {
    return null
  }
}
