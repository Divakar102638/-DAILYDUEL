# DailyDuel Admin

A separate React, Vite, and TypeScript website for DailyDuel administrators.
It uses the existing Express API and has its own dependencies; Flutter and
backend package manifests remain separate.

## Local setup

Requirements: Node.js 20.19 or newer and npm.

```powershell
Set-Location 'D:\DailyDuel\admin-web'
npm install
if (-not (Test-Path .env.local)) { Copy-Item .env.example .env.local }
npm run dev
```

Open `http://localhost:5173`. The existing backend uses port `3000` by
default; the browser API base URL is configured in `.env.local`:

```dotenv
VITE_API_BASE_URL=http://localhost:3000
```

For browser requests, the backend must allow the exact local web origin. Add
this to the existing **local** `D:\DailyDuel\backend\.env` file (do not put it
in a production environment for local development). If `CORS_ORIGINS` already
exists, append the origin to its comma-separated value instead of adding a
duplicate variable:

```dotenv
CORS_ORIGINS=http://localhost:5173
```

Restart the local backend after changing its local configuration. The admin
portal uses the existing local API and never connects directly to MongoDB.
No credentials or API tokens belong in `VITE_` variables.

Sign in with an existing administrator account. The website first verifies
the login token through `GET /api/v1/auth/session` and
`GET /api/v1/admin/access`. Tokens are held in `sessionStorage` for the
current browser tab to remain compatible with the existing bearer-token API.
This is not equivalent to an HttpOnly cookie; protect the portal from XSS and
serve it only over HTTPS outside local development. The backend remains the
authorization boundary for every administrator operation.

## Included workspace

- Overview with live backend counts.
- Exam listing, safe metadata editing, scheduling, and pre-participation
  archive.
- Question draft creation/editing, review/publishing, archive, and validated
  JSON batch import.
- Category configuration.
- Published exam rankings and results.
- Paginated student directory using the existing users collection.
- Administrator account details and logout.

The backend rejects exam edits/archives once attempts exist. Published
questions are immutable; archive them and create a replacement instead.
Question bulk import creates drafts and returns per-item duplicate and
validation outcomes. Correct answers appear only in authenticated,
administrator-only question management APIs; student question APIs continue
to omit them.

Some data/operations are not available in the existing backend and are not
fabricated by the dashboard: negative marking, passing thresholds, exam
deletion, payout workflows, and answer-by-answer competitive review. Results
are only visible after the backend publishes them.

## Checks

```powershell
npm test
npm run lint
npm run build
```

## Separate deployment preparation

The website can be built as a static site using `npm run build`; publish the
generated `dist` directory on a static host. Production builds default to
`https://dailyduel.onrender.com`; set the admin host's build-time
`VITE_API_BASE_URL` to that value as well, replacing any previous
`http://localhost:3000` setting. In the backend hosting dashboard, include the
exact admin website origin in `CORS_ORIGINS` (scheme and host only, no path or
trailing slash), preserving any other required origins. Redeploy/restart the
backend after updating its environment, then build and redeploy the admin
site. Do not put secrets in browser environment variables.
