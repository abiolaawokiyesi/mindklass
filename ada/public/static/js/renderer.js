/**
 * Studio portrait renderer (procedural).
 *
 * Geometry model — everything is expressed as a multiple of `R`, the head's
 * half-height, so the bust scales cleanly from a 360px phone to a 1440px stage.
 *
 *         -1.18R  crown of hair
 *         -1.05R  top of skull
 *         -0.72R  hairline
 *         -0.22R  eye line
 *         +0.34R  nose base
 *         +0.52R  mouth
 *         +1.00R  chin
 *         +1.15R  base of neck
 *         → frame bottom = shoulders
 *
 * Draw order matters more than any single detail: hair mass behind → torso →
 * neck → head → hair front. Getting that order wrong is what makes a drawn face
 * look like a mask pasted onto a body.
 */

const TAU = Math.PI * 2
const mix = (a, b, t) => a + (b - a) * t

function rnd(i) {
  const x = Math.sin(i * 12.9898) * 43758.5453
  return x - Math.floor(x)
}

function parseHex(h) {
  const s = String(h).replace('#', '')
  const v = s.length === 3 ? s.split('').map((c) => c + c).join('') : s
  return [parseInt(v.slice(0, 2), 16), parseInt(v.slice(2, 4), 16), parseInt(v.slice(4, 6), 16)]
}

function mixHex(a, b, t) {
  const pa = parseHex(a)
  const pb = parseHex(b)
  return `rgb(${Math.round(mix(pa[0], pb[0], t))}, ${Math.round(mix(pa[1], pb[1], t))}, ${Math.round(mix(pa[2], pb[2], t))})`
}

export class CanvasPortrait {
  constructor(canvas, opts = {}) {
    this.canvas = canvas
    this.ctx = canvas.getContext('2d', { alpha: true, desynchronized: true })
    this.opts = {
      skin: { highlight: '#d9a67f', base: '#a86b46', shade: '#77452b', deep: '#4d2a16' },
      hair: { base: '#171014', light: '#3c2a2e', sheen: 'rgba(255, 216, 190, 0.13)' },
      cloth: '#1b2740',
      eye: '#4a2c14',
      lip: { base: '#8d4a44', dark: '#5e2a28', light: '#a76a62' },
      ...(opts || {})
    }
    this.dpr = 1
    this.w = 0
    this.h = 0
    this._grainTex = null
    this._t = 0
    this.resize()
  }

  resize() {
    const rect = this.canvas.getBoundingClientRect()
    const dpr = Math.min(window.devicePixelRatio || 1, 2)
    this.dpr = dpr
    this.w = Math.max(1, Math.round(rect.width))
    this.h = Math.max(1, Math.round(rect.height))
    this.canvas.width = Math.round(this.w * dpr)
    this.canvas.height = Math.round(this.h * dpr)
    this.ctx.setTransform(dpr, 0, 0, dpr, 0, 0)
    this._grainTex = null
  }

  /* ---------------------------------------------------------------- layout */

  get geometry() {
    const { w, h } = this
    const R = Math.min(w / 3.15, h / 3.85)
    return { w, h, R, cx: w / 2, cy: h * 0.455 }
  }

  /* ----------------------------------------------------------------- frame */

  draw(rig, dt) {
    const ctx = this.ctx
    if (!this.w || !this.h) return
    this._t += dt || 0.016

    const { R, cx, cy, w, h } = this.geometry
    ctx.clearRect(0, 0, w, h)

    this._backdrop(w, h)

    // Head transform: pitch moves the whole bust, yaw shears the features.
    ctx.save()
    ctx.translate(cx, cy + rig.pitch * R * 0.30)
    ctx.rotate(rig.roll * 0.42)

    this._hairBack(R, rig)
    this._torso(R, rig, h, cy)
    this._neck(R, rig)

    // Face group: the 2.5D parallax that reads as a turning head.
    const fx = Math.sin(rig.yaw) * R * 0.16
    const squash = 1 - Math.abs(rig.yaw) * 0.05
    ctx.save()
    ctx.scale(squash, 1)
    ctx.translate(fx * 0.35, 0)

    this._ears(R, rig.yaw)
    this._head(R, rig, fx)

    ctx.restore()
    this._hairFront(R, rig)
    ctx.restore()

    this._lighting(w, h, R, cx, cy, rig)
    this._drawGrain(w, h)
  }

  _backdrop(w, h) {
    const ctx = this.ctx
    const g = ctx.createRadialGradient(w * 0.5, h * 0.28, 10, w * 0.5, h * 0.4, Math.max(w, h) * 0.8)
    g.addColorStop(0, 'rgba(58, 84, 142, 0.40)')
    g.addColorStop(0.5, 'rgba(21, 32, 60, 0.26)')
    g.addColorStop(1, 'rgba(6, 9, 16, 0)')
    ctx.fillStyle = g
    ctx.fillRect(0, 0, w, h)

    const spots = [
      [0.20, 0.22, 0.17, 'rgba(109,139,255,0.10)'],
      [0.82, 0.16, 0.14, 'rgba(67,224,200,0.07)']
    ]
    for (const [sx, sy, sr, col] of spots) {
      const rr = Math.max(w, h) * sr
      const rg = ctx.createRadialGradient(w * sx, h * sy, 0, w * sx, h * sy, rr)
      rg.addColorStop(0, col)
      rg.addColorStop(1, 'rgba(0,0,0,0)')
      ctx.fillStyle = rg
      ctx.fillRect(0, 0, w, h)
    }
  }

  /* -------------------------------------------------------------- silhouette */

  _headPath(R) {
    const p = new Path2D()
    p.moveTo(0, -R * 1.05)
    p.bezierCurveTo(R * 0.56, -R * 1.05, R * 0.90, -R * 0.66, R * 0.92, -R * 0.16)
    // cheekbone then jaw
    p.bezierCurveTo(R * 0.94, R * 0.22, R * 0.74, R * 0.66, R * 0.40, R * 0.88)
    p.bezierCurveTo(R * 0.24, R * 0.99, -R * 0.24, R * 0.99, -R * 0.40, R * 0.88)
    p.bezierCurveTo(-R * 0.74, R * 0.66, -R * 0.94, R * 0.22, -R * 0.92, -R * 0.16)
    p.bezierCurveTo(-R * 0.90, -R * 0.66, -R * 0.56, -R * 1.05, 0, -R * 1.05)
    p.closePath()
    return p
  }

  /**
   * Hair mass behind the head. Deliberately a single closed silhouette with NO
   * inner cutout: an even-odd "hairline" had two edges doubling back through each
   * other near the temples, and the self-intersection punched a visible hole in
   * the fill. The hairline is instead created by the face path drawn on top, and
   * the fringe in `_hairFront` is laid over the forehead.
   */
  _hairSilhouette(R) {
    const p = new Path2D()
    p.moveTo(-R * 0.94, R * 0.10)
    p.bezierCurveTo(-R * 1.14, -R * 0.30, -R * 0.96, -R * 0.98, -R * 0.36, -R * 1.15)
    p.bezierCurveTo(-R * 0.12, -R * 1.22, R * 0.12, -R * 1.22, R * 0.36, -R * 1.15)
    p.bezierCurveTo(R * 0.96, -R * 0.98, R * 1.14, -R * 0.30, R * 0.94, R * 0.10)
    // Tuck the mass behind the jaw instead of letting it taper to a point below
    // the ear — a closed curve that ends in a sharp lobe reads as a spike.
    p.bezierCurveTo(R * 0.90, -R * 0.16, R * 0.86, -R * 0.36, R * 0.80, -R * 0.46)
    p.bezierCurveTo(R * 0.74, -R * 0.72, R * 0.44, -R * 0.86, 0, -R * 0.86)
    p.bezierCurveTo(-R * 0.44, -R * 0.86, -R * 0.74, -R * 0.72, -R * 0.80, -R * 0.46)
    p.bezierCurveTo(-R * 0.86, -R * 0.36, -R * 0.90, -R * 0.16, -R * 0.94, R * 0.10)
    p.closePath()
    return p
  }

  _hairBack(R, rig) {
    const ctx = this.ctx
    const h = this.opts.hair
    const path = this._hairSilhouette(R)

    const g = ctx.createLinearGradient(0, -R * 1.2, 0, R * 0.5)
    g.addColorStop(0, h.light)
    g.addColorStop(0.42, h.base)
    g.addColorStop(1, '#0b070a')
    ctx.fillStyle = g
    ctx.fill(path)

    // Strand texture: fine arcs following the crown. Clipped to the mass so no
    // stray geometry can escape the silhouette.
    ctx.save()
    ctx.clip(path)
    for (let i = 0; i < 30; i++) {
      const a = -Math.PI * 0.88 + (i / 30) * Math.PI * 1.76
      const r1 = R * (0.70 + rnd(i) * 0.30)
      ctx.strokeStyle = `rgba(255, 214, 192, ${0.025 + rnd(i + 7) * 0.045})`
      ctx.lineWidth = R * (0.005 + rnd(i + 3) * 0.007)
      ctx.beginPath()
      ctx.moveTo(Math.cos(a) * r1 * 0.70, -R * 0.16 + Math.sin(a) * r1)
      ctx.quadraticCurveTo(
        Math.cos(a) * r1 * 1.06,
        -R * 0.16 + Math.sin(a) * r1 * 1.02,
        Math.cos(a) * r1 * 1.30,
        -R * 0.16 + Math.sin(a) * r1 * 1.16
      )
      ctx.stroke()
    }
    ctx.restore()
  }

  /**
   * The fringe, laid over the forehead. One closed, non-self-intersecting shape:
   * outer crown → right temple → swept hairline → left temple → back to the crown.
   * The hairline is asymmetric (side-swept) because a perfectly symmetric arc
   * reads as a helmet.
   */
  _hairFront(R, rig) {
    const ctx = this.ctx
    const h = this.opts.hair
    const shift = Math.sin(rig.yaw) * R * 0.09

    ctx.save()
    ctx.translate(shift, 0)

    const fringe = new Path2D()
    fringe.moveTo(-R * 1.06, R * 0.30)
    fringe.bezierCurveTo(-R * 1.16, -R * 0.34, -R * 0.98, -R * 1.00, -R * 0.36, -R * 1.17)
    fringe.bezierCurveTo(-R * 0.12, -R * 1.24, R * 0.12, -R * 1.24, R * 0.36, -R * 1.17)
    fringe.bezierCurveTo(R * 0.98, -R * 1.00, R * 1.16, -R * 0.34, R * 1.06, R * 0.30)
    // sweep back across the forehead (right temple → left temple)
    fringe.bezierCurveTo(R * 0.98, R * 0.02, R * 0.94, -R * 0.34, R * 0.86, -R * 0.52)
    fringe.bezierCurveTo(R * 0.70, -R * 0.70, R * 0.34, -R * 0.76, -R * 0.06, -R * 0.72)
    fringe.bezierCurveTo(-R * 0.40, -R * 0.68, -R * 0.72, -R * 0.58, -R * 0.88, -R * 0.40)
    fringe.bezierCurveTo(-R * 0.96, -R * 0.22, -R * 1.02, -R * 0.04, -R * 1.06, R * 0.30)
    fringe.closePath()

    // The fringe must not read as a separate cap sitting on the hair mass, so its
    // gradient follows the same stops as `_hairBack` and only edges lighter at the
    // very top, where the key light actually falls.
    const g = ctx.createLinearGradient(-R * 0.2, -R * 1.24, -R * 0.1, -R * 0.34)
    g.addColorStop(0, mixHex(h.light, '#000000', 0.10))
    g.addColorStop(0.30, h.base)
    g.addColorStop(0.75, h.base)
    g.addColorStop(1, 'rgba(13, 9, 11, 0.55)')
    ctx.fillStyle = g
    ctx.fill(fringe)

    ctx.save()
    ctx.clip(fringe)

    // A narrow gloss just under the crown. Kept small and faint: a broad bright
    // ellipse over dark hair reads as a bald patch, not as shine.
    const sheen = ctx.createLinearGradient(-R * 0.42, -R * 1.16, -R * 0.06, -R * 0.86)
    sheen.addColorStop(0, 'rgba(255, 226, 208, 0)')
    sheen.addColorStop(0.5, 'rgba(255, 226, 208, 0.055)')
    sheen.addColorStop(1, 'rgba(255, 226, 208, 0)')
    ctx.fillStyle = sheen
    ctx.beginPath()
    ctx.ellipse(-R * 0.14, -R * 1.02, R * 0.38, R * 0.075, -0.14, 0, TAU)
    ctx.fill()

    // Individual strands sweeping from the parting towards the left temple.
    for (let i = 0; i < 16; i++) {
      const t = i / 16
      ctx.strokeStyle = `rgba(255, 228, 210, ${0.030 + rnd(i + 5) * 0.035})`
      ctx.lineWidth = R * (0.0035 + rnd(i + 9) * 0.004)
      ctx.beginPath()
      ctx.moveTo(R * (0.30 - t * 0.10), -R * (0.80 + rnd(i) * 0.10))
      ctx.bezierCurveTo(
        R * (0.10 - t * 0.40), -R * (0.92 + t * 0.06),
        -R * (0.30 + t * 0.40), -R * (0.80 - t * 0.10),
        -R * (0.55 + t * 0.34), -R * (0.56 - t * 0.22)
      )
      ctx.stroke()
    }
    ctx.restore()
    ctx.restore()
  }

  /* ------------------------------------------------------------------ body */

  _torso(R, rig, h, cy) {
    const ctx = this.ctx
    // Anchored to the frame bottom so the bust always fills the stage, whatever
    // its aspect ratio.
    const bottom = (h - cy) / 1 + R * 0.2
    const topY = R * 1.06
    const breath = rig.breath * R * 0.012

    ctx.save()
    const shoulders = new Path2D()
    shoulders.moveTo(-R * 0.62, topY + breath)
    shoulders.bezierCurveTo(-R * 1.20, topY + R * 0.16, -R * 1.80, topY + R * 0.60, -R * 2.30, bottom)
    shoulders.lineTo(R * 2.30, bottom)
    shoulders.bezierCurveTo(R * 1.80, topY + R * 0.60, R * 1.20, topY + R * 0.16, R * 0.62, topY + breath)
    shoulders.bezierCurveTo(R * 0.42, topY + R * 0.30, -R * 0.42, topY + R * 0.30, -R * 0.62, topY + breath)
    shoulders.closePath()

    const cg = ctx.createLinearGradient(-R * 1.6, topY, R * 1.6, bottom)
    cg.addColorStop(0, '#0a1120')
    cg.addColorStop(0.32, this.opts.cloth)
    cg.addColorStop(0.58, mixHex(this.opts.cloth, '#ffffff', 0.12))
    cg.addColorStop(1, '#080e19')
    ctx.fillStyle = cg
    ctx.fill(shoulders)

    // Collar: the V opening is what tells the eye "this is clothing, not a wall".
    ctx.save()
    ctx.clip(shoulders)
    const collar = new Path2D()
    collar.moveTo(-R * 0.60, topY - R * 0.02)
    collar.quadraticCurveTo(-R * 0.30, topY + R * 0.46, 0, topY + R * 0.50)
    collar.quadraticCurveTo(R * 0.30, topY + R * 0.46, R * 0.60, topY - R * 0.02)
    collar.lineTo(R * 0.30, topY - R * 0.06)
    collar.quadraticCurveTo(0, topY + R * 0.22, -R * 0.30, topY - R * 0.06)
    collar.closePath()
    ctx.fillStyle = 'rgba(3, 6, 11, 0.78)'
    ctx.fill(collar)

    // Fold highlights either side of the collar.
    for (const side of [-1, 1]) {
      const fg = ctx.createLinearGradient(side * R * 0.55, topY, side * R * 1.5, bottom)
      fg.addColorStop(0, 'rgba(255,255,255,0.05)')
      fg.addColorStop(1, 'rgba(255,255,255,0)')
      ctx.fillStyle = fg
      ctx.beginPath()
      ctx.moveTo(side * R * 0.62, topY)
      ctx.lineTo(side * R * 1.34, bottom)
      ctx.lineTo(side * R * 0.96, bottom)
      ctx.closePath()
      ctx.fill()
    }
    ctx.restore()
    ctx.restore()
  }

  _neck(R, rig) {
    const ctx = this.ctx
    const ctx2 = ctx
    const neck = new Path2D()
    // Starts inside the head so there is never a gap at the jaw.
    neck.moveTo(-R * 0.36, R * 0.42)
    neck.bezierCurveTo(-R * 0.34, R * 0.92, -R * 0.40, R * 1.06, -R * 0.52, R * 1.14)
    neck.lineTo(R * 0.52, R * 1.14)
    neck.bezierCurveTo(R * 0.40, R * 1.06, R * 0.34, R * 0.92, R * 0.36, R * 0.42)
    neck.closePath()

    const g = ctx2.createLinearGradient(-R * 0.4, R * 0.5, R * 0.4, R * 1.1)
    g.addColorStop(0, this.opts.skin.shade)
    g.addColorStop(0.42, this.opts.skin.base)
    g.addColorStop(1, this.opts.skin.deep)
    ctx2.fillStyle = g
    ctx2.fill(neck)

    // Cast shadow from the jaw — the cue that sells "head attached to neck".
    ctx2.save()
    ctx2.clip(neck)
    const sg = ctx2.createLinearGradient(0, R * 0.42, 0, R * 1.05)
    sg.addColorStop(0, 'rgba(28, 12, 6, 0.78)')
    sg.addColorStop(0.42, 'rgba(28, 12, 6, 0.34)')
    sg.addColorStop(1, 'rgba(28, 12, 6, 0.06)')
    ctx2.fillStyle = sg
    ctx2.fillRect(-R * 0.6, R * 0.4, R * 1.2, R * 0.8)
    ctx2.restore()
  }

  _ears(R, yaw) {
    const ctx = this.ctx
    for (const side of [-1, 1]) {
      // An ear on the far side of a turned head is mostly hidden.
      const vis = 1 - Math.max(0, side * Math.sin(yaw)) * 0.7
      if (vis < 0.2) continue
      ctx.save()
      ctx.translate(side * R * 0.87, R * 0.03)
      ctx.scale(vis, 1)
      const g = ctx.createRadialGradient(0, 0, R * 0.02, 0, 0, R * 0.22)
      g.addColorStop(0, this.opts.skin.base)
      g.addColorStop(1, this.opts.skin.shade)
      ctx.beginPath()
      ctx.ellipse(0, 0, R * 0.12, R * 0.20, side * 0.10, 0, TAU)
      ctx.fillStyle = g
      ctx.fill()
      ctx.strokeStyle = 'rgba(58, 26, 12, 0.34)'
      ctx.lineWidth = R * 0.010
      ctx.beginPath()
      ctx.ellipse(side * R * 0.012, R * 0.012, R * 0.058, R * 0.115, 0, 0, TAU)
      ctx.stroke()
      ctx.restore()
    }
  }

  /* ------------------------------------------------------------------ head */

  _head(R, rig, fx) {
    const ctx = this.ctx
    const face = this._headPath(R)

    // Base skin with a directional falloff.
    const g = ctx.createRadialGradient(-R * 0.28, -R * 0.34, R * 0.10, R * 0.06, -R * 0.02, R * 1.22)
    g.addColorStop(0, this.opts.skin.highlight)
    g.addColorStop(0.34, this.opts.skin.base)
    g.addColorStop(0.78, this.opts.skin.shade)
    g.addColorStop(1, this.opts.skin.deep)
    ctx.fillStyle = g
    ctx.fill(face)

    ctx.save()
    ctx.clip(face)

    this._formShading(R, rig)
    this._brows(R, rig, fx)
    this._eyes(R, rig, fx)
    this._nose(R, rig, fx)
    this._mouth(R, rig, fx)

    ctx.restore()

    // Jaw bounce light: a bright line under the chin separates head from neck.
    ctx.save()
    ctx.clip(face)
    ctx.strokeStyle = 'rgba(255, 214, 180, 0.16)'
    ctx.lineWidth = R * 0.03
    ctx.beginPath()
    ctx.moveTo(-R * 0.34, R * 0.90)
    ctx.quadraticCurveTo(0, R * 1.02, R * 0.34, R * 0.90)
    ctx.stroke()
    ctx.restore()

    // Terminator: one soft edge instead of an outline.
    ctx.strokeStyle = 'rgba(42, 18, 8, 0.14)'
    ctx.lineWidth = R * 0.018
    ctx.stroke(face)
  }

  _formShading(R, rig) {
    const ctx = this.ctx
    const yaw = rig.yaw
    const smile = rig.mouthSmile

    // Key light pool on the forehead / cheek.
    const key = ctx.createRadialGradient(-R * 0.30, -R * 0.55, R * 0.05, -R * 0.20, -R * 0.30, R * 0.95)
    key.addColorStop(0, 'rgba(255, 230, 205, 0.30)')
    key.addColorStop(1, 'rgba(255, 230, 205, 0)')
    ctx.fillStyle = key
    ctx.fillRect(-R, -R * 1.1, R * 2, R * 2.2)

    // Cheek suffusion — blood under the skin. Small, but it kills the plastic look.
    const cheek = ctx.createRadialGradient(0, R * 0.20, R * 0.02, 0, R * 0.20, R * 0.66)
    cheek.addColorStop(0, `rgba(190, 84, 60, ${0.11 + Math.max(0, smile) * 0.07})`)
    cheek.addColorStop(1, 'rgba(190, 84, 60, 0)')
    ctx.fillStyle = cheek
    ctx.fillRect(-R, -R * 0.4, R * 2, R * 1.4)

    // Sides falling away from the light, keyed to yaw.
    for (const side of [-1, 1]) {
      const strength = side > 0 ? 0.34 + Math.max(0, yaw) * 0.30 : 0.26 + Math.max(0, -yaw) * 0.30
      const sg = ctx.createLinearGradient(side * R * 0.30, 0, side * R * 0.95, 0)
      sg.addColorStop(0, 'rgba(50, 21, 9, 0)')
      sg.addColorStop(1, `rgba(50, 21, 9, ${strength})`)
      ctx.fillStyle = sg
      const x0 = side > 0 ? R * 0.30 : -R
      ctx.fillRect(x0, -R, R * 0.70, R * 2)
    }

    // Under the jaw / temples.
    const low = ctx.createLinearGradient(0, R * 0.52, 0, R * 1.02)
    low.addColorStop(0, 'rgba(48, 20, 9, 0)')
    low.addColorStop(1, 'rgba(48, 20, 9, 0.40)')
    ctx.fillStyle = low
    ctx.fillRect(-R, R * 0.5, R * 2, R * 0.55)

    // Hairline shadow.
    const hl = ctx.createLinearGradient(0, -R * 1.05, 0, -R * 0.58)
    hl.addColorStop(0, 'rgba(36, 14, 7, 0.42)')
    hl.addColorStop(1, 'rgba(36, 14, 7, 0)')
    ctx.fillStyle = hl
    ctx.fillRect(-R, -R * 1.06, R * 2, R * 0.50)
  }

  _brows(R, rig, fx) {
    const ctx = this.ctx
    const y = -R * 0.44 - rig.browRaise * R * 0.055 + rig.browFurrow * R * 0.018
    for (const side of [-1, 1]) {
      const bx = side * R * 0.35 + fx * 0.55
      const tilt = side * (0.10 + rig.browFurrow * 0.30)
      ctx.save()
      ctx.translate(bx, y)
      ctx.rotate(tilt * 0.42)
      ctx.beginPath()
      ctx.moveTo(-R * 0.20, R * 0.020)
      ctx.quadraticCurveTo(-R * 0.02, -R * 0.040 - rig.browRaise * R * 0.016, R * 0.20, R * 0.006)
      ctx.quadraticCurveTo(-R * 0.02, -R * 0.006, -R * 0.20, R * 0.036)
      ctx.closePath()
      ctx.fillStyle = 'rgba(30, 17, 11, 0.90)'
      ctx.fill()
      // Individual hairs at the tail — fine detail reads as real.
      ctx.strokeStyle = 'rgba(30, 17, 11, 0.5)'
      ctx.lineWidth = R * 0.007
      for (let i = 0; i < 6; i++) {
        const t = -0.16 + i * 0.055
        ctx.beginPath()
        ctx.moveTo(R * t, R * 0.026)
        ctx.lineTo(R * (t - 0.012), -R * 0.014)
        ctx.stroke()
      }
      ctx.restore()
    }
  }

  _eyes(R, rig, fx) {
    const ctx = this.ctx
    const open = 1 - rig.blink
    const gx = rig.gazeX * R * 0.026
    const gy = rig.gazeY * R * 0.016
    const e = this.opts.eye

    for (const side of [-1, 1]) {
      const ex = side * R * 0.335 + fx * 0.60
      const ey = -R * 0.225

      const wOpen = R * 0.132
      const hOpen = R * 0.082 * open

      // Socket recess.
      const sock = ctx.createRadialGradient(ex, ey, R * 0.01, ex, ey, R * 0.20)
      sock.addColorStop(0, 'rgba(46, 19, 9, 0.30)')
      sock.addColorStop(1, 'rgba(46, 19, 9, 0)')
      ctx.fillStyle = sock
      ctx.fillRect(ex - R * 0.24, ey - R * 0.18, R * 0.48, R * 0.36)

      if (hOpen < R * 0.006) {
        ctx.strokeStyle = 'rgba(28, 13, 7, 0.92)'
        ctx.lineWidth = R * 0.014
        ctx.beginPath()
        ctx.moveTo(ex - wOpen, ey)
        ctx.quadraticCurveTo(ex, ey + R * 0.020, ex + wOpen, ey)
        ctx.stroke()
        // Lashes on the closed lid.
        ctx.lineWidth = R * 0.006
        for (let i = 0; i < 6; i++) {
          const t = -0.8 + i * 0.32
          ctx.beginPath()
          ctx.moveTo(ex + wOpen * t, ey + R * 0.008)
          ctx.lineTo(ex + wOpen * (t + 0.06), ey + R * 0.024)
          ctx.stroke()
        }
        continue
      }

      ctx.save()
      const eye = new Path2D()
      eye.moveTo(ex - wOpen, ey + R * 0.002)
      eye.bezierCurveTo(ex - wOpen * 0.42, ey - hOpen * 1.18, ex + wOpen * 0.42, ey - hOpen * 1.18, ex + wOpen, ey - R * 0.004)
      eye.bezierCurveTo(ex + wOpen * 0.42, ey + hOpen * 0.92, ex - wOpen * 0.42, ey + hOpen * 0.92, ex - wOpen, ey + R * 0.002)
      eye.closePath()
      ctx.clip(eye)

      // Sclera: warm off-white, never #fff.
      ctx.fillStyle = '#f5efe9'
      ctx.fillRect(ex - wOpen, ey - hOpen * 1.4, wOpen * 2, hOpen * 2.9)

      // Capillary tint towards the corners.
      const cg = ctx.createLinearGradient(ex - wOpen, 0, ex + wOpen, 0)
      cg.addColorStop(0, 'rgba(200, 120, 110, 0.32)')
      cg.addColorStop(0.3, 'rgba(200, 120, 110, 0)')
      cg.addColorStop(0.7, 'rgba(200, 120, 110, 0)')
      cg.addColorStop(1, 'rgba(200, 120, 110, 0.32)')
      ctx.fillStyle = cg
      ctx.fillRect(ex - wOpen, ey - hOpen, wOpen * 2, hOpen * 2)

      const ix = ex + gx
      const iy = ey + gy
      const irisR = R * 0.060
      const ig = ctx.createRadialGradient(ix - irisR * 0.28, iy - irisR * 0.32, irisR * 0.08, ix, iy, irisR)
      ig.addColorStop(0, mixHex(e, '#ffffff', 0.36))
      ig.addColorStop(0.46, e)
      ig.addColorStop(1, mixHex(e, '#000000', 0.66))
      ctx.beginPath()
      ctx.arc(ix, iy, irisR, 0, TAU)
      ctx.fillStyle = ig
      ctx.fill()

      ctx.strokeStyle = 'rgba(255,255,255,0.09)'
      ctx.lineWidth = R * 0.003
      for (let i = 0; i < 16; i++) {
        const a = (i / 16) * TAU
        ctx.beginPath()
        ctx.moveTo(ix + Math.cos(a) * irisR * 0.36, iy + Math.sin(a) * irisR * 0.36)
        ctx.lineTo(ix + Math.cos(a) * irisR * 0.90, iy + Math.sin(a) * irisR * 0.90)
        ctx.stroke()
      }

      ctx.beginPath()
      ctx.arc(ix, iy, irisR * 0.42, 0, TAU)
      ctx.fillStyle = '#06050a'
      ctx.fill()

      // Two catchlights — the single strongest realism cue in a drawn eye.
      ctx.beginPath()
      ctx.arc(ix - irisR * 0.34, iy - irisR * 0.36, irisR * 0.26, 0, TAU)
      ctx.fillStyle = 'rgba(255,255,255,0.95)'
      ctx.fill()
      ctx.beginPath()
      ctx.arc(ix + irisR * 0.30, iy + irisR * 0.32, irisR * 0.10, 0, TAU)
      ctx.fillStyle = 'rgba(255,255,255,0.42)'
      ctx.fill()

      // Lid shadow across the top of the eyeball.
      const lid = ctx.createLinearGradient(ex, ey - hOpen * 1.2, ex, ey + hOpen * 0.5)
      lid.addColorStop(0, 'rgba(26, 10, 5, 0.60)')
      lid.addColorStop(1, 'rgba(26, 10, 5, 0)')
      ctx.fillStyle = lid
      ctx.fillRect(ex - wOpen, ey - hOpen * 1.4, wOpen * 2, hOpen * 1.9)
      ctx.restore()

      // Upper lash line.
      ctx.strokeStyle = 'rgba(22, 11, 7, 0.95)'
      ctx.lineWidth = R * 0.010
      ctx.beginPath()
      ctx.moveTo(ex - wOpen, ey + R * 0.002)
      ctx.bezierCurveTo(ex - wOpen * 0.42, ey - hOpen * 1.18, ex + wOpen * 0.42, ey - hOpen * 1.18, ex + wOpen, ey - R * 0.004)
      ctx.stroke()

      // Lower lash line: thin and warm, not black.
      ctx.strokeStyle = 'rgba(90, 46, 30, 0.55)'
      ctx.lineWidth = R * 0.005
      ctx.beginPath()
      ctx.moveTo(ex - wOpen * 0.86, ey + hOpen * 0.74)
      ctx.quadraticCurveTo(ex, ey + hOpen * 0.96, ex + wOpen * 0.82, ey + hOpen * 0.70)
      ctx.stroke()
    }
  }

  _nose(R, rig, fx) {
    const ctx = this.ctx
    const nx = fx * 1.05
    const shadowSide = Math.sin(rig.yaw) >= 0 ? 1 : -1

    // Bridge highlight — radial falloff, not a filled quad. A hard-edged polygon
    // reads as a scar rather than a specular plane.
    const bh = ctx.createRadialGradient(nx - R * 0.012, -R * 0.16, R * 0.01, nx, R * 0.02, R * 0.30)
    bh.addColorStop(0, 'rgba(255, 238, 218, 0.22)')
    bh.addColorStop(0.6, 'rgba(255, 238, 218, 0.07)')
    bh.addColorStop(1, 'rgba(255, 238, 218, 0)')
    ctx.fillStyle = bh
    ctx.beginPath()
    ctx.moveTo(nx - R * 0.040, -R * 0.26)
    ctx.quadraticCurveTo(nx - R * 0.052, R * 0.10, nx - R * 0.050, R * 0.19)
    ctx.lineTo(nx + R * 0.050, R * 0.19)
    ctx.quadraticCurveTo(nx + R * 0.052, R * 0.10, nx + R * 0.040, -R * 0.26)
    ctx.closePath()
    ctx.fill()

    // Side plane in shadow.
    ctx.fillStyle = `rgba(52, 21, 9, ${0.20 + Math.abs(Math.sin(rig.yaw)) * 0.14})`
    ctx.beginPath()
    ctx.ellipse(nx + shadowSide * R * 0.072, R * 0.10, R * 0.040, R * 0.150, shadowSide * 0.10, 0, TAU)
    ctx.fill()

    // Tip.
    ctx.beginPath()
    ctx.ellipse(nx, R * 0.245, R * 0.082, R * 0.058, 0, 0, TAU)
    ctx.fillStyle = 'rgba(255, 226, 200, 0.20)'
    ctx.fill()

    // Nostril wings.
    for (const side of [-1, 1]) {
      const vis = 1 - Math.max(0, side * Math.sin(rig.yaw)) * 0.65
      if (vis < 0.15) continue
      ctx.save()
      ctx.translate(nx + side * R * 0.052, R * 0.268)
      ctx.scale(vis, 1)
      ctx.beginPath()
      ctx.ellipse(0, 0, R * 0.019, R * 0.012, side * 0.32, 0, TAU)
      ctx.fillStyle = 'rgba(34, 12, 5, 0.74)'
      ctx.fill()
      ctx.restore()
    }

    // Shadow beneath, connecting the nose to the lip.
    const under = ctx.createRadialGradient(nx, R * 0.33, R * 0.01, nx, R * 0.33, R * 0.15)
    under.addColorStop(0, 'rgba(44, 17, 7, 0.24)')
    under.addColorStop(1, 'rgba(44, 17, 7, 0)')
    ctx.fillStyle = under
    ctx.fillRect(nx - R * 0.16, R * 0.20, R * 0.32, R * 0.28)
  }

  _mouth(R, rig, fx) {
    const ctx = this.ctx
    const open = Math.min(1, rig.jawOpen)
    const wide = rig.mouthWide
    const round = rig.lipRound
    const smile = rig.mouthSmile

    const mx = fx * 0.85
    const my = R * (0.545 + open * 0.020)
    const halfW = R * (0.205 + wide * 0.032 - round * 0.048 + smile * 0.020)
    const gapH = R * (0.005 + open * 0.108)
    const corner = smile * R * 0.046

    // Philtrum shading.
    const ph = ctx.createLinearGradient(mx, my - R * 0.10, mx, my - R * 0.02)
    ph.addColorStop(0, 'rgba(48, 18, 7, 0)')
    ph.addColorStop(1, 'rgba(48, 18, 7, 0.20)')
    ctx.fillStyle = ph
    ctx.fillRect(mx - halfW * 0.5, my - R * 0.10, halfW, R * 0.08)

    // Outer lip body (both lips), so the mouth has volume even when closed.
    const lipsOuter = new Path2D()
    lipsOuter.moveTo(mx - halfW, my - corner)
    lipsOuter.bezierCurveTo(mx - halfW * 0.55, my - R * 0.052 - corner, mx + halfW * 0.55, my - R * 0.052 - corner, mx + halfW, my - corner)
    lipsOuter.bezierCurveTo(mx + halfW * 0.60, my + R * 0.080 - corner, mx - halfW * 0.60, my + R * 0.080 - corner, mx - halfW, my - corner)
    lipsOuter.closePath()
    const lg = ctx.createLinearGradient(mx, my - R * 0.055, mx, my + R * 0.08)
    lg.addColorStop(0, this.opts.lip.dark)
    lg.addColorStop(0.34, this.opts.lip.base)
    lg.addColorStop(0.72, this.opts.lip.light)
    lg.addColorStop(1, this.opts.lip.dark)
    ctx.fillStyle = lg
    ctx.fill(lipsOuter)

    // Opening.
    if (gapH > R * 0.008) {
      ctx.save()
      const cav = new Path2D()
      cav.moveTo(mx - halfW * 0.94, my - corner * 0.5)
      cav.quadraticCurveTo(mx, my - gapH * 0.72 - corner, mx + halfW * 0.94, my - corner * 0.5)
      cav.quadraticCurveTo(mx, my + gapH * 1.25, mx - halfW * 0.94, my - corner * 0.5)
      cav.closePath()
      ctx.fillStyle = '#2b1011'
      ctx.fill(cav)
      ctx.clip(cav)

      // Upper teeth.
      const th = Math.max(R * 0.012, gapH * 0.60)
      const tg = ctx.createLinearGradient(0, my - gapH * 0.7, 0, my - gapH * 0.7 + th)
      tg.addColorStop(0, '#f8f4ee')
      tg.addColorStop(1, '#d6cfc5')
      ctx.fillStyle = tg
      ctx.beginPath()
      ctx.moveTo(mx - halfW, my - gapH * 0.9)
      ctx.lineTo(mx + halfW, my - gapH * 0.9)
      ctx.lineTo(mx + halfW, my - gapH * 0.9 + th)
      ctx.quadraticCurveTo(mx, my - gapH * 0.9 + th * 1.18, mx - halfW, my - gapH * 0.9 + th)
      ctx.closePath()
      ctx.fill()

      ctx.strokeStyle = 'rgba(120, 108, 98, 0.26)'
      ctx.lineWidth = R * 0.0035
      for (let i = 1; i < 7; i++) {
        const x = mx - halfW + (halfW * 2 * i) / 7
        ctx.beginPath()
        ctx.moveTo(x, my - gapH * 0.86)
        ctx.lineTo(x, my - gapH * 0.86 + th * 0.9)
        ctx.stroke()
      }

      if (open > 0.36) {
        ctx.fillStyle = 'rgba(146, 62, 66, 0.80)'
        ctx.beginPath()
        ctx.ellipse(mx, my + gapH * 0.80, halfW * 0.50, gapH * 0.32, 0, 0, TAU)
        ctx.fill()
      }
      ctx.restore()
    }

    // Wet specular on the lower lip.
    ctx.globalAlpha = 0.42
    ctx.fillStyle = 'rgba(255, 244, 236, 0.95)'
    ctx.beginPath()
    ctx.ellipse(mx - halfW * 0.22, my + R * 0.040, halfW * 0.20, R * 0.009, -0.12, 0, TAU)
    ctx.fill()
    ctx.globalAlpha = 1

    // Corner creases.
    ctx.strokeStyle = 'rgba(46, 16, 8, 0.32)'
    ctx.lineWidth = R * 0.007
    for (const side of [-1, 1]) {
      ctx.beginPath()
      ctx.moveTo(mx + side * halfW, my - corner)
      ctx.quadraticCurveTo(mx + side * (halfW + R * 0.016), my + R * 0.006, mx + side * (halfW + R * 0.006), my + R * 0.026)
      ctx.stroke()
    }
  }

  /* --------------------------------------------------------------- lighting */

  _lighting(w, h, R, cx, cy, rig) {
    const ctx = this.ctx
    // Cool rim from camera-left, warm kicker from camera-right.
    const g1 = ctx.createRadialGradient(cx + R * 1.05, cy - R * 0.55, R * 0.1, cx + R * 0.95, cy - R * 0.45, R * 1.45)
    g1.addColorStop(0, 'rgba(140, 190, 255, 0.15)')
    g1.addColorStop(1, 'rgba(140, 190, 255, 0)')
    ctx.fillStyle = g1
    ctx.fillRect(0, 0, w, h)

    const g2 = ctx.createRadialGradient(cx - R * 1.05, cy - R * 0.40, R * 0.1, cx - R * 0.95, cy - R * 0.30, R * 1.35)
    g2.addColorStop(0, 'rgba(255, 198, 142, 0.10)')
    g2.addColorStop(1, 'rgba(255, 198, 142, 0)')
    ctx.fillStyle = g2
    ctx.fillRect(0, 0, w, h)
  }

  _drawGrain(w, h) {
    const targetW = Math.max(1, Math.round(w / 3))
    if (!this._grainTex || this._grainTex.width !== targetW) {
      const gh = Math.max(1, Math.round(h / 3))
      const cv = document.createElement('canvas')
      cv.width = targetW
      cv.height = gh
      const gctx = cv.getContext('2d')
      const img = gctx.createImageData(targetW, gh)
      for (let i = 0; i < img.data.length; i += 4) {
        const v = 128 + (rnd(i) - 0.5) * 24
        img.data[i] = v
        img.data[i + 1] = v
        img.data[i + 2] = v
        img.data[i + 3] = 6
      }
      gctx.putImageData(img, 0, 0)
      this._grainTex = cv
    }
    this.ctx.save()
    this.ctx.globalCompositeOperation = 'overlay'
    this.ctx.drawImage(this._grainTex, 0, 0, w, h)
    this.ctx.restore()
  }
}
