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

---

## Quick Start

Clone the repo first:

```bash
git clone https://github.com/krishnasHub/bot-example.git
cd bot-example
```

Then run the setup script for your platform. It will check for Node.js (installing it if needed), install all dependencies, prompt for your API key, and launch the app.

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

If you're not sure what PowerShell is, use this instead. Double-click `install.bat`, or run it from Command Prompt:

```cmd
install.bat
```

---

Once running, open **http://localhost:3000** in your browser.  
Press `Ctrl+C` in the terminal to stop — the script will automatically clean up the servers.

### Stopping the servers manually

If you need to stop the servers from a separate terminal:

| Platform | Command |
|----------|---------|
| Mac / Linux | `./stop.sh` |
| Windows PowerShell | `.\stop.ps1` |
| Windows Command Prompt | `stop.bat` |

---

## What the install script does

1. Checks if Node.js is installed — installs it automatically if not
2. Installs all project dependencies
3. Asks for your [Anthropic API key](https://console.anthropic.com) and saves it
4. Starts the app

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

3. Copy the example env file and add your API key:
   ```bash
   cp server/.env.example server/.env   # Mac/Linux
   copy server\.env.example server\.env  # Windows
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
- **API server:** http://localhost:3001
