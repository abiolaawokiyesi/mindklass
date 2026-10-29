/**
 * The voice.
 *
 * Three-tier chain, chosen per sentence at runtime:
 *   1. Neural TTS via /api/tts  — best quality, real African-language voices,
 *      streamed through WebAudio so we can drive lip-sync from the analyser.
 *   2. Pre-recorded narration MP3 (existing MindKlass `tools/generate-voice.py`
 *      output) when a lesson sentence has an asset — zero latency, offline-safe.
 *   3. Browser speechSynthesis — always available, no key, but no analyser, so
 *      lip-sync falls back to the text-prior schedule with synthetic envelope.
 *
 * Interruption is a first-class feature: a learner should be able to talk over
 * the avatar and have it stop mid-word, the way a person would.
 */

import { scheduleVisemes, estimateDuration, normalizeForSpeech } from './visemes.js'

export class Speaker {
  constructor({ rig, onCaption, onWord, onState, onViseme } = {}) {
    this.rig = rig
    this.onCaption = onCaption || (() => {})
    this.onWord = onWord || (() => {})
    this.onState = onState || (() => {})
    this.onViseme = onViseme || (() => {})

    this.ctx = null
    this.analyser = null
    this.freq = null
    this.gain = null
    this.current = null
    this.queue = []
    this.playing = false
    this.muted = false
    this.rate = 1
    this.lang = 'en'
    this.bcp47 = 'en-NG'
    this._abort = null
    this._raf = null
    this._ttsBroken = false // once the endpoint 501s, stop asking for this session
    this._unlocked = false
  }

  setLang(code, bcp47) {
    this.lang = code
    this.bcp47 = bcp47 || code
  }

  /** iOS requires a user gesture before audio can play. Call from a tap. */
  async unlock() {
    if (this._unlocked) return
    try {
      const AC = window.AudioContext || window.webkitAudioContext
      if (!AC) return
      this.ctx = this.ctx || new AC()
      if (this.ctx.state === 'suspended') await this.ctx.resume()
      this.analyser = this.ctx.createAnalyser()
      this.analyser.fftSize = 1024
      this.analyser.smoothingTimeConstant = 0.55
      this.freq = new Uint8Array(this.analyser.frequencyBinCount)
      this.gain = this.ctx.createGain()
      this.gain.gain.value = this.muted ? 0 : 1
      this.analyser.connect(this.gain)
      this.gain.connect(this.ctx.destination)
      this._unlocked = true
    } catch {
      this._unlocked = false
    }
  }

  setMuted(m) {
    this.muted = m
    if (this.gain) this.gain.gain.value = m ? 0 : 1
    if (m) this.stop()
  }

  /* ------------------------------------------------------------------ speak */

  /**
   * @param {string} text
   * @param {{audioUrl?: string, onEnd?: Function, allowNeural?: boolean}} opts
   */
  say(text, opts = {}) {
    const clean = normalizeForSpeech(text).trim()
    if (!clean) { opts.onEnd?.(); return }
    this.queue.push({ text: clean, ...opts })
    if (!this.playing) this._next()
  }

  /** Speak several sentences back-to-back without gaps in the mouth animation. */
  sayAll(sentences, opts = {}) {
    sentences.forEach((s, i) => this.say(s, { ...opts, onEnd: i === sentences.length - 1 ? opts.onEnd : undefined }))
  }

  stop() {
    this.queue.length = 0
    this._abort?.()
    this._abort = null
    if (this.current?.source) {
      try { this.current.source.stop() } catch { /* already ended */ }
    }
    if (this.current?.audio) {
      this.current.audio.pause()
      this.current.audio.src = ''
    }
    if ('speechSynthesis' in window) {
      try { window.speechSynthesis.cancel() } catch { /* not supported */ }
    }
    this.current = null
    this.playing = false
    this._stopRaf()
    this.rig?.setSpeaking(false)
    this.onState?.('idle')
  }

  get isSpeaking() { return this.playing }

  /* -------------------------------------------------------------- internals */

  async _next() {
    const item = this.queue.shift()
    if (!item) {
      this.playing = false
      this.rig?.setSpeaking(false)
      this.onState?.('idle')
      return
    }
    this.playing = true
    this.rig?.setSpeaking(true)
    this.onState?.('speaking')

    try {
      // 1 — explicit audio asset (lesson narration)
      if (item.audioUrl) {
        const ok = await this._playUrl(item.audioUrl, item)
        if (ok) return
      }
      // 2 — neural TTS through the server proxy
      if (item.allowNeural !== false && !this._ttsBroken && this.ctx) {
        const ok = await this._playNeural(item)
        if (ok) return
      }
      // 3 — browser voice, last resort but always present
      await this._playBrowser(item)
    } catch {
      this._finishItem(item)
    }
  }

  _finishItem(item) {
    item.onEnd?.()
    this.current = null
    this._stopRaf()
    this._next()
  }

  async _playNeural(item) {
    const ctrl = new AbortController()
    this._abort = ctrl
    try {
      const res = await fetch('/api/tts', {
        method: 'POST',
        headers: { 'content-type': 'application/json' },
        body: JSON.stringify({ text: item.text, lang: this.lang }),
        signal: ctrl.signal
      })
      if (res.status === 501) { this._ttsBroken = true; return false }
      if (!res.ok) return false
      const buf = await res.arrayBuffer()
      if (!buf.byteLength) return false
      return await this._playBuffer(buf, item)
    } catch {
      return false
    } finally {
      this._abort = null
    }
  }

  async _playBuffer(buf, item) {
    await this.unlock()
    if (!this.ctx) return false
    let audioBuf
    try {
      audioBuf = await this.ctx.decodeAudioData(buf.slice(0))
    } catch {
      return false
    }
    const source = this.ctx.createBufferSource()
    source.buffer = audioBuf
    source.connect(this.analyser)
    const dur = audioBuf.duration
    this.current = { source, duration: dur, startedAt: this.ctx.currentTime }
    this._schedule = scheduleVisemes(item.text, dur, true)
    this._startRaf(item, dur, true)
    source.onended = () => this._finishItem(item)
    source.start()
    return true
  }

  async _playUrl(url, item) {
    try {
      await this.unlock()
      const audio = new Audio()
      audio.crossOrigin = 'anonymous'
      audio.src = url
      audio.playbackRate = this.rate
      if (!this.ctx) {
        // No WebAudio: still play, lip-sync from estimate.
        audio.volume = this.muted ? 0 : 1
        this.current = { audio }
        await audio.play()
        const dur = Number.isFinite(audio.duration) && audio.duration > 0 ? audio.duration : estimateDuration(item.text)
        this._schedule = scheduleVisemes(item.text, dur, true)
        this._startRaf(item, dur, true)
        audio.onended = () => this._finishItem(item)
        return true
      }
      // Route through WebAudio for the analyser.
      const res = await fetch(url)
      if (!res.ok) return false
      return await this._playBuffer(await res.arrayBuffer(), item)
    } catch {
      return false
    }
  }

  _playBrowser(item) {
    return new Promise((resolve) => {
      if (!('speechSynthesis' in window)) { resolve(false); return }
      const synth = window.speechSynthesis
      const u = new SpeechSynthesisUtterance(item.text)
      u.lang = this.bcp47
      u.rate = Math.min(1.35, this.rate * 0.98)
      u.pitch = 1.02
      const voice = this._pickVoice()
      if (voice) u.voice = voice

      const est = estimateDuration(item.text) / this.rate
      this._schedule = scheduleVisemes(item.text, est, false)
      this._startRaf(item, est, false, true)

      let settled = false
      const done = () => {
        if (settled) return
        settled = true
        resolve(true)
        this._finishItem(item)
      }
      u.onend = done
      u.onerror = done
      // Safety net: some engines never fire onend.
      setTimeout(done, (est + 2.5) * 1000)
      synth.speak(u)
      if (this.muted) {
        // Some engines ignore volume; cancel and let the caption carry the text.
        setTimeout(() => { if (this.current === null) synth.cancel() }, 60)
      }
    })
  }

  _pickVoice() {
    const synth = window.speechSynthesis
    const voices = synth.getVoices?.() || []
    if (!voices.length) return null
    const want = this.bcp47.toLowerCase()
    const exact = voices.find((v) => v.lang?.toLowerCase() === want)
    if (exact) return exact
    const prefix = want.split('-')[0]
    return voices.find((v) => v.lang?.toLowerCase().startsWith(prefix)) || null
  }

  /* ------------------------------------------------------------- lip-sync */

  _startRaf(item, duration, durationKnown, synthetic = false) {
    this._stopRaf()
    const base = this.ctx ? this.ctx.currentTime : 0
    const started = performance.now() / 1000
    let lastIdx = -1

    const loop = () => {
      const t = this.ctx ? this.ctx.currentTime - base : performance.now() / 1000 - started
      const el = Math.max(0, t)

      // ---- energy from the real signal
      let level = 0
      let bright = 0
      if (this.analyser && this.freq) {
        this.analyser.getByteFrequencyData(this.freq)
        let sum = 0
        let hi = 0
        for (let i = 0; i < this.freq.length; i++) {
          sum += this.freq[i]
          if (i < this.freq.length * 0.35) hi += this.freq[i]
        }
        level = Math.min(1, (sum / this.freq.length) / 78)
        bright = Math.min(1, (hi / (this.freq.length * 0.35)) / 95)
      } else if (synthetic) {
        // Browser TTS gives us no audio graph: synthesise a plausible envelope
        // from the schedule so the mouth still moves per phoneme.
        level = 0.55 + Math.sin(el * 11) * 0.12
      }

      // ---- text prior picks the shape
      const sched = this._schedule || []
      let v = 'sil'
      let weight = 0
      for (let i = 0; i < sched.length; i++) {
        const s = sched[i]
        if (el >= s.t && el < s.t + s.d + 0.06) { v = s.v; weight = 1; break }
        if (el < s.t) break
      }
      if (v === 'sil' && sched.length && el > sched[sched.length - 1].t) v = 'sil'

      // Silence detection: only open the mouth when there is actual signal.
      const gated = level < 0.075 ? 'sil' : v
      this.rig?.applyViseme(gated, Math.min(1, 0.45 + level * 0.9))

      // Brightness nudges the mouth wider for fricatives/vowels (i/e vs o/u).
      if (this.rig && gated !== 'sil') {
        this.rig._targets.mouthWide += (bright - 0.5) * 0.12
      }

      // ---- word-level caption highlight (screen readers + reading practice)
      if (item.onEnd || this.onWord) {
        const idx = sched.reduce((acc, s, i) => (el >= s.t ? i : acc), -1)
        if (idx !== lastIdx) {
          lastIdx = idx
          const words = item.text.split(/\s+/)
          const frac = sched.length ? (idx + 1) / sched.length : 0
          this.onWord(words[Math.min(words.length - 1, Math.floor(frac * words.length))], item.text)
        }
      }

      // ---- occasionally glance while speaking, like a person thinking
      if (this.rig) {
        const glance = Math.sin(el * 0.9) * 0.22
        this.rig.lookAt(glance, Math.sin(el * 0.6) * 0.12)
      }

      if (el > duration + 1.6) { this._stopRaf(); return }
      this._raf = requestAnimationFrame(loop)
    }
    this._raf = requestAnimationFrame(loop)
  }

  _stopRaf() {
    if (this._raf) cancelAnimationFrame(this._raf)
    this._raf = null
  }
}
