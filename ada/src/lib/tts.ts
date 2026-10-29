// Server-side text-to-speech proxy.
//
// Why proxy at all? Two reasons that matter in production:
//   1. High-quality neural voices for African languages (Yoruba, Hausa, Igbo,
//      Swahili, Amharic…) are only available from commercial APIs, and their
//      keys must never be in the browser.
//   2. The browser's built-in `speechSynthesis` is the fallback, not the plan:
//      on Android/iOS it often has no voice at all for these languages, and it
//      cannot be streamed or cached. A real neural voice is what makes the
//      avatar feel like a person.
//
// If no provider is configured the route returns 501 with a machine-readable
// reason, and the client transparently falls back to the browser voice.

export type TtsProvider = 'azure' | 'elevenlabs' | 'openai' | 'google'

type SpeakArgs = {
  text: string
  langCode: string
  bcp47: string
  provider?: string
  apiKey?: string
  baseUrl?: string
  voiceMap?: string
}

/**
 * Voice selection per language, per provider.
 * Azure is listed first because it has genuine neural coverage for the widest
 * set of African languages, which is the actual requirement here.
 */
const AZURE_VOICES: Record<string, string> = {
  en: 'en-NG-EzinneNeural',
  yo: 'yo-NG-IyanuNeural',
  ha: 'ha-NG-AminaNeural',
  ig: 'ig-NG-EzinneNeural',
  pcm: 'en-NG-AbeoNeural',
  sw: 'sw-KE-ZuriNeural',
  am: 'am-ET-MekdesNeural',
  zu: 'zu-ZA-ThandoNeural',
  xh: 'xh-ZA-NomalangaNeural',
  af: 'af-ZA-AdriNeural',
  fr: 'fr-FR-DeniseNeural',
  ar: 'ar-SA-ZariyahNeural',
  hi: 'hi-IN-SwaraNeural',
  ur: 'ur-PK-UzmaNeural',
  pt: 'pt-BR-FranciscaNeural',
  es: 'es-ES-ElviraNeural',
  zh: 'zh-CN-XiaoxiaoNeural',
  bn: 'bn-IN-TanishaaNeural',
  tw: 'en-GH-NanaNeural',
  wo: 'fr-SN-FatouNeural',
  rw: 'fr-RW-???',
  sn: 'en-ZW-???',
  st: 'en-ZA-LeahNeural',
  so: 'so-SO-UbaxNeural'
}

const OPENAI_VOICES = ['alloy', 'coral', 'sage', 'verse'] as const

function pickAzureVoice(langCode: string, override?: string) {
  const raw = override || AZURE_VOICES[langCode] || 'en-NG-EzinneNeural'
  // Guard against placeholder entries for languages Azure has no neural voice for:
  // fall back to the closest available voice rather than sending a bad request.
  return raw.includes('???') ? 'en-NG-EzinneNeural' : raw
}

export type TtsResult =
  | { ok: true; audio: ArrayBuffer; contentType: string; provider: TtsProvider; voice: string }
  | { ok: false; reason: string }

export async function synthesize(args: SpeakArgs): Promise<TtsResult> {
  const provider = (args.provider || '').toLowerCase() as TtsProvider | ''
  if (!args.apiKey || !provider) return { ok: false, reason: 'no_provider_configured' }

  const text = args.text.slice(0, 1200)
  if (!text.trim()) return { ok: false, reason: 'empty_text' }

  const voiceOverride = args.voiceMap
    ? (() => {
        try {
          return (JSON.parse(args.voiceMap) as Record<string, string>)[args.langCode]
        } catch {
          return undefined
        }
      })()
    : undefined

  try {
    if (provider === 'azure') {
      const region = args.baseUrl || 'southafricanorth'
      const voice = pickAzureVoice(args.langCode, voiceOverride)
      const ssml = `<speak version='1.0' xml:lang='${args.bcp47}'><voice name='${voice}'><prosody rate='0%' pitch='0%'>${escapeXml(
        text
      )}</prosody></voice></speak>`
      const res = await fetch(`https://${region}.tts.speech.microsoft.com/cognitiveservices/v1`, {
        method: 'POST',
        headers: {
          'Ocp-Apim-Subscription-Key': args.apiKey,
          'Content-Type': 'application/ssml+xml',
          'X-Microsoft-OutputFormat': 'audio-24khz-48kbitrate-mono-mp3',
          'User-Agent': 'MindKlassAvatar'
        },
        body: ssml
      })
      if (!res.ok) return { ok: false, reason: `azure_${res.status}` }
      return { ok: true, audio: await res.arrayBuffer(), contentType: 'audio/mpeg', provider, voice }
    }

    if (provider === 'elevenlabs') {
      const voice = voiceOverride || '21m00Tcm4TlvDq8ikWAM'
      const base = args.baseUrl || 'https://api.elevenlabs.io'
      const res = await fetch(`${base}/v1/text-to-speech/${voice}?output_format=mp3_44100_128`, {
        method: 'POST',
        headers: { 'xi-api-key': args.apiKey, 'content-type': 'application/json' },
        body: JSON.stringify({
          text,
          model_id: 'eleven_multilingual_v2',
          voice_settings: { stability: 0.45, similarity_boost: 0.8, style: 0.25, use_speaker_boost: true }
        })
      })
      if (!res.ok) return { ok: false, reason: `elevenlabs_${res.status}` }
      return { ok: true, audio: await res.arrayBuffer(), contentType: 'audio/mpeg', provider, voice }
    }

    if (provider === 'openai') {
      const base = (args.baseUrl || 'https://api.openai.com/v1').replace(/\/$/, '')
      const voice = voiceOverride || OPENAI_VOICES[0]
      const res = await fetch(`${base}/audio/speech`, {
        method: 'POST',
        headers: { authorization: `Bearer ${args.apiKey}`, 'content-type': 'application/json' },
        body: JSON.stringify({
          model: 'gpt-4o-mini-tts',
          voice,
          input: text,
          response_format: 'mp3',
          instructions: `Speak ${args.bcp47} like a warm, patient classroom teacher. Natural pace, clear consonants.`
        })
      })
      if (!res.ok) return { ok: false, reason: `openai_${res.status}` }
      return { ok: true, audio: await res.arrayBuffer(), contentType: 'audio/mpeg', provider, voice }
    }

    if (provider === 'google') {
      const base = (args.baseUrl || 'https://texttospeech.googleapis.com/v1').replace(/\/$/, '')
      const res = await fetch(`${base}/text:synthesize?key=${encodeURIComponent(args.apiKey)}`, {
        method: 'POST',
        headers: { 'content-type': 'application/json' },
        body: JSON.stringify({
          input: { text },
          voice: { languageCode: args.bcp47, ssmlGender: 'FEMALE' },
          audioConfig: { audioEncoding: 'MP3', speakingRate: 0.98 }
        })
      })
      if (!res.ok) return { ok: false, reason: `google_${res.status}` }
      const json = (await res.json()) as { audioContent?: string }
      if (!json.audioContent) return { ok: false, reason: 'google_empty' }
      const bin = Uint8Array.from(atob(json.audioContent), (ch) => ch.charCodeAt(0))
      return { ok: true, audio: bin.buffer, contentType: 'audio/mpeg', provider, voice: args.bcp47 }
    }

    return { ok: false, reason: `unknown_provider_${provider}` }
  } catch (e) {
    return { ok: false, reason: `tts_error_${(e as Error).message.slice(0, 60)}` }
  }
}

function escapeXml(s: string) {
  return s
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')
    .replace(/"/g, '&quot;')
    .replace(/'/g, '&apos;')
}
