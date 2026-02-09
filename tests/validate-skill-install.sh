#!/bin/bash
# ZoneWise Agent Teams — Installation Validator
# Run this after installation to verify everything works
# Usage: bash validate-skill-install.sh

set -e

echo "=========================================="
echo "  ZoneWise Agent Teams — Install Check"
echo "=========================================="
echo ""

PASS=0
FAIL=0
WARN=0

check_pass() { echo "  ✅ $1"; ((PASS++)); }
check_fail() { echo "  ❌ $1"; ((FAIL++)); }
check_warn() { echo "  ⚠️  $1"; ((WARN++)); }

# 1. Check tmux
echo "1. Checking tmux..."
if command -v tmux &> /dev/null; then
    VERSION=$(tmux -V 2>/dev/null || echo "unknown")
    check_pass "tmux installed ($VERSION)"
else
    check_fail "tmux not installed — run: sudo apt install tmux"
fi

# 2. Check Claude Code
echo "2. Checking Claude Code..."
if command -v claude &> /dev/null; then
    VERSION=$(claude --version 2>/dev/null | head -1 || echo "unknown")
    check_pass "Claude Code installed ($VERSION)"
else
    check_fail "Claude Code not found — install from https://docs.anthropic.com/en/docs/claude-code"
fi

# 3. Check Agent Teams env var
echo "3. Checking Agent Teams flag..."
if [ "$CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS" = "1" ] || [ "$CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS" = "true" ]; then
    check_pass "CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS is set"
else
    # Check settings.json
    SETTINGS_FILE="$HOME/.claude/settings.json"
    if [ -f "$SETTINGS_FILE" ] && grep -q "CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS" "$SETTINGS_FILE"; then
        check_pass "Agent Teams enabled in settings.json"
    else
        check_fail "Agent Teams not enabled — set env var or add to settings.json"
    fi
fi

# 4. Check skill installation
echo "4. Checking skill installation..."
GLOBAL_SKILL="$HOME/.claude/skills/build-with-agent-team/SKILL.md"
LOCAL_SKILL=".claude/skills/build-with-agent-team/SKILL.md"

if [ -f "$GLOBAL_SKILL" ]; then
    check_pass "Skill installed globally ($GLOBAL_SKILL)"
elif [ -f "$LOCAL_SKILL" ]; then
    check_pass "Skill installed locally ($LOCAL_SKILL)"
else
    check_fail "Skill not found — copy SKILL.md to ~/.claude/skills/build-with-agent-team/"
fi

# 5. Check command installation
echo "5. Checking commands..."
GLOBAL_CMD="$HOME/.claude/commands/build-county-scraper.md"
LOCAL_CMD=".claude/commands/build-county-scraper.md"

if [ -f "$GLOBAL_CMD" ]; then
    check_pass "build-county-scraper command installed globally"
elif [ -f "$LOCAL_CMD" ]; then
    check_pass "build-county-scraper command installed locally"
else
    check_warn "build-county-scraper command not found — optional but recommended"
fi

# 6. Check WSL (Windows only)
echo "6. Checking environment..."
if grep -qi microsoft /proc/version 2>/dev/null; then
    check_pass "Running in WSL (required for Windows)"
elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
    check_pass "Running on Linux"
elif [[ "$OSTYPE" == "darwin"* ]]; then
    check_pass "Running on macOS"
else
    check_warn "Unknown OS — may need adjustments"
fi

# 7. Check Python (for scrapers)
echo "7. Checking Python..."
if command -v python3 &> /dev/null; then
    PY_VERSION=$(python3 --version 2>&1)
    check_pass "Python installed ($PY_VERSION)"
else
    check_fail "Python3 not found — required for scraper builds"
fi

# 8. Check Git
echo "8. Checking Git..."
if command -v git &> /dev/null; then
    GIT_VERSION=$(git --version 2>&1)
    check_pass "Git installed ($GIT_VERSION)"
else
    check_fail "Git not found"
fi

# Summary
echo ""
echo "=========================================="
echo "  Results: $PASS passed, $FAIL failed, $WARN warnings"
echo "=========================================="

if [ $FAIL -gt 0 ]; then
    echo ""
    echo "Fix the failures above before using Agent Teams."
    exit 1
else
    echo ""
    echo "Ready to go! Try:"
    echo "  /build-county-scraper orange"
    echo ""
    exit 0
fi
