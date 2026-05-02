#!/bin/bash
# OpenClaw + NVIDIA NIM API — Mac Setup Script

set -e

echo "=== OpenClaw Setup ==="

# Check Node.js
if ! command -v node &> /dev/null; then
    echo "ERROR: Node.js not found. Install it first: brew install node"
    exit 1
fi
echo "Node.js: $(node --version)"

# Install openclaw globally
echo ""
echo "Installing openclaw..."
npm install -g openclaw

# Create config directory
mkdir -p ~/.openclaw

# Copy config template if config doesn't exist
if [ -f ~/.openclaw/openclaw.json ]; then
    echo ""
    echo "Config already exists at ~/.openclaw/openclaw.json — skipping."
else
    cp config-template.json ~/.openclaw/openclaw.json
    echo ""
    echo "Config template copied to ~/.openclaw/openclaw.json"
    echo "IMPORTANT: Edit that file and replace all YOUR_* placeholders before starting."
fi

echo ""
echo "=== Done ==="
echo ""
echo "Next steps:"
echo "  1. Edit ~/.openclaw/openclaw.json and fill in your API keys"
echo "  2. Run: openclaw gateway start"
echo "  3. Run: openclaw gateway status"
