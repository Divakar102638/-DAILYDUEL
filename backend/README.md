# DailyDuel backend

This standalone Node.js service uses Express and the official MongoDB Node.js
driver to verify connectivity to MongoDB Atlas. Flutter does not connect to
MongoDB directly. No application data migration or Flutter API integration is
included yet.

## Requirements

- Node.js 20 or newer and npm.
- A MongoDB Atlas cluster, database user, and network access rule allowing the
  machine running this backend to connect.

## Configure MongoDB Atlas securely

The connection string belongs only in `D:\DailyDuel\backend\.env`, not in
Flutter, source files, or a committed file. The Git ignore rules exclude this
file. Open `.env` in VS Code or Notepad and enter the connection URI shown by
**Atlas > Connect > Drivers > Node.js** on the `MONGODB_URI=` line. Do not use
a guessed hostname or share the URI in chat, screenshots, source files, or
logs. The committed `.env.example` contains no credentials or URI template.

The local file should contain:

```dotenv
HOST=127.0.0.1
PORT=3000
MONGODB_URI=<paste the actual Atlas URI locally, replacing this instruction>
```

Keep the angle-bracketed instruction out of `.env`; replace the entire value
with the URI copied directly from Atlas. If the password contains special
characters, make sure they are URL-encoded as directed by Atlas. If the URI
has ever been exposed, rotate the Atlas database-user password.

## Install and run

```powershell
Set-Location 'D:\DailyDuel\backend'
npm install
npm start
```

To test the Atlas connection without starting the API:

```powershell
Set-Location 'D:\DailyDuel\backend'
npm run db:check
```

The backend checks the MongoDB connection during startup and exits with a
credential-safe error if the connection cannot be established. Check the
hostname against Atlas, verify the database username and URL-encoded password,
confirm the machine's IP is allowed in Atlas Network Access, and ensure the
database user has the roles required by the application. The default
address is `http://127.0.0.1:3000`; set `HOST` or `PORT` in the local `.env` to
override it.

## Deploy on Render

The GitHub repository is a Flutter project at its root. Configure the Render
Web Service to use the backend subdirectory:

- **Root Directory:** `backend`
- **Build Command:** `npm ci`
- **Start Command:** `npm start`
- **Required environment variable:** `MONGODB_URI` (set its value privately in
  the Render dashboard using the URI from Atlas)
- **Port:** Render supplies `PORT` automatically.
- **Host:** The server defaults to `0.0.0.0` when `HOST` is not set. Do not set
  it to `127.0.0.1` in Render.

The backend loads `.env` from its own directory for local development; in
production, Render-provided environment variables take precedence. Commit and
push the backend files, including `package.json` and `package-lock.json`, and
the production host default before deploying. Do not commit `.env`; add
`MONGODB_URI` only in Render's environment settings.

## Verify

In a second PowerShell window:

```powershell
Invoke-RestMethod 'http://127.0.0.1:3000/health'
Invoke-RestMethod 'http://127.0.0.1:3000/health/database'
```

The database endpoint returns only the connection status, never the URI or
credentials. An unavailable database returns HTTP 503 with a generic status.

Run the backend tests with:

```powershell
Set-Location 'D:\DailyDuel\backend'
npm test
```
