/**
 * Listening.
 *
 * Uses the Web Speech API where it exists. Reality check on support: Chrome and
 * Edge have it, Safari has it behind a flag on some versions, and Firefox does
 * not. Coverage for African languages is uneven too, which is exactly why the
 * engine never depends on voice alone — typing is always available, and the
 * UI states plainly when a language cannot be heard on this device.
 */

const SR = window.SpeechRecognition || window.webkitSpeechRecognition

export const isSupported = () => Boolean(SR)

/** Languages we know recognition handles badly, so we can warn honestly. */
const WEAK = new Set(['yo', 'ig', 'ha', 'tw', 'wo', 'sn', 'rw', 'st', 'zu', 'xh', 'am'])

export class Mic {
  constructor({ lang = 'en', bcp47 = 'en-NG', onLevel } = {}) {
    this.lang = lang
    this.bcp47 = bcp47
    this.onLevel = onLevel
    this.rec = null
    this.active = false
    this._shouldRestart = false
    this._finalText = ''
    this._handlers = {}
    this._levelRaf = null
    this._stream = null
    this._ctx = null
  }

  setLang(lang, bcp47) {
    this.lang = lang
    this.bcp47 = bcp47
  }

  static weakFor(lang) {
    return WEAK.has(lang)
  }

  start(handlers = {}) {
    this._handlers = handlers
    if (!SR) {
      handlers.onError?.(
        'This browser cannot listen. Type your question instead, or open MindKlass in Chrome.'
      )
      return
    }
    if (this.active) return

    this._finalText = ''
    const rec = new SR()
    this.rec = rec
    rec.lang = this.bcp47
    rec.continuous = false
    rec.interimResults = true
    rec.maxAlternatives = 1

    let gotAnything = false

    rec.onresult = (e) => {
      let interim = ''
      for (let i = e.resultIndex; i < e.results.length; i++) {
        const res = e.results[i]
        if (res.isFinal) {
          this._finalText += res[0].transcript
          gotAnything = true
        } else {
          interim += res[0].transcript
        }
      }
      const shown = (this._finalText + ' ' + interim).trim()
      if (shown) handlers.onInterim?.(shown, { interim: !this._finalText })
      if (this._finalText) handlers.onFinal?.(this._finalText.trim())
    }

    rec.onerror = (e) => {
      this.active = false
      this._stopLevel()
      if (e.error === 'not-allowed' || e.error === 'service-not-allowed') {
        handlers.onError?.('Microphone permission was blocked. Allow it in your browser settings, or type instead.')
      } else if (e.error === 'no-speech') {
        handlers.onError?.('I did not catch that. Try again, a little closer to the mic.')
      } else if (e.error === 'language-not-supported' || e.error === 'network') {
        handlers.onError?.(
          `This device cannot listen in ${this.bcp47}. You can still type — Ada will answer in the same language.`
        )
      } else {
        handlers.onError?.('Listening stopped. You can type your question instead.')
      }
    }

    rec.onend = () => {
      this.active = false
      this._stopLevel()
      if (this._shouldRestart && !gotAnything) {
        this._shouldRestart = false
        try { rec.start() } catch { /* ignore */ }
        return
      }
      if (!gotAnything) {
        handlers.onError?.('I did not hear anything. Tap Talk and try again.')
      }
    }

    try {
      rec.start()
      this.active = true
      this._shouldRestart = true
      this._startLevel()
    } catch {
      handlers.onError?.('Could not start listening. Try again in a moment.')
    }
  }

  stop() {
    this._shouldRestart = false
    try { this.rec?.stop() } catch { /* ignore */ }
    this.active = false
    this._stopLevel()
  }

  /* ------------------------------------------------------------ level meter */

  /**
   * A live input level drives the avatar's "listening" posture. Separate from
   * SpeechRecognition because that API exposes no audio stream.
   */
  async _startLevel() {
    if (!this.onLevel) return
    try {
      const stream = await navigator.mediaDevices.getUserMedia({ audio: true })
      this._stream = stream
      const AC = window.AudioContext || window.webkitAudioContext
      this._ctx = new AC()
      const src = this._ctx.createMediaStreamSource(stream)
      const an = this._ctx.createAnalyser()
      an.fftSize = 512
      src.connect(an)
      const buf = new Uint8Array(an.frequencyBinCount)
      const loop = () => {
        an.getByteFrequencyData(buf)
        let sum = 0
        for (let i = 0; i < buf.length; i++) sum += buf[i]
        this.onLevel(Math.min(1, sum / buf.length / 70))
        this._levelRaf = requestAnimationFrame(loop)
      }
      loop()
    } catch {
      /* permission denied: recognition may still work via the browser service */
    }
  }

  _stopLevel() {
    if (this._levelRaf) cancelAnimationFrame(this._levelRaf)
    this._levelRaf = null
    this._stream?.getTracks().forEach((t) => t.stop())
    this._stream = null
    try { this._ctx?.close() } catch { /* ignore */ }
    this._ctx = null
  }
}
