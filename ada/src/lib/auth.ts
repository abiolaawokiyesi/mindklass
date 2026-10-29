// Supabase-linked identity.
//
// MindKlass already authenticates users with Supabase. The avatar engine does not
// want a second login, so it accepts the Supabase access token the SPA already
// holds and links it to a local learner row keyed by `supabase_uid`.
//
// If SUPABASE_JWT_SECRET is configured we verify the HS256 signature properly.
// Without it (local sandbox, or a school running the engine standalone) we fall
// back to an unsigned decode so development is never blocked — and we say so in
// the health payload so nobody mistakes it for verified auth in production.

export type Identity = {
  uid: string
  email?: string
  name?: string
  verified: boolean
}

const b64urlToBytes = (s: string): Uint8Array => {
  const pad = s.replace(/-/g, '+').replace(/_/g, '/')
  const padded = pad + '='.repeat((4 - (pad.length % 4)) % 4)
  const bin = atob(padded)
  const out = new Uint8Array(bin.length)
  for (let i = 0; i < bin.length; i++) out[i] = bin.charCodeAt(i)
  return out
}

const decodeJson = (s: string): any => {
  try {
    return JSON.parse(new TextDecoder().decode(b64urlToBytes(s)))
  } catch {
    return null
  }
}

export async function verifySupabaseJwt(token: string, secret?: string): Promise<Identity | null> {
  const parts = token.split('.')
  if (parts.length !== 3) return null
  const payload = decodeJson(parts[1])
  if (!payload?.sub) return null

  // Reject expired tokens even in decode-only mode.
  if (typeof payload.exp === 'number' && payload.exp * 1000 < Date.now()) return null

  if (!secret) {
    return {
      uid: payload.sub,
      email: payload.email,
      name: payload.user_metadata?.full_name || payload.user_metadata?.name,
      verified: false
    }
  }

  try {
    const key = await crypto.subtle.importKey(
      'raw',
      new TextEncoder().encode(secret),
      { name: 'HMAC', hash: 'SHA-256' },
      false,
      ['verify']
    )
    const ok = await crypto.subtle.verify(
      'HMAC',
      key,
      b64urlToBytes(parts[2]),
      new TextEncoder().encode(`${parts[0]}.${parts[1]}`)
    )
    if (!ok) return null
    return {
      uid: payload.sub,
      email: payload.email,
      name: payload.user_metadata?.full_name || payload.user_metadata?.name,
      verified: true
    }
  } catch {
    return null
  }
}

export function bearer(c: { req: { header: (k: string) => string | undefined } }): string | null {
  const h = c.req.header('authorization') || ''
  const m = h.match(/^Bearer\s+(.+)$/i)
  return m ? m[1] : null
}
