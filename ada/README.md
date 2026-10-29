# MindKlass — Ada, the Live Tutor Avatar

A talking tutor that teaches MindKlass courses and holds a real conversation with
a learner in their own language. Built to sit **beside** the existing MindKlass
React SPA, not to replace it.

> **Why a separate app and not another patch to `dist/assets/app.js`?**
> MindKlass adds every feature by script-patching one 9 MB minified bundle whose
> source is lost. That is exactly the fragility you described. New surface area
> belongs in its own deployable, with real source, that the SPA links to or embeds
> in an iframe. Nothing here touches your existing bundle.

---

## What it does

- **Teaches out loud.** Ada delivers a lesson as short spoken beats — objective,
  explanation, worked example, then a comprehension question. She stops at the
  question and waits. That is the difference between a lecture recording and a class.
- **Converts.** Press *Talk* at any moment and she stops mid‑sentence and listens.
  Typed input is always available as a fallback.
- **Teaches in the learner's language.** 23 languages configured, including Yoruba,
  Hausa, Igbo, Nigerian Pidgin, Swahili, Amharic, Twi, Zulu, Xhosa, Shona, Sesotho,
  Wolof, Kinyarwanda and Somali. The exam term stays in English; the explanation is native.
- **Behaves like a teacher, not a chatbot.** Before answering it picks a pedagogical
  move — Socratic question, worked example, analogy, plain explanation, error repair,
  or a quiz — based on what the learner just said and how well they know the topic.
- **Grounds every answer in approved curriculum,** then cites the lesson it used.
- **Measures understanding.** Answers update a per-topic mastery estimate.

---

## Current status — what is real

| Capability | State |
|---|---|
| Avatar rendering, 60 fps on low-end phones | ✅ working, verified in-browser |
| Lip-sync + blink + gaze + gesture + 7 expressions | ✅ working |
| 4 courses / 9 lessons / 82 indexed chunks | ✅ working |
| Grounded tutoring (no API key needed) | ✅ working |
| Streaming chat over NDJSON, sentence-level speech start | ✅ working |
| 23 languages, greetings + prompts in-language | ✅ working |
| Lesson player with comprehension gates | ✅ working |
| Mastery tracking, session + turn logging in D1 | ✅ working |
| Text-to-speech | ⚠️ **device voice by default** — see *Voice* below |
| Speech *recognition* | ⚠️ Chrome/Edge only; weaker for African languages |
| Model-backed tutoring | ⏳ **needs a working API key** (see *Tutor brain*) |
| Photoreal GLB avatar | ⏳ not shipped — architecture supports it, asset not included |

### Two limitations you should know before deploying

**1. Voice.** By default Ada uses the browser's `speechSynthesis`. That is free and
always available, but on Android and iOS there is frequently **no voice installed
for Yoruba, Hausa, Igbo, Twi or Amharic**, so the device falls back to reading them
in an English accent — or says nothing. Real neural voices for those languages need
a commercial TTS key. The proxy is already written (`src/lib/tts.ts`, supports Azure,
ElevenLabs, OpenAI and Google); set `TTS_PROVIDER` + `TTS_API_KEY` and the browser
voice stops being used automatically.

> **Correction (October 2026):** this README originally recommended Azure for
> Yoruba, Hausa and Igbo. That claim, and the voice names in `AZURE_VOICES`
> (for example `yo-NG-IyanuNeural`), could **not** be confirmed; searches of
> Microsoft's and Google's documentation did not show those three languages. Call the
> provider's "list voices" API and listen to a sample before you promise a language.
> See `FREE_SETUP.md` for free options and licences.

**2. Tutor brain.** The LLM proxy available in this sandbox returns a
`free_plan_block` refusal on every call (credits exhausted), so the model path is
wired but **unverified end-to-end**. Without a key, Ada runs in *grounded mode*:
she teaches from the approved curriculum using the exact same pedagogy layer and
avatar, but cannot paraphrase a free-form question. She says so plainly in
non-English languages rather than pretending English prose is a translation.
Set `OPENAI_API_KEY` (+ optional `OPENAI_BASE_URL`, `AVATAR_LLM_MODEL`) to enable it.
The fallback is automatic and silent — a learner never sees an error page.

---

## Architecture

```
src/
  index.tsx            Hono routes (edge, single request per turn)
  ui/shell.ts          server-rendered HTML shell
  kb/courses.ts        curriculum source of truth (lessons, checks, misconceptions)
  lib/
    llm.ts             provider client; refusal detection; graceful degradation
    pedagogy.ts        strategy selection, prompts, grounded fallback
    retrieval.ts       BM25 lexical index over D1 or in-code corpus
    languages.ts       23-language registry (tag, greeting, teaching hint)
    tts.ts             neural TTS proxy (azure / elevenlabs / openai / google)
    auth.ts            Supabase JWT verification (see note below)
    db.ts              D1 writes, mastery EMA
public/static/js/
  app.js               controller: boot, lesson playback, chat, mic, language
  rig.js               the rig channel — single source of truth for the face
  renderer.js          procedural portrait renderer (Canvas 2D)
  speech.js            TTS chain + lip-sync driver + interruption
  visemes.js           grapheme→viseme + timed schedules
  stt.js               speech recognition wrapper
migrations/            D1 schema + generated seed
scripts/gen-seed.mjs   regenerates seed.sql from courses.ts
```

### The three decisions worth knowing

**The rig is a channel, not a model.** `rig.js` holds face state; `renderer.js` and
`speech.js` only read or write that state. That is why a photoreal GLB can be swapped
in later without touching teaching logic — and why the avatar react instantly to a
new expression without a 3D asset load.

**Lip-sync is two-signal.** Synthesised speech has flat loudness, so amplitude-only
animation looks like a fish. The text prior picks *which* mouth shape, the live
WebAudio analyser decides *whether* and *how wide*. Gated on real signal energy, so
the mouth does not flap through silences. Browser TTS exposes no audio graph, so
there we synthesise an envelope from the viseme schedule instead.

**Retrieval is lexical, not vector.** The corpus is small and reviewed. BM25 answers
in microseconds and keeps a turn inside one Worker request with no external
embedding call. It reads from D1 when seeded and from code otherwise.

---

## API

| Method | Path | Purpose |
|---|---|---|
| GET | `/api/health` | Honest capability report (tutor mode, TTS mode, DB, auth) |
| GET | `/api/courses` · `/api/courses/:id` · `/api/lessons/:id` | Curriculum |
| GET | `/api/languages` | 23 languages + whether neural voice is available |
| POST | `/api/session` | Start session, return in-language greeting |
| POST | `/api/chat` | **Streaming tutor turn (NDJSON)** |
| POST | `/api/tts` | Neural TTS proxy; returns `{fallback:'browser'}` if unconfigured |
| POST | `/api/mastery` · GET `/api/mastery/:learnerId` | Mastery estimate |
| POST | `/api/kb/seed` | Idempotent curriculum mirror into D1 |
| GET | `/api/search?q=` | Retrieval debugging for curriculum authors |

`/api/chat` streams `{type:'meta'|'delta'|'done'}`. `meta` carries the strategy, the
avatar cue, and the source lessons — so the UI can show *why* Ada answered that way.

---

## Running it

```bash
npm run build
npm run db:migrate:local     # schema + curriculum seed
pm2 start ecosystem.config.cjs
curl localhost:3000/api/health
```

## Configuring it

| Variable | Effect if unset |
|---|---|
| `OPENAI_API_KEY` | Grounded mode (curriculum only, no free-form paraphrase) |
| `OPENAI_BASE_URL` | OpenAI default |
| `AVATAR_LLM_MODEL` | `gpt-5-mini` |
| `TTS_PROVIDER` + `TTS_API_KEY` | Device voice |
| `TTS_VOICE_MAP` | JSON `{"yo":"yo-NG-IyanuNeural"}` per-language override |
| `SUPABASE_JWT_SECRET` | Tokens decoded but **not** signature-verified |

⚠️ **On `SUPABASE_JWT_SECRET`:** when it is absent, `/api/chat` accepts an unsigned
Supabase token. That is deliberate so local development is never blocked, and
`/api/health` reports `auth.verified: false` so it cannot be mistaken for a secure
deployment. **Set it before going live.**

---

## Adding a course

Add to `COURSES` in `src/kb/courses.ts`, run `npm run kb:seed`, then
`npm run db:migrate:local`. Retrieval, the lesson player and the tutor pick it up
with no other change.

---

## Next steps, in priority order

1. **Set a TTS key.** This is the single biggest quality jump. Without it the African
   language promise is only partly kept, because the device has no voice.
2. **Set an LLM key and test ~50 real learner questions** against the strategy layer.
   Tune `STRATEGY_RULES` in `pedagogy.ts` on what you see.
3. **Replace the procedural avatar with a photoreal GLB** if that is the bar. Keep
   `rig.js` as the channel and add a `renderer3d.js` that maps the same fields onto
   morph targets. Budget 15–60 MB and test on a real 2 GB Android first.
4. **Consent + recording policy.** The avatar looks like a person and speaks
   naturally. You need a signed policy for voice/transcript storage before schools
   adopt it — `turn` rows currently persist transcripts indefinitely.
5. **Move the curriculum to Supabase** if teachers will author content. The D1 mirror
   exists for exactly this migration; `loadChunks` already prefers the database.
6. **Add a teacher dashboard** on top of `mastery` + `turn`. The data is there.

---

## Not yet implemented

- Photoreal 3D avatar asset (architecture ready, asset absent)
- Real-time voice (sub-second barge-in) — current turn-taking is speech-end based
- Pronunciation scoring / phoneme-level feedback
- Offline PWA caching beyond the shell
- Paystack/Agora integration — these stay in the MindKlass SPA
