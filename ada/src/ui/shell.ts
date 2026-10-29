// Server-rendered shell. One small HTML document; all behaviour lives in
// /static/js. Rendering the frame on the edge keeps first paint instant on the
// low-end Android phones most learners actually use.

export type ShellProps = {
  initialLesson?: string | null
  embed?: boolean
}

export function shell(props: ShellProps): string {
  const cfg = JSON.stringify({
    initialLesson: props.initialLesson ?? null,
    embed: Boolean(props.embed),
    apiBase: ''
  })

  return `<!DOCTYPE html>
<html lang="en" data-theme="night">
<head>
<meta charset="utf-8" />
<meta name="viewport" content="width=device-width, initial-scale=1, viewport-fit=cover" />
<meta name="theme-color" content="#080b13" />
<title>Ada — MindKlass Tutor</title>
<meta name="description" content="Ada is a live MindKlass tutor: a talking avatar that teaches your courses and answers questions in your own language." />
<link rel="manifest" href="/static/manifest.webmanifest" />
<link rel="icon" href="/static/icon.svg" type="image/svg+xml" />
<link rel="stylesheet" href="/static/avatar.css" />
</head>
<body>
<div id="mk-root" class="mk-app">
  <header class="mk-topbar">
    <div class="mk-brand">
      <span class="mk-dot" aria-hidden="true"></span>
      <span class="mk-brand-text">MindKlass</span>
      <span class="mk-brand-sub">Ada · Live Tutor</span>
    </div>
    <div class="mk-topbar-actions">
      <button id="mk-status-pill" class="mk-pill" type="button" aria-live="polite">Connecting…</button>
      <button id="mk-help-btn" class="mk-icon-btn" type="button" aria-label="How Ada works" title="How Ada works">?</button>
    </div>
  </header>

  <main class="mk-main">
    <aside class="mk-rail" id="mk-rail" aria-label="Courses">
      <div class="mk-rail-head">
        <h2>Courses</h2>
        <span id="mk-course-count" class="mk-muted"></span>
      </div>
      <div id="mk-courses" class="mk-courses"></div>
    </aside>

    <section class="mk-stage-wrap" aria-label="Tutor">
      <div id="mk-stage" class="mk-stage">
        <canvas id="mk-canvas" aria-label="Ada, your tutor avatar"></canvas>
        <div class="mk-stage-vignette" aria-hidden="true"></div>

        <div class="mk-stage-overlay">
          <div class="mk-avatar-meta">
            <span id="mk-emotion" class="mk-chip">Attentive</span>
            <span id="mk-speaking" class="mk-chip mk-chip-ghost" hidden>Speaking</span>
          </div>
          <div class="mk-stage-caption">
            <p id="mk-caption" class="mk-caption" aria-live="polite"></p>
          </div>
        </div>

        <div class="mk-stage-controls">
          <button id="mk-mic" class="mk-mic" type="button" aria-label="Hold a conversation" aria-pressed="false">
            <svg viewBox="0 0 24 24" width="22" height="22" aria-hidden="true"><path fill="currentColor" d="M12 15a3 3 0 0 0 3-3V6a3 3 0 1 0-6 0v6a3 3 0 0 0 3 3Zm5-3a5 5 0 0 1-10 0H5a7 7 0 0 0 6 6.92V22h2v-3.08A7 7 0 0 0 19 12h-2Z"/></svg>
            <span class="mk-mic-label">Talk</span>
          </button>
          <button id="mk-play" class="mk-round" type="button" aria-label="Play the current lesson">▶</button>
          <button id="mk-mute" class="mk-round" type="button" aria-label="Mute the tutor">🔊</button>
          <button id="mk-lang" class="mk-round mk-round-wide" type="button" aria-label="Change language">🌐 <span id="mk-lang-code">EN</span></button>
        </div>
      </div>

      <div id="mk-lesson-bar" class="mk-lesson-bar" hidden>
        <div class="mk-lesson-progress"><div id="mk-lesson-fill" class="mk-lesson-fill"></div></div>
        <div class="mk-lesson-meta">
          <span id="mk-lesson-title">—</span>
          <span id="mk-lesson-step" class="mk-muted"></span>
        </div>
        <div class="mk-lesson-actions">
          <button id="mk-prev" class="mk-ghost-btn" type="button">Back</button>
          <button id="mk-next" class="mk-ghost-btn mk-ghost-primary" type="button">Next</button>
          <button id="mk-exit-lesson" class="mk-ghost-btn" type="button">Close</button>
        </div>
      </div>
    </section>

    <aside class="mk-chat" aria-label="Conversation">
      <div class="mk-chat-head">
        <h2>Conversation</h2>
        <span id="mk-mode-badge" class="mk-muted" title="Which tutor brain is answering">—</span>
      </div>
      <div id="mk-messages" class="mk-messages" role="log" aria-live="polite"></div>

      <div id="mk-suggestions" class="mk-suggestions"></div>

      <form id="mk-composer" class="mk-composer">
        <textarea id="mk-input" rows="1" placeholder="Ask Ada anything about your course…" autocomplete="off"></textarea>
        <button id="mk-send" class="mk-send" type="submit" aria-label="Send">
          <svg viewBox="0 0 24 24" width="20" height="20" aria-hidden="true"><path fill="currentColor" d="M3 20.5 21 12 3 3.5v6.2L15 12 3 14.3z"/></svg>
        </button>
      </form>
    </aside>
  </main>

  <dialog id="mk-lang-dialog" class="mk-dialog">
    <form method="dialog">
      <h3>Choose your language</h3>
      <p class="mk-muted">Ada teaches and listens in the language you pick. You can switch at any point.</p>
      <div id="mk-lang-list" class="mk-lang-list"></div>
      <button class="mk-ghost-btn" value="close">Done</button>
    </form>
  </dialog>

  <dialog id="mk-help-dialog" class="mk-dialog">
    <form method="dialog">
      <h3>How Ada works</h3>
      <ol class="mk-help-list">
        <li><strong>Pick a course</strong> on the left, then press ▶ to have Ada teach the lesson out loud.</li>
        <li><strong>Interrupt any time.</strong> While Ada speaks, press Talk and ask a question — she stops and answers.</li>
        <li><strong>Choose your language.</strong> Ada explains in your mother tongue, keeping the exam term in English.</li>
        <li><strong>She checks you understand.</strong> Every explanation ends with a question. Answer it and she adapts.</li>
      </ol>
      <button class="mk-ghost-btn" value="close">Got it</button>
    </form>
  </dialog>

  <div id="mk-toast" class="mk-toast" role="status" aria-live="polite" hidden></div>
</div>
<script>window.__MK__=${cfg};</script>
<script type="module" src="/static/js/app.js"></script>
</body>
</html>`
}
