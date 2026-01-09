#!/bin/bash

# OpenCode OAuth Fix Setup Script
# https://github.com/fivetaku/opencode-oauth-fix
#
# Features:
# - Multi-layered bypass (Method 1: PascalCase, Method 2: TTL-based random)
# - TTL-based cache optimization (1 hour suffix reuse)

set -e

echo "=================================="
echo "  OpenCode OAuth Fix Installer"
echo "=================================="
echo ""

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check for Bun
if ! command -v bun &> /dev/null; then
    echo -e "${YELLOW}Bun not found. Installing...${NC}"
    curl -fsSL https://bun.sh/install | bash
    source ~/.bashrc 2>/dev/null || source ~/.zshrc 2>/dev/null || true
fi

# Get username
USERNAME=$(whoami)
PATCH_DIR="$HOME/Developer/opencode-patch"

echo -e "${GREEN}[1/6]${NC} Creating patch directory..."
mkdir -p "$PATCH_DIR"
cd "$PATCH_DIR"

# Clone or update plugin (using fivetaku fork with TTL optimization)
echo -e "${GREEN}[2/6]${NC} Setting up opencode-anthropic-auth plugin (TTL optimized)..."
if [ -d "opencode-anthropic-auth" ]; then
    echo "  Plugin directory exists, updating..."
    cd opencode-anthropic-auth
    git fetch origin pr-13 2>/dev/null || true
    git checkout pr-13
    git pull origin pr-13 2>/dev/null || true
    bun install
    cd ..
else
    git clone -b pr-13 https://github.com/fivetaku/opencode-anthropic-auth.git
    cd opencode-anthropic-auth
    bun install
    cd ..
fi

# Clone or update OpenCode
echo -e "${GREEN}[3/6]${NC} Setting up OpenCode..."
if [ -d "opencode" ]; then
    echo "  OpenCode directory exists, updating..."
    cd opencode
    git pull origin dev 2>/dev/null || true
    bun install
else
    git clone https://github.com/anomalyco/opencode.git
    cd opencode
    bun install
fi

# Update plugin path
echo -e "${GREEN}[4/6]${NC} Configuring plugin path..."
PLUGIN_FILE="packages/opencode/src/plugin/index.ts"
PLUGIN_PATH="file:///Users/$USERNAME/Developer/opencode-patch/opencode-anthropic-auth/index.mjs"

if grep -q "opencode-anthropic-auth@" "$PLUGIN_FILE"; then
    # Replace existing anthropic auth plugin reference
    if [[ "$OSTYPE" == "darwin"* ]]; then
        sed -i '' "s|\"opencode-anthropic-auth@[^\"]*\"|\"$PLUGIN_PATH\"|g" "$PLUGIN_FILE"
    else
        sed -i "s|\"opencode-anthropic-auth@[^\"]*\"|\"$PLUGIN_PATH\"|g" "$PLUGIN_FILE"
    fi
    echo "  Updated existing plugin path"
elif grep -q "opencode-anthropic-auth/index.mjs" "$PLUGIN_FILE"; then
    # Already using local path, update it
    if [[ "$OSTYPE" == "darwin"* ]]; then
        sed -i '' "s|file:///Users/[^/]*/Developer/opencode-patch/opencode-anthropic-auth/index.mjs|$PLUGIN_PATH|g" "$PLUGIN_FILE"
    else
        sed -i "s|file:///Users/[^/]*/Developer/opencode-patch/opencode-anthropic-auth/index.mjs|$PLUGIN_PATH|g" "$PLUGIN_FILE"
    fi
    echo "  Updated local plugin path"
else
    echo -e "${YELLOW}  Warning: Could not find plugin reference in $PLUGIN_FILE${NC}"
    echo "  You may need to manually update the plugin path."
fi

# Build OpenCode
echo -e "${GREEN}[5/6]${NC} Building OpenCode (this may take a minute)..."
cd packages/opencode
bun run build -- --single

# Setup PATH
echo -e "${GREEN}[6/6]${NC} Setting up PATH..."
OPENCODE_BIN="$PATCH_DIR/opencode/packages/opencode/dist/opencode-darwin-arm64/bin"
PATH_EXPORT="export PATH=\"$OPENCODE_BIN:\$PATH\""

# Detect shell config file
if [ -f "$HOME/.zshrc" ]; then
    SHELL_RC="$HOME/.zshrc"
elif [ -f "$HOME/.bashrc" ]; then
    SHELL_RC="$HOME/.bashrc"
else
    SHELL_RC="$HOME/.profile"
fi

# Add to PATH if not already present
if ! grep -q "opencode-patch/opencode/packages/opencode/dist" "$SHELL_RC" 2>/dev/null; then
    echo "" >> "$SHELL_RC"
    echo "# OpenCode OAuth Fix" >> "$SHELL_RC"
    echo "$PATH_EXPORT" >> "$SHELL_RC"
    echo "  Added to $SHELL_RC"
else
    echo "  PATH already configured in $SHELL_RC"
fi

# Apply PATH for current session
export PATH="$OPENCODE_BIN:$PATH"

echo ""
echo "=================================="
echo -e "${GREEN}  Installation Complete!${NC}"
echo "=================================="
echo ""
echo "Features:"
echo "  - Multi-layered bypass (Method 1 + 2)"
echo "  - TTL-based cache optimization (1hr)"
echo ""
echo "To apply changes to your current terminal:"
echo -e "  ${YELLOW}source $SHELL_RC${NC}"
echo ""
echo "Or open a new terminal window."
echo ""
echo "Verify installation:"
echo -e "  ${YELLOW}opencode --version${NC}"
echo ""
echo "Start OpenCode:"
echo -e "  ${YELLOW}opencode${NC}"
echo ""
echo "If Method 1 is blocked, use Method 2:"
echo -e "  ${YELLOW}export OPENCODE_USE_RANDOMIZED_TOOLS=true${NC}"
echo -e "  ${YELLOW}opencode${NC}"
echo ""
