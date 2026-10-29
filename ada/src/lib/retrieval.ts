// Retrieval over the curriculum.
//
// Design note: the corpus is small and curated, so a BM25-style lexical index
// answers in microseconds and keeps the whole tutor inside one Worker request.
// `loadChunks` prefers D1 (populated by `npm run kb:seed`) and falls back to the
// in-code corpus, so the same code path scales when the curriculum grows or a
// school adds its own material.

import { COURSES } from '../kb/courses'

export type KBChunk = {
  courseId: string
  courseTitle: string
  lessonId: string
  lessonTitle: string
  idx: number
  label: string
  body: string
  text: string
  tokens: string[]
}

const STOP = new Set(
  'the a an and or of to in is are was were be been being it its this that these those for with as at by from on not no you your we our i me my he she they them his her their do does did can could would should will shall may might must have has had if then than so such about into over under more most other some any each both few many own same very just but also there here what which who whom when where why how'.split(
    ' '
  )
)

const norm = (s: string) =>
  s
    .toLowerCase()
    .normalize('NFD')
    .replace(/[\u0300-\u036f]/g, '')
    .replace(/[^a-z0-9\u00c0-\u024f\s]/g, ' ')
    .replace(/\s+/g, ' ')
    .trim()

export const tokenize = (s: string): string[] =>
  norm(s)
    .split(' ')
    .filter((t) => t.length > 1 && !STOP.has(t))

let CACHE: KBChunk[] | null = null
let IDF: Map<string, number> | null = null
let AVG_LEN = 1

function buildCorpus(): KBChunk[] {
  const out: KBChunk[] = []
  for (const course of COURSES) {
    for (const lesson of course.lessons) {
      lesson.chunks.forEach((chunk, idx) => {
        const joined = `${chunk.title}. ${chunk.body}`
        out.push({
          courseId: course.id,
          courseTitle: course.title,
          lessonId: lesson.id,
          lessonTitle: lesson.title,
          idx,
          label: chunk.title,
          body: chunk.body,
          text: joined,
          tokens: tokenize(joined)
        })
      })
      // Objectives, misconceptions and glossary are retrieval-worthy too: a
      // learner's confusion often maps onto a misconception, not a paragraph.
      lesson.misconceptions.forEach((m, idx) => {
        const joined = `${m.wrong} ${m.right}`
        out.push({
          courseId: course.id,
          courseTitle: course.title,
          lessonId: lesson.id,
          lessonTitle: lesson.title,
          idx: 1000 + idx,
          label: `Common misconception in ${lesson.title}`,
          body: `Misconception: ${m.wrong} Correction: ${m.right}`,
          text: joined,
          tokens: tokenize(joined)
        })
      })
      lesson.glossary.forEach((g, idx) => {
        const joined = `${g.term} ${g.meaning}`
        out.push({
          courseId: course.id,
          courseTitle: course.title,
          lessonId: lesson.id,
          lessonTitle: lesson.title,
          idx: 2000 + idx,
          label: `Definition: ${g.term}`,
          body: `${g.term} — ${g.meaning}`,
          text: joined,
          tokens: tokenize(joined)
        })
      })
    }
  }
  return out
}

function ensureIndex() {
  if (CACHE) return
  CACHE = buildCorpus()
  const df = new Map<string, number>()
  let total = 0
  for (const c of CACHE) {
    total += c.tokens.length
    for (const t of new Set(c.tokens)) df.set(t, (df.get(t) ?? 0) + 1)
  }
  AVG_LEN = total / Math.max(1, CACHE.length)
  const N = CACHE.length
  IDF = new Map()
  for (const [t, n] of df) IDF.set(t, Math.log(1 + (N - n + 0.5) / (n + 0.5)))
}

/** Try D1 first (populated by kb:seed); fall back to the in-code corpus. */
export async function loadChunks(db?: D1Database, courseId?: string | null): Promise<KBChunk[]> {
  ensureIndex()
  if (!db) return CACHE!
  try {
    // The original query joined a table alias ("l") that was never declared, so it
    // threw on every call and the D1 path silently never ran. Fixed here. When the
    // learner is inside a course only that course is read: the free D1 plan allows
    // 5 million row reads a day, and reading the whole corpus on every turn would
    // use that up quickly.
    const stmt = db.prepare(
      `SELECT course_id, lesson_id, chunk_idx, title, body FROM kb_chunk ${courseId ? 'WHERE course_id = ?' : ''} LIMIT 3000`
    )
    const { results } = await (courseId ? stmt.bind(courseId) : stmt).all<{
      course_id: string
      lesson_id: string
      chunk_idx: number
      title: string
      body: string
    }>()
    if (!results || results.length < 12) return CACHE!

    // Titles for courses and lessons that only exist in D1 (for example the
    // MindKlass lesson notes loaded by scripts/gen-mindklass-seed.ps1).
    const names = new Map<string, string>()
    try {
      const t = await db.prepare('SELECT id, title FROM kb_title').all<{ id: string; title: string }>()
      for (const r of t.results ?? []) names.set(r.id, r.title)
    } catch {
      /* table not created yet: fall back to ids */
    }
    const titleOf = (cid: string) => COURSES.find((c) => c.id === cid)?.title ?? names.get(cid) ?? cid
    const lessonTitle = (lid: string) => {
      for (const c of COURSES) {
        const l = c.lessons.find((x) => x.id === lid)
        if (l) return l.title
      }
      return names.get(lid) ?? lid
    }
    return results.map((r) => {
      const text = `${r.title ?? ''}. ${r.body}`
      return {
        courseId: r.course_id,
        courseTitle: titleOf(r.course_id),
        lessonId: r.lesson_id,
        lessonTitle: lessonTitle(r.lesson_id),
        idx: r.chunk_idx,
        label: r.title ?? '',
        body: r.body,
        text,
        tokens: tokenize(text)
      }
    })
  } catch {
    return CACHE!
  }
}

export type Hit = { chunk: KBChunk; score: number }

export function searchChunks(
  chunks: KBChunk[],
  query: string,
  opts: { limit?: number; courseId?: string; lessonId?: string } = {}
): Hit[] {
  ensureIndex()
  const q = tokenize(query)
  if (!q.length) return []
  const limit = opts.limit ?? 4
  const k1 = 1.4
  const b = 0.72
  const scored: Hit[] = []

  for (const c of chunks) {
    if (opts.courseId && c.courseId !== opts.courseId) continue
    if (opts.lessonId && c.lessonId !== opts.lessonId) continue
    const len = c.tokens.length || 1
    const freq = new Map<string, number>()
    for (const t of c.tokens) freq.set(t, (freq.get(t) ?? 0) + 1)
    let score = 0
    for (const term of q) {
      const f = freq.get(term)
      if (!f) continue
      const idf = IDF?.get(term) ?? 1
      score += idf * ((f * (k1 + 1)) / (f + k1 * (1 - b + b * (len / AVG_LEN))))
    }
    // Small boost when the query term appears in the chunk label / lesson title.
    const labelled = norm(`${c.label} ${c.lessonTitle}`)
    for (const term of q) if (labelled.includes(term)) score *= 1.12
    // A tight, focused chunk is more useful than a rambling match.
    if (c.idx >= 2000) score *= 0.96
    if (score > 0) scored.push({ chunk: c, score })
  }
  scored.sort((a, b2) => b2.score - a.score)
  return scored.slice(0, limit)
}

/** Most curriculum-relevant course given free text (used for auto-routing). */
export function detectCourse(query: string, chunks: KBChunk[]): string | null {
  const hits = searchChunks(chunks, query, { limit: 5 })
  if (!hits.length) return null
  const tally = new Map<string, number>()
  for (const h of hits) tally.set(h.chunk.courseId, (tally.get(h.chunk.courseId) ?? 0) + h.score)
  return [...tally.entries()].sort((a, b) => b[1] - a[1])[0][0]
}
