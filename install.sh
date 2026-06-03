#!/bin/bash

# ─────────────────────────────────────────
#   Bot Group Chat — Setup Script (Mac/Linux)
# ─────────────────────────────────────────

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
CYAN='\033[0;36m'
NC='\033[0m'

step()  { echo -e "${GREEN}[+]${NC} $1"; }
warn()  { echo -e "${YELLOW}[!]${NC} $1"; }
error() { echo -e "${RED}[x]${NC} $1"; }
info()  { echo -e "${CYAN}    $1${NC}"; }

echo ""
echo -e "${CYAN}╔══════════════════════════════════════╗${NC}"
echo -e "${CYAN}║     Bot Group Chat — Setup Script    ║${NC}"
echo -e "${CYAN}╚══════════════════════════════════════╝${NC}"
echo ""

# ── Step 1: Node.js ───────────────────────
step "Checking for Node.js..."

if command -v node &>/dev/null; then
    step "Node.js already installed: $(node --version)"
else
    warn "Node.js not found. Installing now..."

    if [[ "$OSTYPE" == "darwin"* ]]; then
        if ! command -v brew &>/dev/null; then
            step "Installing Homebrew (package manager for Mac)..."
            /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
            # Add brew to PATH for Apple Silicon Macs
            if [[ -f /opt/homebrew/bin/brew ]]; then
                eval "$(/opt/homebrew/bin/brew shellenv)"
            fi
        fi
        step "Installing Node.js via Homebrew..."
        brew install node
    else
        step "Installing Node.js via nvm..."
        curl -fsSL https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash
        export NVM_DIR="$HOME/.nvm"
        [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
        nvm install --lts
        nvm use --lts
    fi

    step "Node.js installed: $(node --version)"
fi

# ── Step 2: Dependencies ──────────────────
echo ""
step "Installing root dependencies..."
npm install --silent

step "Installing server dependencies..."
npm install --prefix server --silent

step "Installing client dependencies..."
npm install --prefix client --silent

step "All dependencies installed."

# ── Step 3: API Key ───────────────────────
echo ""
step "Checking API key setup..."

NEEDS_KEY=true
if [ -f "server/.env" ] && ! grep -q "your_api_key_here" "server/.env" 2>/dev/null; then
    step "API key already configured."
    NEEDS_KEY=false
fi

if [ "$NEEDS_KEY" = true ]; then
    warn "An Anthropic API key is required to run the bots."
    info "Get your free key at: https://console.anthropic.com"
    echo ""
    read -p "    Enter your Anthropic API key: " api_key

    if [ -z "$api_key" ]; then
        warn "No key entered. You can add it later by editing server/.env"
        cp server/.env.example server/.env
    else
        sed "s|your_api_key_here|$api_key|" server/.env.example > server/.env
        step "API key saved to server/.env"
    fi
fi

# ── Step 3b: Image Search (optional) ─────
echo ""
step "Image search setup (optional - lets bots find and share images)..."
echo ""
echo -e "${CYAN}  Which image search provider would you like to use?${NC}"
echo "    1) Pexels  - curated stock photos, 1 key    (pexels.com/api)"
echo "    2) Google  - broader web results, 2 keys    (console.cloud.google.com)"
echo "    3) None    - disable image search"
echo ""
read -p "    Enter 1, 2, or 3: " img_choice

# Strip any existing image search keys before writing new ones
tmpfile=$(mktemp)
grep -v "^PEXELS_API_KEY=\|^GOOGLE_API_KEY=\|^GOOGLE_CX=" server/.env > "$tmpfile" 2>/dev/null
mv "$tmpfile" server/.env

case "$img_choice" in
    1)
        read -p "    Enter your Pexels API key: " pexels_key
        if [ -n "$pexels_key" ]; then
            echo "PEXELS_API_KEY=$pexels_key" >> server/.env
            step "Pexels API key saved."
        fi
        ;;
    2)
        info "1. Go to programmablesearchengine.google.com and create a search engine"
        info "2. Enable 'Image search' in its settings and copy the Search Engine ID"
        info "3. Get an API key from console.cloud.google.com (enable Custom Search API)"
        echo ""
        read -p "    Enter your Google API key: " google_key
        read -p "    Enter your Search Engine ID (cx): " google_cx
        if [ -n "$google_key" ] && [ -n "$google_cx" ]; then
            echo "GOOGLE_API_KEY=$google_key" >> server/.env
            echo "GOOGLE_CX=$google_cx" >> server/.env
            step "Google Custom Search keys saved."
        fi
        ;;
    *)
        step "Image search disabled."
        ;;
esac

# ── Step 4: Free ports ───────────────────
step "Checking for processes on ports 3000 and 3001..."
for port in 3000 3001; do
    pid=$(lsof -ti tcp:$port 2>/dev/null)
    if [ -n "$pid" ]; then
        kill -9 $pid 2>/dev/null
    fi
done
step "Ports cleared."

# ── Step 5: Launch ────────────────────────
echo ""
echo -e "${CYAN}╔══════════════════════════════════════╗${NC}"
echo -e "${CYAN}║         Setup complete! Launching    ║${NC}"
echo -e "${CYAN}╚══════════════════════════════════════╝${NC}"
echo ""
step "Starting server...  http://localhost:3001"
step "Starting client...  http://localhost:3000"
echo ""
info "Opening your browser automatically once the server is ready..."
info "If it does not open, go to: http://localhost:3000"
info "Press Ctrl+C to stop."
echo ""

# Poll in background until the server responds, then open the browser
(
    for i in $(seq 1 30); do
        sleep 0.5
        if curl -s http://localhost:3001/api/bots >/dev/null 2>&1; then
            if [[ "$OSTYPE" == "darwin"* ]]; then
                open "http://localhost:3000"
            else
                xdg-open "http://localhost:3000" 2>/dev/null || true
            fi
            break
        fi
    done
) &

cleanup() {
    echo ""
    step "Shutting down servers..."
    for port in 3000 3001; do
        pid=$(lsof -ti tcp:$port 2>/dev/null)
        [ -n "$pid" ] && kill $pid 2>/dev/null
    done
    step "Servers stopped. Goodbye!"
    exit 0
}
trap cleanup INT TERM

npm run dev
