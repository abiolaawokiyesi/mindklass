// The teaching brain.
//
// This is the part that makes the avatar behave like a good teacher rather than
// a chatbot with a face. It decides HOW to answer before deciding WHAT to say:
//
//   diagnose  -> pick a strategy from the learner's utterance + their mastery
//   ground    -> retrieve approved curriculum text to anchor the answer
//   speak     -> short, spoken-style turns (TTS-friendly), one idea per turn
//   verify    -> end with a check question so understanding is measurable
//
// The strategy mix matters. A tutor that only explains produces passive learners;
// a tutor that only asks questions frustrates them. Real teachers alternate.

import { searchChunks, detectCourse, type KBChunk } from './retrieval'
import { langByCode, type Lang } from './languages'
import type { Msg } from './llm'

export type Strategy =
  | 'socratic'
  | 'worked_example'
  | 'explain'
  | 'analogy'
  | 'simplify'
  | 'correct'
  | 'quiz'
  | 'encourage'

export type Turn = { role: 'user' | 'assistant'; content: string }

export type PlanInput = {
  message: string
  history: Turn[]
  lang: Lang
  courseId?: string | null
  lessonId?: string | null
  mastery?: { score: number; attempts: number } | null
  learnerName?: string | null
  chunks: KBChunk[]
}

export type Plan = {
  strategy: Strategy
  rationale: string
  courseId: string | null
  hits: { label: string; body: string; lessonId: string; courseTitle: string; score: number }[]
  system: string
  messages: Msg[]
  /** Where to focus the avatar's attention (used for camera + gesture cues). */
  focus: 'explain' | 'listen' | 'celebrate' | 'think'
}

const has = (s: string, ...words: string[]) => words.some((w) => s.includes(w))

/** Cheap, transparent intent read. Cheap matters: it runs on every turn. */
export function readIntent(message: string) {
  const m = message.toLowerCase().trim()
  return {
    isGreeting: /^(hi|hello|hey|good (morning|afternoon|evening)|start|begin|hola|bonjour|salam|ẹ káà|bawo)/.test(m) || m.length < 3,
    wantsExample: has(m, 'example', 'show me', 'demonstrate', 'for instance', 'sample', 'like what'),
    wantsSimpler: has(m, 'simpler', 'simple', 'confus', "don't understand", 'do not understand', 'explain again', 'lost', 'hard', 'difficult', 'stuck'),
    wantsQuiz: has(m, 'quiz', 'test me', 'practice question', 'exam', 'past question', 'try me'),
    isAnswering: /^(yes|no|maybe|i think|it is|it\'s|because|true|false|option|[a-d]\b)/.test(m) && m.length < 220,
    isCorrectClaim: has(m, 'the answer is', 'i got', 'is it', 'i think', 'my answer'),
    expressesConfusion: has(m, 'why', 'how come', 'still', 'but wait', 'i don\'t get', 'what do you mean'),
    wantsToMoveOn: has(m, 'next', 'move on', 'continue', 'i understand now', 'got it', 'okay next'),
    isOffTopic: has(m, 'joke', 'football', 'music', 'song', 'game')
  }
}

export function chooseStrategy(input: PlanInput, intent = readIntent(input.message)): { strategy: Strategy; rationale: string } {
  const mastery = input.mastery?.score ?? 0
  const attempts = input.mastery?.attempts ?? 0
  const turnNo = input.history.filter((h) => h.role === 'assistant').length

  if (intent.wantsSimpler) {
    return {
      strategy: 'simplify',
      rationale: 'Learner signalled confusion, so re-teach from a lower rung with a smaller idea — no new vocabulary.'
    }
  }
  if (intent.wantsQuiz || (mastery > 0.72 && attempts >= 2 && turnNo > 3)) {
    return {
      strategy: 'quiz',
      rationale: 'Enough exposure to test retrieval; testing strengthens memory more than re-reading.'
    }
  }
  if (intent.wantsExample) {
    return {
      strategy: 'worked_example',
      rationale: 'Learner asked for an example — worked examples are the most efficient route for a novice.'
    }
  }
  if (intent.expressesConfusion && mastery < 0.5) {
    return {
      strategy: 'analogy',
      rationale: 'Confusion with low mastery: build a bridge from something they already know before formalising.'
    }
  }
  if (intent.isAnswering && mastery < 0.45) {
    return {
      strategy: 'correct',
      rationale: 'Learner attempted an answer; confirm or repair the specific error rather than starting over.'
    }
  }
  if (turnNo === 0) {
    return {
      strategy: 'explain',
      rationale: 'First turn: give the core idea in one breath, then hand the thinking back.'
    }
  }
  return {
    strategy: 'socratic',
    rationale: 'Learner is engaged and has some footing — a guiding question produces more durable learning than another explanation.'
  }
}

const STRATEGY_RULES: Record<Strategy, string> = {
  explain:
    'Give the core idea in 3 to 5 short sentences. Plain words. Then ask ONE short question that makes the learner apply it. Do not list more than three bullet points.',
  simplify:
    'The learner is lost. Drop to the smallest true version of the idea. Use everyday words only, one sentence per idea, maximum four sentences. Then check with one yes-or-no question.',
  socratic:
    'Do NOT give the answer. Ask one focused question that exposes the learner\'s current reasoning, then wait. If they have been stuck twice, give a hint that halves the problem.',
  worked_example:
    'Work one example aloud, step by step, narrating WHY each step is allowed. Then set a near-identical example for the learner and stop.',
  analogy:
    'Explain using one concrete everyday comparison a student would recognise. State where the comparison breaks down. Then connect it back to the formal term.',
  correct:
    'Say what is right first, then name the exact step that went wrong, then redo only that step. Never say "wrong" without immediately naming the correct move.',
  quiz:
    'Ask one exam-style question with clear numbers or terms. Do not reveal the answer. Wait for the learner. Keep the question spoken-friendly.',
  encourage:
    'Acknowledge genuine effort specifically, then give the next small step. Do not over-praise.'
}

export function buildPlan(input: PlanInput): Plan {
  const { message, lang, chunks } = input
  const intent = readIntent(message)
  const { strategy, rationale } = chooseStrategy(input, intent)

  const courseId = input.courseId || detectCourse(message, chunks) || null
  const rawHits = searchChunks(chunks, message, {
    limit: 4,
    courseId: courseId ?? undefined,
    lessonId: input.lessonId ?? undefined
  })
  const hits = rawHits.map((h) => ({
    label: h.chunk.label,
    body: h.chunk.body,
    lessonId: h.chunk.lessonId,
    courseTitle: h.chunk.courseTitle,
    score: Number(h.score.toFixed(2))
  }))

  const grounded =
    hits.length > 0
      ? hits.map((h, i) => `[${i + 1}] ${h.label} (${h.courseTitle})\n${h.body}`).join('\n\n')
      : 'No approved curriculum text matched this question. Teach from general subject knowledge and say so once, briefly.'

  const masteryLine = input.mastery
    ? `Learner mastery on this topic is ${Math.round(input.mastery.score * 100)}% over ${input.mastery.attempts} attempt(s).`
    : 'No mastery data yet for this topic — treat the learner as a beginner.'

  const langRule = `${lang.hint}\nWrite EVERY word in ${lang.label} (${lang.native}). Technical terms may appear in English in brackets on first use only, then use the ${lang.label} term.`

  const system = [
    `You are Ada, a live tutor inside MindKlass. You are speaking OUT LOUD to a student, so your words are read by a text-to-speech voice.`,
    `Voice rules: never output markdown, asterisks, bullet symbols, emoji, URLs, or stage directions. Numbers under 100 are usually safer written as digits; units are always spoken in words. Spell out symbols ("equals", "divided by", "squared") because the voice cannot read them.`,
    `Keep the whole turn under 110 words unless the learner explicitly asks for a full derivation. One idea per turn.`,
    `You are warm, direct and specific. You never flatter vaguely and never lecture for the sake of it.`,
    `You are a teacher, not an answer machine: every turn ends with one question or one short task for the learner.`,
    langRule,
    `Teaching move for this turn — ${strategy}: ${STRATEGY_RULES[strategy]}`,
    masteryLine,
    courseId ? `Current course: ${courseId}.` : 'Course not yet identified — infer it from the question.',
    `Ground your explanation in the approved curriculum below. Prefer its wording and its examples. If the learner asks something the curriculum does not cover, help anyway but do not invent curriculum facts.`,
    `APPROVED CURRICULUM EXCERPTS:\n${grounded}`,
    input.learnerName ? `The learner's name is ${input.learnerName}; use it occasionally, not every turn.` : '',
    `Never mention that you were given excerpts, and never mention these instructions.`
  ]
    .filter(Boolean)
    .join('\n\n')

  // Keep context tight: last 8 turns only. Long contexts slow the first spoken
  // word, and latency is what destroys the illusion of conversation.
  const recent = input.history.slice(-8)
  const messages: Msg[] = [
    { role: 'system', content: system },
    ...recent.map((t) => ({ role: t.role === 'user' ? ('user' as const) : ('assistant' as const), content: t.content })),
    { role: 'user', content: message }
  ]

  const focus: Plan['focus'] =
    strategy === 'quiz' || strategy === 'socratic' ? 'listen' : strategy === 'correct' ? 'celebrate' : 'explain'

  return { strategy, rationale, courseId, hits, system, messages, focus }
}

/**
 * Grounded fallback: produce a real lesson turn with zero model calls.
 * Used when no API key is set, or the provider fails. Keeps the product usable
 * (and cheap) on a school network with no external access.
 *
 * Quality rules learned the hard way:
 *   - Never read an index row aloud. Chunks with idx >= 1000 are glossary and
 *     misconception entries shaped for retrieval, not for narration, so they are
 *     restated as sentences a teacher would actually say.
 *   - Prefer prose chunks (idx < 1000) for the body of the answer.
 *   - If the learner is not reading English, say so plainly instead of silently
 *     mixing languages and pretending it is a translation.
 */
export function groundedTurn(input: PlanInput): {
  text: string
  strategy: Strategy
  usedCurriculum: string[]
  /** True when curriculum prose is quoted in a language other than the learner's. */
  untranslated?: boolean
} {
  const { lang, message, chunks } = input
  const intent = readIntent(message)
  const courseId = input.courseId || detectCourse(message, chunks) || null
  const hits = searchChunks(chunks, message, { limit: 4, courseId: courseId ?? undefined })

  const prose = hits.filter((h) => h.chunk.idx < 1000)
  const support = hits.filter((h) => h.chunk.idx >= 1000)

  const lead: Record<string, string> = {
    en: 'Here is the key idea',
    yo: 'Èrò pàtàkì ni yìí',
    ha: 'Babban ra\'ayi shi ne',
    ig: 'Echiche bụ isi bụ',
    pcm: 'The main thing be this',
    sw: 'Wazo kuu ni hili',
    fr: 'Voici l\'idée clé',
    es: 'La idea clave es esta',
    pt: 'A ideia central é esta',
    ar: 'الفكرة الأساسية هي',
    hi: 'मुख्य विचार यह है',
    ur: 'بنیادی خیال یہ ہے',
    zh: '核心思想是',
    am: 'ዋናው ሐሳብ ይህ ነው',
    tw: 'Adwene titiriw ne',
    zu: 'Umqondo oyisisekelo ukuthi',
    xh: 'Ingcamango engundoqo kukuba',
    sn: 'Pfungwa huru ndeyekuti',
    st: 'Khopolo ea bohlokoa ke hore',
    wo: 'Xala bu baax mi',
    rw: 'Igitekerezo gikuru ni',
    so: 'Fikradda muhiimka ah waa',
    bn: 'মূল ধারণাটি হলো'
  }

  const ask: Record<string, string> = {
    en: 'In your own words, how would you explain that to a classmate?',
    yo: 'Ní ọ̀rọ̀ rẹ, báwo ni ìwọ yóò ṣe àlàyé rẹ̀ fún ẹlẹ́gbẹ́ rẹ?',
    ha: 'A cikin kalmominka, yaya za ka bayyana wannan ga abokin karatu?',
    ig: 'N\'okwu gị, olee otu ị ga-akọwa nke a nye nwa akwụkwọ ibe gị?',
    pcm: 'Talk am for your own word — how you go explain am give your classmate?',
    sw: 'Kwa maneno yako mwenyewe, ungemweleza vipi mwanafunzi mwenzio?',
    fr: 'Avec tes propres mots, comment l\'expliquerais-tu à un camarade ?',
    es: 'Con tus propias palabras, ¿cómo se lo explicarías a un compañero?',
    pt: 'Com suas próprias palavras, como você explicaria isso a um colega?',
    ar: 'بكلماتك، كيف تشرح ذلك لزميلك؟',
    hi: 'अपने शब्दों में, आप इसे किसी सहपाठी को कैसे समझाएँगे?',
    ur: 'اپنے الفاظ میں آپ یہ کسی ساتھی کو کیسے سمجھائیں گے؟',
    zh: '用你自己的话，你会怎样向同学解释这一点？',
    am: 'በራስህ ቃላት ይህን ለአንድ ተማሪ እንዴት ታስረዳዋለህ?',
    tw: 'W\'ankasa w\'ano, wobɛkyerɛ wo mfɛfo no dɛn?',
    zu: 'Ngamazwi akho, ungakuchaza kanjani lokhu kumfundi akanye nawe?',
    xh: 'Ngamazwi akho, ungakuchaza njani oku kumfundi ofunda nawe?',
    sn: 'Nemashoko ako, ungatsanangura sei izvi kumwana waunofunda naye?',
    st: 'Ka mantsoe a hao, o ka hlalosa see joang ho moithuti eo o ithutang le yena?',
    wo: 'Ak sa bataaxal, naka la taxawaal ko ñaaw?',
    rw: 'Mu magambo yawe, wabivuga ute ku wundi munyeshuri?',
    so: 'Erayadaada, sidee ugu sharxi lahayd arday kale?',
    bn: 'নিজের ভাষায়, তুমি এটা বন্ধুকে কীভাবে ব্যাখ্যা করবে?'
  }

  /**
   * Honest disclosure, in the learner's language: curriculum prose is authored in
   * English, so in grounded mode a non-English learner gets an English quotation
   * with a native-language frame. Saying so is better than pretending it is a
   * translation — and it tells the school exactly why to configure a voice model.
   */
  const bridge: Record<string, string> = {
    en: '',
    yo: 'Àkíyèsí: àwọn àpilẹ̀kọ́ ẹ̀kọ́ wà ní èdè Gẹ̀ẹ́sì, mo sì ń ṣe àlàyé rẹ̀ ní Yorùbá.',
    ha: 'Sanarwa: rubutun darasin nan da Turanci yake, ina bayani a Hausa.',
    ig: 'Ọkwa: ihe ọmụmụ ahụ dị n\'Bekee, ana m akọwa ya n\'Igbo.',
    pcm: 'One note: the lesson text dey for English, I dey explain am for Pidgin.',
    sw: 'Kumbuka: maandishi ya somo yako kwa Kiingereza, ninaeleza kwa Kiswahili.',
    fr: 'Note : le texte du cours est en anglais, je vous l’explique en français.',
    es: 'Nota: el texto del curso está en inglés, se lo explico en español.',
    pt: 'Nota: o texto da lição está em inglês, estou explicando em português.',
    ar: 'ملاحظة: نص الدرس بالإنجليزية، وأنا أشرحه بالعربية.',
    hi: 'ध्यान दें: पाठ का पाठ अंग्रेज़ी में है, मैं हिंदी में समझा रही हूँ।',
    ur: 'نوٹ: سبق کا متن انگریزی میں ہے، میں اردو میں سمجھا رہی ہوں۔',
    zh: '说明：课程原文是英语，我用中文讲解。',
    am: 'ማስታወሻ፦ የትምህርቱ ጽሑፍ በእንግሊዝኛ ነው፤ በአማርኛ እያስረዳሁ ነው።',
    tw: 'Kae: adesua no nsɛm wɔ Borɔfo mu, me rekyerɛ mu wɔ Twi mu.',
    zu: 'Qaphela: umbhalo wesifundo usesiNgisini, ngichaza ngesiZulu.',
    xh: 'Qaphela: umbhalo wesifundo usesiNgesi, ndicacisa ngesiXhosa.',
    sn: 'Cherekedza: zvinyorwa zvedzidzo zviri neChirungu, ndiri kutsanangura nechiShona.',
    st: 'Ela hloko: mongolo wa thuto o ka Senyesemane, ke hlalosa ka Sesotho.',
    wo: 'Xam-xam: mbindum tëri bi ci Angale la, maa n taxawaal ko ci Wolof.',
    rw: 'Icyitonderwa: inyandiko y\'isomo iri mu Cyongereza, ndasobanura mu Kinyarwanda.',
    so: 'Ogeysiis: qoraalka casharka waa Ingiriisi, waxaan ku sharraxayaa Soomaali.',
    bn: 'দ্রষ্টব্য: পাঠের লেখা ইংরেজিতে, আমি বাংলায় বুঝিয়ে দিচ্ছি।'
  }

  const L = (m: Record<string, string>) => m[lang.code] ?? m.en
  const parts: string[] = []
  const nonEnglish = lang.code !== 'en'

  /** Turn an index row into something a teacher would actually say out loud. */
  const speechify = (chunk: KBChunk): string => {
    if (chunk.idx >= 2000) return chunk.body // "Term — meaning." already speaks well
    const body = chunk.body
    const misc = body.match(/^Misconception:\s*(.+?)\s*Correction:\s*(.+)$/is)
    if (misc) {
      return `A lot of students think ${misc[1].replace(/\.$/, '')} — actually, ${lowerFirst(misc[2])}`
    }
    return body
  }

  const primary = prose[0] ?? support[0] ?? null
  const secondary = prose[1] && prose[1] !== primary ? prose[1] : null

  if (nonEnglish && primary) parts.push(L(bridge))

  if (!primary && !support.length) {
    parts.push(lang.greeting)
  } else if (primary) {
    parts.push(`${L(lead)}: ${speechify(primary.chunk)}`)
    if (secondary) parts.push(speechify(secondary.chunk))
  }

  // A misconception is often the most useful thing to surface — but as a warning
  // the learner can act on, not as a second quoted record.
  const misc = support.find((h) => h.chunk.body.includes('Misconception:'))
  if (misc && prose.length < 2) {
    const m = misc.chunk.body.match(/^Misconception:\s*(.+?)\s*Correction:\s*(.+)$/is)
    if (m) {
      const warn: Record<string, string> = {
        en: 'One thing to watch:',
        yo: 'Ohun kan láti ṣọ́ra fún:',
        ha: 'Abu daya da za a lura da shi:',
        ig: 'Otu ihe ị ga-akpachara anya:',
        pcm: 'One thing you suppose watch:',
        sw: 'Jambo moja la kuzingatia:',
        fr: 'Un point d’attention :',
        es: 'Un punto a tener en cuenta:',
        pt: 'Um ponto de atenção:'
      }
      parts.push(`${warn[lang.code] ?? warn.en} ${lowerFirst(m[1])}. ${m[2]}`)
    }
  }

  if (intent.wantsExample) {
    const lesson = primary ? findWorked(primary.chunk.lessonId) : null
    if (lesson) {
      const exLabel: Record<string, string> = { en: 'Let us work one example.', yo: 'Ẹ jẹ́ kí a ṣe àpẹẹrẹ kan.' }
      parts.push(`${exLabel[lang.code] ?? exLabel.en} ${lesson.prompt} ${lesson.steps.join(' ')}`)
    }
  }

  parts.push(L(ask))

  return {
    text: parts.join(' ').replace(/\s+/g, ' ').trim(),
    strategy: primary ? 'explain' : 'encourage',
    usedCurriculum: [primary, secondary, misc]
      .filter((h): h is NonNullable<typeof h> => Boolean(h))
      .map((h) => h.chunk.label),
    untranslated: nonEnglish && Boolean(primary)
  }
}

function lowerFirst(s: string) {
  return s.charAt(0).toLowerCase() + s.slice(1)
}

import { findLesson } from '../kb/courses'
function findWorked(lessonId: string) {
  const found = findLesson(lessonId)
  return found?.lesson.worked[0] ?? null
}

/** Split into speakable sentences. TTS reads sentence-by-sentence so the
 *  avatar starts talking before the model has finished thinking. */
export function toSentences(text: string): string[] {
  return text
    .replace(/\s+/g, ' ')
    .split(/(?<=[.!?…])\s+(?=[^\s])/)
    .map((s) => s.trim())
    .filter(Boolean)
}
