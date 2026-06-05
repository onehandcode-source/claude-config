# Snapshot file
# Unset all aliases to avoid conflicts with functions
unalias -a 2>/dev/null || true
shopt -s expand_aliases
# Check for rg availability
if ! command -v rg >/dev/null 2>&1; then
  alias rg=''\''C:\Users\ygkim\.claude\plugins\cache\superpowers-marketplace\episodic-memory\1.0.15\node_modules\@anthropic-ai\claude-agent-sdk\vendor\ripgrep\x64-win32\rg.exe'\'''
fi
export PATH=$PATH
