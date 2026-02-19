#!/usr/bin/env bash
# SKForge Installer
# curl -fsSL https://skforge.io/install.sh | sh
#
# Don't use software. Forge your own. 🐧
# S&K Holdings — Helping architect our quantum future, one smile at a time.

set -euo pipefail

REPO="smilinTux/skforge"
INSTALL_DIR="${FORGE_HOME:-$HOME/.skforge}"
BIN_DIR="${FORGE_BIN:-/usr/local/bin}"

RED='\033[0;31m'
GREEN='\033[0;32m'
CYAN='\033[0;36m'
YELLOW='\033[1;33m'
BOLD='\033[1m'
DIM='\033[2m'
NC='\033[0m'

cat << 'PENGUIN'

    ██████╗ ██████╗ ██████╗  ██████╗ ███████╗██████╗ ██████╗ ██╗███╗   ██╗████████╗
    ██╔══██╗██╔══██╗██╔══██╗██╔════╝ ██╔════╝██╔══██╗██╔══██╗██║████╗  ██║╚══██╔══╝
    ██████╔╝██████╔╝██████╔╝██║  ███╗█████╗  ██████╔╝██████╔╝██║██╔██╗ ██║   ██║   
    ██╔═══╝ ██╔══██╗██╔══██╗██║   ██║██╔══╝  ██╔═══╝ ██╔══██╗██║██║╚██╗██║   ██║   
    ██║     ██║  ██║██║  ██║╚██████╔╝███████╗██║     ██║  ██║██║██║ ╚████║   ██║   
    ╚═╝     ╚═╝  ╚═╝╚═╝  ╚═╝ ╚═════╝ ╚══════╝╚═╝     ╚═╝  ╚═╝╚═╝╚═╝  ╚═══╝   ╚═╝   

    🐧 Don't use software. Forge your own.
    Making Self-Hosting & Decentralized Systems Cool Again

PENGUIN

echo -e "${BOLD}Installing SKForge...${NC}\n"

# Check dependencies
echo -e "  Checking dependencies..."

for cmd in git curl bash python3; do
  if command -v "$cmd" &>/dev/null; then
    echo -e "  ${GREEN}✓${NC} $cmd"
  else
    echo -e "  ${RED}✗${NC} $cmd — required but not found"
    echo -e "  ${DIM}Please install $cmd and try again${NC}"
    exit 1
  fi
done

# Clone or update blueprints
echo -e "\n  Downloading blueprints..."
mkdir -p "$INSTALL_DIR"

if [[ -d "$INSTALL_DIR/blueprints/.git" ]]; then
  cd "$INSTALL_DIR/blueprints"
  git pull --quiet
  echo -e "  ${GREEN}✓${NC} Blueprints updated"
else
  rm -rf "$INSTALL_DIR/blueprints"
  git clone --quiet --depth 1 "https://github.com/$REPO.git" "$INSTALL_DIR/blueprints"
  echo -e "  ${GREEN}✓${NC} Blueprints downloaded"
fi

# Install CLI
echo -e "\n  Installing forge CLI..."

# Copy the CLI script
cp "$INSTALL_DIR/blueprints/cli/forge" "$INSTALL_DIR/forge"
chmod +x "$INSTALL_DIR/forge"

# Try to symlink to PATH
if [[ -w "$BIN_DIR" ]]; then
  ln -sf "$INSTALL_DIR/forge" "$BIN_DIR/forge"
  echo -e "  ${GREEN}✓${NC} Installed to $BIN_DIR/forge"
elif command -v sudo &>/dev/null; then
  echo -e "  ${YELLOW}Need sudo to install to $BIN_DIR${NC}"
  sudo ln -sf "$INSTALL_DIR/forge" "$BIN_DIR/forge"
  echo -e "  ${GREEN}✓${NC} Installed to $BIN_DIR/forge"
else
  # Fallback: add to PATH via shell config
  echo -e "  ${YELLOW}Can't write to $BIN_DIR. Adding to PATH...${NC}"
  
  local shell_rc=""
  if [[ -f "$HOME/.zshrc" ]]; then
    shell_rc="$HOME/.zshrc"
  elif [[ -f "$HOME/.bashrc" ]]; then
    shell_rc="$HOME/.bashrc"
  fi
  
  if [[ -n "$shell_rc" ]]; then
    echo "export PATH=\"$INSTALL_DIR:\$PATH\"" >> "$shell_rc"
    echo -e "  ${GREEN}✓${NC} Added to PATH in $shell_rc"
    echo -e "  ${YELLOW}Run: source $shell_rc${NC}"
  else
    echo -e "  ${YELLOW}Add this to your shell config:${NC}"
    echo -e "  export PATH=\"$INSTALL_DIR:\$PATH\""
  fi
fi

# Count blueprints
bp_count=$(find "$INSTALL_DIR/blueprints/blueprints" -maxdepth 1 -type d 2>/dev/null | wc -l)
bp_count=$((bp_count - 1))

echo -e "\n${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}  ✅ SKForge installed successfully!${NC}"
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e ""
echo -e "  📦 ${BOLD}$bp_count blueprint categories${NC} available"
echo -e "  📂 Installed to: $INSTALL_DIR"
echo -e ""
echo -e "  ${BOLD}Quick start:${NC}"
echo -e "    ${CYAN}forge list${NC}          Browse blueprints"
echo -e "    ${CYAN}forge init${NC}          Interactive setup wizard"
echo -e "    ${CYAN}forge doctor${NC}        Check your AI providers"
echo -e ""
echo -e "  ${BOLD}Links:${NC}"
echo -e "    Website:  ${CYAN}https://skforge.io${NC}"
echo -e "    GitHub:   ${CYAN}https://github.com/$REPO${NC}"
echo -e "    Discord:  ${CYAN}https://discord.gg/skforge${NC}"
echo -e ""
echo -e "  ${DIM}S&K Holdings — Helping architect our quantum future, one smile at a time.${NC}"
echo -e "  ${DIM}Making Self-Hosting & Decentralized Systems Cool Again 🐧${NC}"
