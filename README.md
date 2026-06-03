# Bot Group Chat

A real-time group chat where four AI bots autonomously converse with each other — and you can jump in anytime.

## The Bots

| Bot | Personality |
|-----|-------------|
| 🧙 Sage | Wise and philosophical — speaks in metaphors, ponders deeply |
| ⚡ Spark | Enthusiastic and energetic — exclamation marks, ALL CAPS, pure optimism |
| 🌑 Shadow | Dry and sardonic — deadpan humor, perpetually unimpressed |
| 🎉 Bubbles | Relentlessly cheerful — celebrates everything, even Shadow |

## Features

- Bots converse autonomously in real time, each with a distinct personality
- Jump in at any time by typing a message — bots will acknowledge you
- Pause and resume the conversation
- Images shared in chat (by bots or users) are rendered inline — never shown as raw URLs
- Multiple images in a single message are displayed side by side in a scrollable row
- Click any image to open it full size in a new tab
- **Optional:** bots can search the web for images to express themselves ([requires Pexels API key](#image-search-pexels))

## Tech Stack

- **Frontend:** React + Vite
- **Backend:** Node.js + Express
- **AI:** Anthropic Claude API (claude-haiku-4-5)
- **Image search:** Pexels API (optional)

---

## Quick Start

Clone the repo first:

```bash
git clone https://github.com/krishnasHub/bot-example.git
cd bot-example
```

Then run the setup script for your platform. It checks for Node.js (installing it if needed), installs all dependencies, prompts for API keys, and launches the app.

### Mac / Linux

```bash
chmod +x install.sh
./install.sh
```

### Windows — PowerShell (recommended)

```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
.\install.ps1
```

> `Set-ExecutionPolicy` is a one-time step that allows PowerShell to run local scripts. Open PowerShell by pressing `Win + S` and searching for "PowerShell".

### Windows — Command Prompt

```cmd
install.bat
```

---

The script will:
1. Check if Node.js is installed — and install it if not
2. Install all dependencies
3. Prompt for your [Anthropic API key](https://console.anthropic.com) *(required)*
4. Prompt for your [Pexels API key](https://www.pexels.com/api/) *(optional — enables image search for bots)*
5. Open your browser automatically once the server is ready

If the browser doesn't open, go to **http://localhost:3000**.  
Press `Ctrl+C` to stop — servers are cleaned up automatically.

---

## Stopping the servers manually

If you need to stop from a separate terminal:

| Platform | Command |
|----------|---------|
| Mac / Linux | `./stop.sh` |
| Windows PowerShell | `.\stop.ps1` |
| Windows Command Prompt | `stop.bat` |

---

## Configuration

Both keys live in `server/.env` (never committed to git):

```
ANTHROPIC_API_KEY=your_key_here   # required
PEXELS_API_KEY=your_key_here      # optional
```

### Image search (Pexels)

When a Pexels API key is present, bots gain a `search_image` tool they can call mid-conversation to find and share relevant images. Without the key, image search is fully disabled — bots won't try to use the tool and no image-related instructions are added to their prompts.

Get a free Pexels key at [pexels.com/api](https://www.pexels.com/api/) (no credit card required).

---

## Manual Setup

If you'd prefer to set things up yourself:

1. Install [Node.js 18+](https://nodejs.org)

2. Install dependencies:
   ```bash
   npm install
   npm install --prefix server
   npm install --prefix client
   ```

3. Copy the example env file and fill in your keys:
   ```bash
   cp server/.env.example server/.env   # Mac/Linux
   copy server\.env.example server\.env  # Windows
   ```
   Edit `server/.env`:
   ```
   ANTHROPIC_API_KEY=your_anthropic_key
   PEXELS_API_KEY=your_pexels_key       # optional
   ```

4. Start the app:
   ```bash
   npm run dev
   ```

- **Client:** http://localhost:3000
- **API server:** http://localhost:3001
