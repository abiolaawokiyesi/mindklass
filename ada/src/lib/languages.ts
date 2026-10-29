// Native-language registry.
// Every entry carries what each layer needs:
//  - bcp47      : SpeechSynthesis / SpeechRecognition language tag
//  - voices     : preferred voice-name fragments per platform (best-effort)
//  - hint       : instruction handed to the LLM so it speaks naturally, not literally
//  - greeting   : the avatar's first line, already in-language (works with no LLM)

export type Lang = {
  code: string
  label: string
  native: string
  bcp47: string
  rtl?: boolean
  voices?: string[]
  greeting: string
  hint: string
}

export const LANGS: Lang[] = [
  {
    code: 'en',
    label: 'English',
    native: 'English',
    bcp47: 'en-NG',
    voices: ['Google UK English Female', 'Samantha', 'Microsoft Aria', 'English'],
    greeting: 'Welcome back. I am Ada, your MindKlass tutor. What shall we work on today?',
    hint: 'Speak clear, warm, standard English. Short sentences. Use Nigerian classroom examples where natural.'
  },
  {
    code: 'yo',
    label: 'Yoruba',
    native: 'Yorùbá',
    bcp47: 'yo-NG',
    voices: ['Yoruba', 'yo-NG'],
    greeting: 'Ẹ káàbọ̀. Èmi ni Ada, olùkọ́ rẹ ní MindKlass. Kí ni kí a ṣiṣẹ́ lé lórí lónìí?',
    hint:
      'Speak Yoruba (Yorùbá) with correct tone marks (à á ẹ̀ ọ́). Keep English technical terms only when they are the standard classroom term, and gloss them briefly in Yoruba. Use honorifics naturally.'
  },
  {
    code: 'ha',
    label: 'Hausa',
    native: 'Hausa',
    bcp47: 'ha-NG',
    voices: ['Hausa', 'ha-NG'],
    greeting: 'Barka da dawowa. Ni ce Ada, malamar ku a MindKlass. Me za mu yi aiki a kai yau?',
    hint: 'Speak simple, friendly Hausa. Explain technical terms in Hausa first, then give the English term in brackets.'
  },
  {
    code: 'ig',
    label: 'Igbo',
    native: 'Igbo',
    bcp47: 'ig-NG',
    voices: ['Igbo', 'ig-NG'],
    greeting: 'Nnọọ. Abụ m Ada, onye nkuzi gị na MindKlass. Gịnị ka anyị ga-arụ taa?',
    hint: 'Speak simple, encouraging Igbo with correct diacritics where possible. Introduce the English term after the Igbo explanation.'
  },
  {
    code: 'pcm',
    label: 'Nigerian Pidgin',
    native: 'Naija Pidgin',
    bcp47: 'en-NG',
    voices: ['English'],
    greeting: 'How far! I be Ada, your MindKlass tutor. Wetin we go learn today?',
    hint:
      'Speak natural Nigerian Pidgin, the way a friendly teacher actually talks: "make we look am", "you sabi", "no wahala". Keep it respectful and clear; do not caricature it.'
  },
  {
    code: 'sw',
    label: 'Swahili',
    native: 'Kiswahili',
    bcp47: 'sw-KE',
    voices: ['Swahili', 'sw-KE'],
    greeting: 'Karibu tena. Mimi ni Ada, mwalimu wako wa MindKlass. Tujifunze nini leo?',
    hint: 'Speak standard Kiswahili (Kiswahili sanifu). Introduce terms in Swahili first, then the English equivalent.'
  },
  {
    code: 'am',
    label: 'Amharic',
    native: 'አማርኛ',
    bcp47: 'am-ET',
    voices: ['Amharic', 'am-ET'],
    greeting: 'እንኳን ደህና መጡ። እኔ አዳ ነኝ፣ የMindKlass አስተማሪዎ። ዛሬ ምን እንማር?',
    hint: 'Speak natural Amharic in Ethiopic script. Explain the concept in Amharic first, then give the English term.'
  },
  {
    code: 'tw',
    label: 'Twi',
    native: 'Twi (Akan)',
    bcp47: 'ak-GH',
    voices: ['Twi', 'Akan'],
    greeting: 'Akwaaba. Me din de Ada, wo MindKlass ɔkyerɛkyerɛfo. Yɛbɛyɛ dɛn nnɛ?',
    hint: 'Speak simple Twi (Akan). Give the English technical term alongside the Twi explanation.'
  },
  {
    code: 'zu',
    label: 'Zulu',
    native: 'isiZulu',
    bcp47: 'zu-ZA',
    voices: ['Zulu', 'zu-ZA'],
    greeting: 'Siyakwamukela. Ngingu-Ada, uthisha wakho we-MindKlass. Sizofunda ini namuhla?',
    hint: 'Speak natural isiZulu with respect. Explain first in isiZulu, then the English term.'
  },
  {
    code: 'xh',
    label: 'Xhosa',
    native: 'isiXhosa',
    bcp47: 'xh-ZA',
    voices: ['Xhosa', 'xh-ZA'],
    greeting: 'Wamkelekile. Ndingu-Ada, utitshala wakho we-MindKlass. Siza kufunda ntoni namhlanje?',
    hint: 'Speak natural isiXhosa. Explain in isiXhosa first, then the English term.'
  },
  {
    code: 'sn',
    label: 'Shona',
    native: 'chiShona',
    bcp47: 'sn-ZW',
    voices: ['Shona', 'sn-ZW'],
    greeting: 'Mauya. Ndini Ada, mudzidzisi wako weMindKlass. Todzidza chii nhasi?',
    hint: 'Speak natural chiShona. Explain in chiShona first, then the English term.'
  },
  {
    code: 'st',
    label: 'Sesotho',
    native: 'Sesotho',
    bcp47: 'st-ZA',
    voices: ['Sotho', 'Sesotho'],
    greeting: 'O amohelehile. Ke nna Ada, mosuoe oa hao oa MindKlass. Re tla ithuta eng kajeno?',
    hint: 'Speak natural Sesotho. Explain in Sesotho first, then the English term.'
  },
  {
    code: 'wo',
    label: 'Wolof',
    native: 'Wolof',
    bcp47: 'wo-SN',
    voices: ['Wolof'],
    greeting: 'Dalal ak jàmm. Maa ngi tuddu Ada, sama teacher ci MindKlass. Lan nga bëgg jàng tey?',
    hint: 'Speak simple Wolof. Give the English technical term after the Wolof explanation.'
  },
  {
    code: 'rw',
    label: 'Kinyarwanda',
    native: 'Ikinyarwanda',
    bcp47: 'rw-RW',
    voices: ['Kinyarwanda', 'rw-RW'],
    greeting: 'Murakaza neza. Ndi Ada, umwarimu wawe muri MindKlass. Tugiye kwiga iki uyu munsi?',
    hint: 'Speak natural Ikinyarwanda. Explain in Kinyarwanda first, then the English term.'
  },
  {
    code: 'so',
    label: 'Somali',
    native: 'Soomaali',
    bcp47: 'so-SO',
    voices: ['Somali', 'so-SO'],
    greeting: 'Ku soo dhawow. Waxaan ahay Ada, macallinkaaga MindKlass. Maxaan maanta barannaa?',
    hint: 'Speak natural Somali. Explain in Somali first, then the English term.'
  },
  {
    code: 'fr',
    label: 'French',
    native: 'Français',
    bcp47: 'fr-FR',
    voices: ['Google français', 'Amelie', 'Microsoft Denise', 'French'],
    greeting: 'Bon retour. Je suis Ada, votre tutrice MindKlass. Sur quoi travaillons-nous aujourd’hui ?',
    hint: 'Speak clear, warm French. Keep sentences short and use vous-form with the learner.'
  },
  {
    code: 'ar',
    label: 'Arabic',
    native: 'العربية',
    bcp47: 'ar-SA',
    rtl: true,
    voices: ['Arabic', 'Majed', 'Microsoft Hamed'],
    greeting: 'أهلاً بعودتك. أنا آدا، معلّمتك في MindKlass. ماذا ندرس اليوم؟',
    hint: 'Speak Modern Standard Arabic, simple and warm. Give the English technical term in brackets after the Arabic term.'
  },
  {
    code: 'hi',
    label: 'Hindi',
    native: 'हिन्दी',
    bcp47: 'hi-IN',
    voices: ['Google हिन्दी', 'Microsoft Swara', 'Hindi'],
    greeting: 'वापसी पर स्वागत है। मैं अदा हूँ, आपकी MindKlass शिक्षिका। आज क्या सीखेंगे?',
    hint: 'Speak simple, friendly Hindi in Devanagari. Give the English technical term in brackets after the Hindi term.'
  },
  {
    code: 'ur',
    label: 'Urdu',
    native: 'اردو',
    bcp47: 'ur-PK',
    rtl: true,
    voices: ['Urdu', 'Microsoft Asad'],
    greeting: 'خوش آمدید۔ میں ادا ہوں، آپ کی MindKlass ٹیوٹر۔ آج کیا سیکھیں؟',
    hint: 'Speak simple, respectful Urdu. Give the English technical term in brackets.'
  },
  {
    code: 'pt',
    label: 'Portuguese',
    native: 'Português',
    bcp47: 'pt-BR',
    voices: ['Google português do Brasil', 'Luciana', 'Microsoft Francisca'],
    greeting: 'Bem-vindo de volta. Eu sou a Ada, sua tutora do MindKlass. O que vamos estudar hoje?',
    hint: 'Speak warm Brazilian Portuguese, short sentences.'
  },
  {
    code: 'es',
    label: 'Spanish',
    native: 'Español',
    bcp47: 'es-ES',
    voices: ['Google español', 'Monica', 'Microsoft Elvira'],
    greeting: 'Bienvenido de nuevo. Soy Ada, tu tutora de MindKlass. ¿Qué estudiamos hoy?',
    hint: 'Speak clear, warm Spanish with short sentences.'
  },
  {
    code: 'zh',
    label: 'Mandarin',
    native: '中文',
    bcp47: 'zh-CN',
    voices: ['Google 普通话', 'Microsoft Xiaoxiao', 'Ting-Ting'],
    greeting: '欢迎回来。我是Ada，你的MindKlass老师。今天我们学什么？',
    hint: 'Speak simple, natural Mandarin Chinese. Give the English technical term in brackets after the Chinese term.'
  },
  {
    code: 'bn',
    label: 'Bengali',
    native: 'বাংলা',
    bcp47: 'bn-IN',
    voices: ['Bengali', 'Microsoft Nabanita'],
    greeting: 'আবার স্বাগতম। আমি অদা, আপনার MindKlass শিক্ষক। আজ কী শিখব?',
    hint: 'Speak simple, friendly Bengali. Give the English technical term in brackets.'
  }
]

export const langByCode = (code: string): Lang => LANGS.find((l) => l.code === code) ?? LANGS[0]
export const langCodes = () => LANGS.map((l) => l.code)
