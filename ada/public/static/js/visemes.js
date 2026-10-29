/**
 * Grapheme → viseme for spoken English text.
 *
 * Why do this at all: synthesised speech has unusually flat loudness, so an
 * amplitude-only mouth looks like a fish. We need to know *which* sound the
 * mouth is on, not just how loud it is.
 *
 * Approach: estimate each word's duration from syllable count, distribute
 * visemes inside that window, then let the live audio energy decide the actual
 * aperture. It is a two-signal system — the text gives shape, the audio gives
 * timing. That combination looks convincingly right without shipping a 40 MB
 * acoustic model to a phone.
 */

const DIGITS = {
  '0': 'zero', '1': 'one', '2': 'two', '3': 'three', '4': 'four',
  '5': 'five', '6': 'six', '7': 'seven', '8': 'eight', '9': 'nine'
}
const SYMBOLS = {
  '+': ' plus ', '-': ' minus ', '=': ' equals ', '/': ' divided by ',
  '×': ' times ', '*': ' times ', '%': ' percent ', '²': ' squared ',
  '°': ' degrees ', '&': ' and ', '≈': ' approximately '
}

/** Expand digits/symbols so both the voice and the mouth agree with the words. */
export function normalizeForSpeech(text) {
  let s = text
  for (const [k, v] of Object.entries(SYMBOLS)) s = s.split(k).join(v)
  s = s.replace(/\b\d+\b/g, (m) => {
    if (m.length <= 2) return m.split('').map((d) => ' ' + DIGITS[d]).join('').trim()
    return m.split('').map((d) => DIGITS[d]).join(' ')
  })
  return s
}

const ONSETS = [
  [/^(sh|ch|tch|j|zh|g[eiy])/, 'S'],
  [/^(th)/, 'etc'],
  [/^(ph|f|v)/, 'FV'],
  [/^(m|b|p)/, 'MBP'],
  [/^(qu|wh|w|oo)/, 'WQ'],
  [/^(r|er|ir|ur|ear)/, 'WQ'],
  [/^(l)/, 'L'],
  [/^(oa|ow|o|au|aw|augh)/, 'O'],
  [/^(ee|ea|ie|ei|y|igh|i)/, 'I'],
  [/^(a|e)/, 'E'],
  [/^(s|z|c|ts|x)/, 'S'],
  [/^(n|d|t|k|g|h|ck)/, 'etc']
]

export function wordToVisemes(word) {
  const w = word.toLowerCase().replace(/[^a-z]/g, '')
  if (!w) return []
  const out = []
  let i = 0
  while (i < w.length) {
    const rest = w.slice(i)
    let hit = false
    for (const [re, v] of ONSETS) {
      const m = re.exec(rest)
      if (m) { out.push(v); i += m[1].length; hit = true; break }
    }
    if (!hit) i += 1
  }
  // Cap so very long words do not monopolise the mouth.
  return out.slice(0, 6)
}

/** Rough syllable count — good enough to pace a mouth. */
export function syllables(word) {
  const w = word.toLowerCase().replace(/[^a-z]/g, '')
  if (!w) return 1
  const groups = w.replace(/e$/, '').match(/[aeiouy]+/g)
  return Math.max(1, groups ? groups.length : 1)
}

/**
 * Build a timed viseme schedule for a sentence.
 * @param {string} text
 * @param {number} durationSec actual audio duration when known, else estimated
 * @param {boolean} durationKnown
 * @returns {{t:number, v:string, d:number}[]}
 */
export function scheduleVisemes(text, durationSec, durationKnown = true) {
  const clean = normalizeForSpeech(text)
  const words = clean.split(/\s+/).filter(Boolean)
  if (!words.length) return []

  const per = words.map((w) => ({ w, syl: syllables(w), vs: wordToVisemes(w) }))
  const totalSyl = per.reduce((a, p) => a + p.syl, 0) || 1

  // Natural speech leaves gaps between words; synthesised speech often does not,
  // so we carve them out ourselves to avoid a permanently open mouth.
  const speakable = durationKnown ? durationSec * 0.9 : totalSyl * 0.22

  const out = []
  let cursor = durationKnown ? durationSec * 0.04 : 0
  for (const p of per) {
    const wordDur = (p.syl / totalSyl) * speakable
    const n = Math.max(1, p.vs.length)
    const step = wordDur / (n + 0.6)
    p.vs.forEach((v, i) => out.push({ t: cursor + i * step, v, d: step * 0.92 }))
    cursor += wordDur + (durationKnown ? 0 : 0.045)
  }
  return out
}

export function estimateDuration(text) {
  const words = String(text).split(/\s+/).filter(Boolean)
  const syl = words.reduce((a, w) => a + syllables(w), 0)
  return Math.max(0.45, syl * 0.225)
}
