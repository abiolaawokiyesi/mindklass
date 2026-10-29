/**
 * Rig channel — the single source of truth the renderer reads every frame.
 *
 * Speech, gesture and gaze all write here; renderers only read. That separation
 * is what lets us swap a canvas face for a photoreal GLB without touching the
 * teaching logic.
 */

export const clamp = (v, a = 0, b = 1) => Math.min(b, Math.max(a, v))
export const lerp = (a, b, t) => a + (b - a) * t

/** Frame-rate independent smoothing. */
export const approach = (cur, target, rate, dt) => cur + (target - cur) * (1 - Math.exp(-rate * dt))

export class Rig {
  constructor() {
    // Mouth (0..1 openness, -1..1 width)
    this.jawOpen = 0
    this.mouthWide = 0
    this.mouthSmile = 0.18
    this.lipRound = 0

    // Eyes
    this.blink = 0
    this.gazeX = 0
    this.gazeY = 0
    this.browRaise = 0.12
    this.browFurrow = 0

    // Head
    this.yaw = 0
    this.pitch = 0
    this.roll = 0

    // Body
    this.breath = 0
    this.energy = 0.5

    // Life
    this.time = 0
    this.speaking = false
    this.expression = 'neutral'

    // Internals
    this._blinkAt = 1.6 + Math.random() * 2.6
    this._blinkPhase = -1
    this._saccadeAt = 0.8
    this._saccadeTarget = { x: 0, y: 0 }
    this._targets = {
      jawOpen: 0, mouthWide: 0, smile: 0.18, lipRound: 0,
      gazeX: 0, gazeY: 0, browRaise: 0.12, browFurrow: 0,
      yaw: 0, pitch: 0, roll: 0, energy: 0.5
    }
    this._gesture = null
    this._gestureUntil = 0
  }

  /* ------------------------------------------------------------ expression */

  setExpression(name) {
    this.expression = name
    const t = this._targets
    switch (name) {
      case 'warm':       t.smile = 0.52; t.browRaise = 0.22; t.browFurrow = 0; break
      case 'curious':    t.smile = 0.22; t.browRaise = 0.55; t.browFurrow = 0; t.pitch = 0.06; break
      case 'delighted':  t.smile = 0.86; t.browRaise = 0.42; t.browFurrow = 0; break
      case 'thinking':   t.smile = 0.05; t.browRaise = 0.1; t.browFurrow = 0.45; break
      case 'focused':    t.smile = 0.16; t.browRaise = 0.14; t.browFurrow = 0.18; break
      case 'concerned':  t.smile = -0.1; t.browRaise = 0.3; t.browFurrow = 0.55; break
      default:           t.smile = 0.18; t.browRaise = 0.12; t.browFurrow = 0; break
    }
  }

  /** Gesture is a short-lived bias on top of the expression (a nod, a point). */
  gesture(name, strength = 0.7) {
    this._gesture = { name, strength }
    this._gestureUntil = this.time + 1.1
  }

  setSpeaking(on) {
    this.speaking = on
    if (on) this.setExpression(this.expression === 'neutral' ? 'focused' : this.expression)
  }

  /** Called by the lip-sync engine each frame with a viseme. */
  applyViseme(v, weight = 1) {
    const t = this._targets
    const map = {
      sil: [0, 0, 0],
      AA: [0.95, 0, 0],
      E:  [0.55, 0.75, 0],
      I:  [0.3, 0.95, 0],
      O:  [0.72, -0.55, 0.6],
      U:  [0.45, -0.9, 0.85],
      MBP:[0.05, 0, 0],
      FV: [0.16, 0.25, 0],
      L:  [0.4, 0.3, 0],
      WQ: [0.34, -0.8, 0.75],
      etc:[0.26, 0.1, 0],
      S:  [0.12, 0.6, 0]
    }
    const m = map[v] || map.etc
    t.jawOpen = m[0] * weight
    t.mouthWide = m[1] * weight
    t.lipRound = m[2] * weight
  }

  /** Amplitude-only fallback when no viseme timing is available. */
  applyLevel(level) {
    const l = clamp(level, 0, 1)
    this._targets.jawOpen = Math.min(0.85, l * 1.25)
    this._targets.mouthWide = 0.12
    this._targets.lipRound = 0
  }

  lookAt(x, y) {
    this._targets.gazeX = clamp(x, -1, 1)
    this._targets.gazeY = clamp(y, -1, 1)
  }

  /* -------------------------------------------------------------- per-frame */

  update(dt) {
    this.time += dt
    const t = this._targets

    // ---- blink: a short pulse, never a slow fade, or it reads as sleepiness
    if (this._blinkPhase < 0 && this.time > this._blinkAt) {
      this._blinkPhase = 0
      this._blinkAt = this.time + 2.4 + Math.random() * 4.2
    }
    if (this._blinkPhase >= 0) {
      this._blinkPhase += dt / 0.13
      const p = this._blinkPhase
      this.blink = p < 0.45 ? p / 0.45 : Math.max(0, 1 - (p - 0.45) / 0.55)
      if (p >= 1) { this._blinkPhase = -1; this.blink = 0 }
    }

    // ---- saccades: eyes move in small jumps, not smooth pans
    if (this.time > this._saccadeAt) {
      this._saccadeTarget = { x: (Math.random() - 0.5) * 0.5, y: (Math.random() - 0.5) * 0.28 }
      this._saccadeAt = this.time + 0.9 + Math.random() * 2.4
    }

    // ---- gestures
    if (this._gesture && this.time > this._gestureUntil) this._gesture = null
    let gYaw = 0, gPitch = 0, gRoll = 0, gBrow = 0
    if (this._gesture) {
      const s = this._gesture.strength
      const phase = (this._gestureUntil - this.time) / 1.1
      const env = Math.sin(Math.PI * clamp(phase)) * s
      switch (this._gesture.name) {
        case 'nod':     gPitch = env * 0.34; break
        case 'tilt':    gRoll = env * 0.2; gYaw = env * 0.1; break
        case 'point':   gYaw = env * 0.14; gPitch = -env * 0.1; gBrow = env * 0.2; break
        case 'shrug':   gRoll = env * 0.12; gBrow = env * 0.45; break
        case 'celebrate': gRoll = Math.sin(this.time * 9) * env * 0.1; gBrow = env * 0.5; break
        case 'count':   gPitch = Math.sin(this.time * 3.2) * env * 0.08; break
        default: break
      }
    }

    // Idle head life: always slightly moving, else the avatar reads as a photo.
    const idleYaw = Math.sin(this.time * 0.47) * 0.055 + Math.sin(this.time * 0.19) * 0.03
    const idlePitch = Math.sin(this.time * 0.61 + 1.2) * 0.032
    const idleRoll = Math.sin(this.time * 0.36 + 0.4) * 0.028

    // Speaking adds a little emphasis motion tied to the jaw.
    const speakBob = this.speaking ? Math.sin(this.time * 7.3) * 0.012 * this.jawOpen : 0

    const rate = 9
    this.jawOpen = approach(this.jawOpen, t.jawOpen, this.speaking ? 26 : 14, dt)
    this.mouthWide = approach(this.mouthWide, t.mouthWide + this._saccadeTarget.x * 0.05, rate, dt)
    this.mouthSmile = approach(this.mouthSmile, t.smile, 6, dt)
    this.lipRound = approach(this.lipRound, t.lipRound, 18, dt)

    this.gazeX = approach(this.gazeX, t.gazeX + this._saccadeTarget.x, 18, dt)
    this.gazeY = approach(this.gazeY, t.gazeY + this._saccadeTarget.y, 16, dt)
    this.browRaise = approach(this.browRaise, t.browRaise + gBrow, 7, dt)
    this.browFurrow = approach(this.browFurrow, t.browFurrow, 5, dt)

    this.yaw = approach(this.yaw, t.yaw + idleYaw + gYaw, 5, dt)
    this.pitch = approach(this.pitch, t.pitch + idlePitch + gPitch + speakBob, 5, dt)
    this.roll = approach(this.roll, t.roll + idleRoll + gRoll, 4, dt)

    this.energy = approach(this.energy, t.energy, 2, dt)
    this.breath = Math.sin(this.time * 1.35) * 0.5 + 0.5
  }
}
