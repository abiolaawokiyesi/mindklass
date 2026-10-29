// Gesture + expression track helpers shared by the server (planner) and browser.
// Keeping this dependency-free means both sides agree on what a turn "looks like".

import type { Strategy } from './pedagogy'

export type Viseme =
  | 'sil' | 'AA' | 'E' | 'I' | 'O' | 'U'
  | 'MBP' | 'FV' | 'L' | 'WQ' | 'etc' | 'S'

export type Expression = 'neutral' | 'warm' | 'curious' | 'delighted' | 'thinking' | 'focused' | 'concerned'

export type Gesture = 'idle' | 'point' | 'open' | 'count' | 'shrug' | 'thumbsup'

export type AvatarCue = {
  expression: Expression
  gesture: Gesture
  /** 0..1 – how animated. Lower for solemn corrections, higher for celebration. */
  energy: number
}

const CUES: Record<Strategy, AvatarCue> = {
  explain: { expression: 'focused', gesture: 'count', energy: 0.55 },
  simplify: { expression: 'warm', gesture: 'open', energy: 0.4 },
  socratic: { expression: 'curious', gesture: 'point', energy: 0.5 },
  worked_example: { expression: 'focused', gesture: 'count', energy: 0.6 },
  analogy: { expression: 'curious', gesture: 'open', energy: 0.6 },
  correct: { expression: 'warm', gesture: 'thumbsup', energy: 0.45 },
  quiz: { expression: 'curious', gesture: 'point', energy: 0.5 },
  encourage: { expression: 'delighted', gesture: 'thumbsup', energy: 0.7 }
}

export const cueFor = (strategy: Strategy): AvatarCue => CUES[strategy] ?? CUES.explain

export const EXPRESSION_LABEL: Record<Expression, string> = {
  neutral: 'Attentive',
  warm: 'Encouraging',
  curious: 'Curious',
  delighted: 'Pleased',
  thinking: 'Thinking',
  focused: 'Explaining',
  concerned: 'Careful'
}

/**
 * English grapheme-to-viseme approximation.
 *
 * Real lip-sync uses an acoustic model. In a Worker-hosted PWA we cannot ship
 * one cheaply, so we combine two signals: this text-side prior (which phoneme
 * the mouth is probably on) and a live energy/spectrum reading from the actual
 * audio (whether the mouth should be open at all, and how wide). The result is
 * markedly better than amplitude-only puppetry on synthesised speech, which
 * tends to have flat loudness and needs the text prior to look right.
 */
const RULES: [RegExp, Viseme][] = [
  [/^(sh|ch|j|zh)/, 'S'],
  [/^(th)/, 'etc'],
  [/^(ph|f|v)/, 'FV'],
  [/^(m|b|p)/, 'MBP'],
  [/^(w|qu|wh)/, 'WQ'],
  [/^(r|er|ir|ur)/, 'WQ'],
  [/^(l)/, 'L'],
  [/^(oo|ou|u|ew)/, 'U'],
  [/^(oa|o|aw|au|ow)/, 'O'],
  [/^(ee|ea|ie|y|i|ei)/, 'I'],
  [/^(a|e)/, 'E'],
  [/^(s|z|c|ts)/, 'S'],
  [/^(n|d|t|k|g|h)/, 'etc']
]

export function wordToVisemes(word: string): Viseme[] {
  const w = word.toLowerCase().replace(/[^a-z']/g, '')
  if (!w) return []
  const out: Viseme[] = []
  let i = 0
  while (i < w.length) {
    const rest = w.slice(i)
    let matched = false
    for (const [re, v] of RULES) {
      const m = re.exec(rest)
      if (m) {
        out.push(v)
        i += m[1].length
        matched = true
        break
      }
    }
    if (!matched) i += 1
  }
  return out.length ? out : ['etc']
}
