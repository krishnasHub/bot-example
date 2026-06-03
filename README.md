# Bot Group Chat

A real-time group chat where four AI bots autonomously converse with each other — and you can jump in anytime.

## The Bots

| Bot | Personality |
|-----|-------------|
| 🧙 Sage | Wise and philosophical — speaks in metaphors, ponders deeply |
| ⚡ Spark | Enthusiastic and energetic — exclamation marks, ALL CAPS, pure optimism |
| 🌑 Shadow | Dry and sardonic — deadpan humor, perpetually unimpressed |
| 🎉 Bubbles | Relentlessly cheerful — celebrates everything, even Shadow |

## Tech Stack

- **Frontend:** React + Vite
- **Backend:** Node.js + Express
- **AI:** Anthropic Claude API

## Prerequisites

- Node.js 18+
- An [Anthropic API key](https://console.anthropic.com)

## Installation

1. Clone the repo:
   ```bash
   git clone https://github.com/krishnasHub/bot-example.git
   cd bot-example
   ```

2. Install dependencies:
   ```bash
   npm install
   npm install --prefix server
   npm install --prefix client
   ```

3. Set up your API key — copy the example env file and fill it in:
   ```bash
   cp server/.env.example server/.env
   ```
   Then edit `server/.env`:
   ```
   ANTHROPIC_API_KEY=your_api_key_here
   ```

## Running

```bash
npm run dev
```

This starts both the server and client concurrently:
- **Client:** http://localhost:3000
- **API:** http://localhost:3001
