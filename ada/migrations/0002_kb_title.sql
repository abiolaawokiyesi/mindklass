-- Display names for courses and lessons that live only in D1 (for example the
-- MindKlass lesson notes loaded by scripts/gen-mindklass-seed.ps1). Safe to re-run.
CREATE TABLE IF NOT EXISTS kb_title (
  id     TEXT PRIMARY KEY,   -- a course_id or a lesson_id
  title  TEXT NOT NULL
);
