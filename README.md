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

## Quick Start

Clone the repo, then run the setup script for your platform. It will install everything automatically and launch the app.

### Mac / Linux

```bash
git clone https://github.com/krishnasHub/bot-example.git
cd bot-example
chmod +x install.sh
./install.sh
```

### Windows

Open **PowerShell** and run:

```powershell
git clone https://github.com/krishnasHub/bot-example.git
cd bot-example
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
.\install.ps1
```

> The `Set-ExecutionPolicy` line is a one-time step that allows PowerShell to run local scripts.

The script will:
1. Check if Node.js is installed — and install it if not
2. Install all dependencies
3. Prompt you for your [Anthropic API key](https://console.anthropic.com)
4. Start the app

Once running, open **http://localhost:3000** in your browser.

## Manual Setup

If you'd prefer to set things up yourself:

1. Install [Node.js 18+](https://nodejs.org)

2. Install dependencies:
   ```bash
   npm install
   npm install --prefix server
   npm install --prefix client
   ```

3. Copy the example env file and add your API key:
   ```bash
   cp server/.env.example server/.env
   ```
   Edit `server/.env`:
   ```
   ANTHROPIC_API_KEY=your_api_key_here
   ```

4. Start the app:
   ```bash
   npm run dev
   ```

- **Client:** http://localhost:3000
- **API:** http://localhost:3001
