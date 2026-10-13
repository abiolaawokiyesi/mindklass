# MindKlass: GitHub, Vercel and Supabase setup

Release in `dist/`: **2026.08.09.16** (the exact bundle from `mindklass-upload-2026.08.09.16.zip`).

## How this repo deploys

- `dist/` is the finished site. Vercel serves it as-is: no install, no build (`vercel.json`).
- `vercel.json` recreates the old `.htaccess` behaviour: single-page-app fallback to `index.html`, no-cache on `index.html` / `version.json` / manifest / service worker, 1-hour cache on JS/CSS, 30-day cache on images/audio, security headers. HTTPS is automatic on Vercel.
- To ship a change: edit/add a script in `patches/`, run `python3 build.py <new.version>`, commit the regenerated `dist/`, push. Vercel redeploys on every push to `main`.
- `.gitattributes` stops git from changing line endings in the bundle. Leave it alone.

## Supabase

Nothing to configure in the code. `dist/assets/app.js` already contains the project URL (`https://jozqiwlqektnvsbaqayt.supabase.co`) and the **publishable** key, which is safe to be public. No secret key is in this repo. Keep it that way; never commit the `service_role` key.

After the first Vercel deploy, in the Supabase dashboard go to **Authentication > URL Configuration**:
- Site URL: your production domain (e.g. `https://www.mindklass.com`)
- Redirect URLs: add `https://<your-project>.vercel.app/**` and `https://www.mindklass.com/**`

Without this, sign-in confirmation and password-reset links can send users to the wrong address.

## 1. Push to GitHub

Install Git first if needed (`winget install Git.Git`), then open a terminal in this folder.

```bash
git init -b main
git add .
git commit -m "MindKlass 2026.08.09.16: initial repo with baseline, patches and dist"
```

Create an empty private repo on github.com (no README), then:

```bash
git remote add origin https://github.com/<your-username>/mindklass.git
git push -u origin main
```

## 2. Connect Vercel

1. vercel.com > Add New > Project > Import the GitHub repo.
2. Framework Preset: **Other**. Leave Build Command and Install Command empty. Output Directory: `dist` (already set by `vercel.json`).
3. Deploy. Then Settings > Domains: add `www.mindklass.com` and follow the DNS instructions.

## 3. After go-live checks

- Open the site, hard-refresh, confirm no "new version available" banner (the version in `app.js`, `version.json` and the `?v=` tags must match).
- Log in / sign up once to confirm Supabase works from the new domain.
- Open `/careers/` and a deep link such as `/lifeskills`.

## Known follow-ups (from README)

- Firebase push is off (`FCM_ENABLED` false).
- Paystack payment confirmation has no server-side webhook yet.
- The app mentions a Node backend ("syskay") that needs `SUPABASE_SERVICE_ROLE_KEY`; that is not part of this repo. If you use it, host it separately and set that key only as a server-side environment variable.
