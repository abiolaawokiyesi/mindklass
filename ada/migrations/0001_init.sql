-- MindKlass Avatar Engine -- D1 schema
-- Safe to run repeatedly (CREATE IF NOT EXISTS / INSERT OR IGNORE).

CREATE TABLE IF NOT EXISTS learner (
  id            INTEGER PRIMARY KEY AUTOINCREMENT,
  supabase_uid  TEXT UNIQUE,               -- links to MindKlass Supabase auth.users
  display_name  TEXT,
  native_lang   TEXT DEFAULT 'en',
  tier          TEXT DEFAULT 'free',       -- free | pro | school
  created_at    DATETIME DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS session (
  id            INTEGER PRIMARY KEY AUTOINCREMENT,
  learner_id    INTEGER,
  persona_id    TEXT NOT NULL,
  lesson_id     TEXT,
  lang          TEXT DEFAULT 'en',
  started_at    DATETIME DEFAULT CURRENT_TIMESTAMP,
  ended_at      DATETIME,
  turn_count    INTEGER DEFAULT 0,
  FOREIGN KEY (learner_id) REFERENCES learner(id)
);

CREATE TABLE IF NOT EXISTS turn (
  id            INTEGER PRIMARY KEY AUTOINCREMENT,
  session_id    INTEGER NOT NULL,
  role          TEXT NOT NULL,             -- user | tutor
  content       TEXT NOT NULL,
  lang          TEXT,
  strategy      TEXT,                      -- socratic | worked_example | analogy ...
  grounded      INTEGER DEFAULT 0,         -- 1 = answer came from approved lesson content
  tokens_in     INTEGER DEFAULT 0,
  tokens_out    INTEGER DEFAULT 0,
  created_at    DATETIME DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (session_id) REFERENCES session(id)
);
CREATE INDEX IF NOT EXISTS idx_turn_session ON turn(session_id);

-- Deterministic, cheap "understanding" signal used by the teacher dashboard.
CREATE TABLE IF NOT EXISTS mastery (
  id            INTEGER PRIMARY KEY AUTOINCREMENT,
  learner_id    INTEGER NOT NULL,
  topic_id      TEXT NOT NULL,
  score         REAL DEFAULT 0,            -- 0..1 running estimate
  attempts      INTEGER DEFAULT 0,
  last_seen     DATETIME DEFAULT CURRENT_TIMESTAMP,
  UNIQUE(learner_id, topic_id)
);

-- Concept-level retrieval index (keyword -> lesson chunk). Populated by
-- `npm run kb:seed`. Powers grounded RAG without a vector DB, which keeps the
-- whole thing inside a single Worker request budget.
CREATE TABLE IF NOT EXISTS kb_chunk (
  id            INTEGER PRIMARY KEY AUTOINCREMENT,
  course_id     TEXT NOT NULL,
  lesson_id     TEXT NOT NULL,
  chunk_idx     INTEGER NOT NULL,
  title         TEXT,
  body          TEXT NOT NULL,
  keywords      TEXT NOT NULL,             -- space separated, lowercased
  UNIQUE(lesson_id, chunk_idx)
);
CREATE INDEX IF NOT EXISTS idx_kb_course ON kb_chunk(course_id);
CREATE INDEX IF NOT EXISTS idx_kb_lesson ON kb_chunk(lesson_id);

-- Raw lesson JSON as authored (so the course player can render the real lesson
-- without shipping everything to the browser).
CREATE TABLE IF NOT EXISTS kb_lesson (
  lesson_id     TEXT PRIMARY KEY,
  course_id     TEXT NOT NULL,
  payload       TEXT NOT NULL,
  updated_at    DATETIME DEFAULT CURRENT_TIMESTAMP
);

-- Per-course enrolment so one Supabase user can hold several classes.
CREATE TABLE IF NOT EXISTS enrolment (
  id            INTEGER PRIMARY KEY AUTOINCREMENT,
  learner_id    INTEGER NOT NULL,
  course_id     TEXT NOT NULL,
  created_at    DATETIME DEFAULT CURRENT_TIMESTAMP,
  UNIQUE(learner_id, course_id)
);
