#!/bin/bash
# ZoneWise Agent Teams — One-Shot Deploy
# Installs skill + commands globally for Claude Code
# Run from the zonewise-agent-teams directory:
#   bash deploy.sh
#
# For Claude Code execution:
#   cd ~/zonewise-agent-teams && bash deploy.sh

set -e

echo "================================================"
echo "  ZoneWise Agent Teams — Deploying..."
echo "================================================"

# Ensure directories exist
mkdir -p ~/.claude/skills/build-with-agent-team
mkdir -p ~/.claude/commands

# Install main skill
cp skill/SKILL.md ~/.claude/skills/build-with-agent-team/SKILL.md
echo "✅ Installed: ~/.claude/skills/build-with-agent-team/SKILL.md"

# Install commands
cp commands/build-county-scraper.md ~/.claude/commands/build-county-scraper.md
echo "✅ Installed: ~/.claude/commands/build-county-scraper.md"

# Enable Agent Teams in settings.json
SETTINGS_FILE="$HOME/.claude/settings.json"

if [ -f "$SETTINGS_FILE" ]; then
    # Check if already has the setting
    if grep -q "CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS" "$SETTINGS_FILE"; then
        echo "✅ Agent Teams already enabled in settings.json"
    else
        # Use python to safely merge into existing JSON
        python3 -c "
import json
with open('$SETTINGS_FILE', 'r') as f:
    data = json.load(f)
if 'env' not in data:
    data['env'] = {}
data['env']['CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS'] = '1'
with open('$SETTINGS_FILE', 'w') as f:
    json.dump(data, f, indent=2)
print('✅ Agent Teams enabled in settings.json')
"
    fi
else
    # Create new settings.json
    cat > "$SETTINGS_FILE" << 'EOF'
{
  "env": {
    "CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS": "1"
  }
}
EOF
    echo "✅ Created settings.json with Agent Teams enabled"
fi

# Install tmux if not present
if ! command -v tmux &> /dev/null; then
    echo "📦 Installing tmux..."
    if command -v apt &> /dev/null; then
        sudo apt update -qq && sudo apt install -y tmux
    elif command -v brew &> /dev/null; then
        brew install tmux
    elif command -v dnf &> /dev/null; then
        sudo dnf install -y tmux
    else
        echo "⚠️  Could not auto-install tmux. Install manually."
    fi
fi

if command -v tmux &> /dev/null; then
    echo "✅ tmux: $(tmux -V)"
fi

# Also export for current session
export CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1

# Copy example plans for reference
mkdir -p ~/zonewise-plans
cp example-plans/*.md ~/zonewise-plans/ 2>/dev/null || true
echo "✅ Example plans copied to ~/zonewise-plans/"

echo ""
echo "================================================"
echo "  Deployment complete!"
echo "================================================"
echo ""
echo "Available commands in Claude Code:"
echo "  /build-with-agent-team [plan.md] [num-agents]"
echo "  /build-county-scraper [county-name] [url]"
echo ""
echo "Quick test:"
echo "  /build-county-scraper orange"
echo ""
echo "Validate installation:"
echo "  bash tests/validate-skill-install.sh"
echo ""
