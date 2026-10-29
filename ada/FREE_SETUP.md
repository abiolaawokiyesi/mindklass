# Ada: getting it fully working on free tools

Ada is a separate small service (Cloudflare Pages + D1). MindKlass shows it inside the
**Ask Ada** page, in the bottom tab bar and in the side menu. Until you give MindKlass
the Ada address, students see "Ada is coming soon" (admins see these instructions).

Free-plan figures below come from third-party summaries gathered in October 2026 and
vendors change them often. **Check each vendor's own pricing page before you rely on a number.**

## What is free, and what is not

| Part | Free choice | Notes |
|---|---|---|
| Hosting Ada | Cloudflare Pages + Pages Functions | Free plan: about 100,000 function requests a day, shared with Workers. Static files are not counted. |
| Ada's database | Cloudflare D1 | Free plan: about 5 million row reads and 100,000 row writes a day. Ada reads one course per turn, so seed the courses you want taught, not everything. |
| Tutor brain | Groq free tier, or Google AI Studio (Gemini Flash), or OpenRouter free models | All speak the OpenAI chat format, so **no code change**: set three variables (below). Free limits are per minute and per day, so cap daily messages per student. |
| Speech to text | Browser speech recognition (Chrome and Edge) | Already built in. Weaker for African languages. Groq's free Whisper is a possible upgrade, not wired in yet. |
| Text to speech | The phone's own voice (already built in) | Free and always there, but many Android phones have **no** Yoruba, Hausa or Igbo voice. See "Voice" below. |
| The avatar face | The built-in drawn avatar | Free, light on data, works on low-end phones. A photoreal 3D face needs a 3D asset (not free to make well). |
| Login | Supabase (you already use it) | Set `SUPABASE_JWT_SECRET` before going live. |

## One-time setup (about 30 minutes)

You need Node.js (LTS) installed: <https://nodejs.org>. Then, in a terminal:

```bash
cd ada
npm install
npx wrangler login
npx wrangler d1 create mindklass-avatar-production
```

Copy the `database_id` it prints into `wrangler.jsonc` (replace `local-dev-placeholder`).

Load the course notes you want Ada to teach from. This writes `migrations/0003_mindklass_notes.sql`
from the MindKlass notes (change the pattern to choose courses, for example `NG-SS3-*`):

```powershell
powershell -NoProfile -File .\scripts\gen-mindklass-seed.ps1 -Pattern 'NG-SS2-BIO-*'
```

```bash
npx wrangler d1 migrations apply mindklass-avatar-production --remote
npm run build
npx wrangler pages deploy dist --project-name mindklass-ada
```

Set the tutor brain (example: Groq; get a free key at <https://console.groq.com>). Check the model name
in the Groq console, because model names change:

```bash
npx wrangler pages secret put OPENAI_API_KEY --project-name mindklass-ada
npx wrangler pages secret put OPENAI_BASE_URL --project-name mindklass-ada     # https://api.groq.com/openai/v1
npx wrangler pages secret put AVATAR_LLM_MODEL --project-name mindklass-ada    # for example llama-3.3-70b-versatile
npx wrangler pages secret put SUPABASE_JWT_SECRET --project-name mindklass-ada # from Supabase, Project Settings, API
```

Finally open `dist/ada-config.js` in MindKlass, set the address Cloudflare gave you, and deploy MindKlass as usual:

```js
window.MK_ADA_URL = "https://mindklass-ada.pages.dev";
```

Open MindKlass, tap **Ask Ada**. `https://mindklass-ada.pages.dev/api/health` should say which brain is answering.
`ada/public/_headers` only lets mindklass.com (and localhost) put Ada in a frame; edit it if your domain differs.

## Voice: be careful about what you promise

The README that came with Ada recommends Azure for Yoruba, Hausa and Igbo and lists voice names such as
`yo-NG-IyanuNeural`. **I could not confirm those voices exist**: searches of Microsoft's and Google's
pages did not show Yoruba, Hausa or Igbo neural voices. Before paying for or promising any provider, call its
"list voices" API and look for the language, or listen to a sample. Free or open options to test:

- The browser voice (free). Works for English and often Swahili; test Yoruba, Hausa and Igbo on real phones.
- Meta MMS text to speech on Hugging Face (`facebook/mms-tts-yor`, `facebook/mms-tts-hau`): free to try, but
  the licence is **non-commercial (CC BY-NC 4.0)**, so it is fine for a pilot and not for a paid product. An Igbo
  model of the same name could not be confirmed.
- Open Nigerian-language voice models such as YarnGPT, which advertises Yoruba, Igbo and Hausa: check the licence and quality yourself.
- Nigerian commercial services (for example NaijaLingo) are not free.

Pre-recorded narration (`tools/generate-voice.py` with edge-tts, which you already use for MindKlass) remains the
cheapest reliable voice for fixed lesson text; live conversation is what needs the voice service.

## Before real students use it

1. Set `SUPABASE_JWT_SECRET` (otherwise Ada accepts unsigned tokens, which is fine for testing only).
2. Decide how long chat transcripts are kept (`turn` rows are kept indefinitely) and tell parents and schools.
3. Test about 50 real learner questions per language and read the answers before launch.
4. Put a daily message limit per student so the free quota lasts.

## What changed in this copy of Ada

- `src/lib/retrieval.ts`: fixed a database query that referred to a table alias that was never declared. It failed
  on every call, so Ada never used the D1 notes. It now reads only the open course, and shows course and lesson names from the new `kb_title` table.
- `src/index.tsx`: passes the open course to retrieval.
- `migrations/0002_kb_title.sql`, `scripts/gen-mindklass-seed.ps1`: load MindKlass lesson notes into Ada.
- `public/_headers`: only MindKlass may embed Ada.
- Not changed, and not run here: there was no Node.js on this computer, so the Cloudflare side has **not** been built or
  executed. The MindKlass side (Ask Ada page, connection check, offline states) was tested in the browser with a stand-in service.
