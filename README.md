# Project Setup

This repository is now split into a simple front–end and back–end.

## Structure

- **frontend/** — contains `index.html` and `game.html`.
- **backend/** — Node.js server serving the front–end.

## Backend Requirements

1. Install [Node.js](https://nodejs.org/) (version 16+ recommended).
2. From the `backend` folder run `npm install` to install dependencies.
3. Create a `.env` file in `backend` with the following variable:

```
PORT=3000
```

4. Start the server with `npm start`. The application will be served at `http://localhost:3000` by default.

The server exposes a simple health check at `/api/health` and serves all files from the `frontend` directory as static assets.

## Services

The backend uses the Express framework with the `dotenv` package for environment variable management. No database or external services are configured yet; further functionality (e.g., account system or leaderboard) can be added on top of this structure.
