# Snapshot file
# Unset all aliases to avoid conflicts with functions
unalias -a 2>/dev/null || true
shopt -s expand_aliases
# Check for rg availability
if ! (unalias rg 2>/dev/null; command -v rg) >/dev/null 2>&1; then
  function rg {
  local _cc_bin="${CLAUDE_CODE_EXECPATH:-}"
  [[ -x $_cc_bin ]] || _cc_bin=/c/Users/ygkim/.local/bin/claude.exe
  if [[ ! -x $_cc_bin ]]; then command rg "$@"; return; fi
  if [[ -n $ZSH_VERSION ]]; then
    ARGV0=rg "$_cc_bin" "$@"
  elif [[ "$OSTYPE" == "msys" ]] || [[ "$OSTYPE" == "cygwin" ]] || [[ "$OSTYPE" == "win32" ]]; then
    ARGV0=rg "$_cc_bin" "$@"
  elif [[ $BASHPID != $$ ]]; then
    exec -a rg "$_cc_bin" "$@"
  else
    (exec -a rg "$_cc_bin" "$@")
  fi
}
fi
export PATH='/c/Users/ygkim/Library/Python/3.9/bin:/c/Users/ygkim/bin:/mingw64/bin:/usr/local/bin:/usr/bin:/bin:/mingw64/bin:/usr/bin:/c/Users/ygkim/bin:/c/Users/ygkim/AppData/Roaming/Code/User/globalStorage/github.copilot-chat/debugCommand:/c/Users/ygkim/AppData/Roaming/Code/User/globalStorage/github.copilot-chat/copilotCli:/c/Users/ygkim/AppData/Local/Programs/Microsoft VS Code:/c/Program Files/Common Files/Oracle/Java/javapath:/c/Program Files (x86)/Common Files/Oracle/Java/java8path:/c/Program Files (x86)/Common Files/Oracle/Java/javapath:/c/Windows/system32:/c/Windows:/c/Windows/System32/Wbem:/c/Windows/System32/WindowsPowerShell/v1.0:/c/Windows/System32/OpenSSH:/c/Program Files/dotnet:/cmd:/c/Program Files/Bandizip:/c/Program Files/TortoiseSVN/bin:/c/Program Files/nodejs:/c/Program Files/RabbitMQ Server/rabbitmq_server-4.1.0/sbin:/c/Users/ygkim/AppData/Local/Programs/cursor/resources/app/bin:%JAVA_HOME/bin:/c/Program Files/Docker/Docker/resources/bin:/c/Program Files/RedHat/Podman:/d/01. workSpace/07. maven/apache-maven-3.9.11/bin:/c/Program Files/cursor/resources/app/bin:/c/Program Files (x86)/AOMEI/AOMEI Backupper/8.3.0:/c/Users/ygkim/AppData/Local/pnpm/bin:/c/Users/ygkim/AppData/Local/Programs/oh-my-posh/bin:/c/Users/ygkim/scoop/shims:/c/Users/ygkim/AppData/Local/Programs/Python/Launcher:/c/Users/ygkim/AppData/Local/Microsoft/WindowsApps:/c/Users/ygkim/AppData/Local/Programs/Microsoft VS Code/bin:/c/Users/ygkim/AppData/Roaming/npm:/c/Users/ygkim/AppData/Local/Programs/cursor/resources/app/bin:/c/Users/ygkim/AppData/Local/gitkraken/bin:/c/Users/ygkim/AppData/Local/Programs/Antigravity/bin:/c/Users/ygkim/AppData/Local/PowerToys/DSCModules:/c/Users/ygkim/AppData/Local/GitHubDesktop/bin:/c/Users/ygkim/AppData/Local/Packages/PythonSoftwareFoundation.Python.3.13_qbz5n2kfra8p0/LocalCache/local-packages/Python313/Scripts:/c/Users/ygkim/AppData/Local/Packages/PythonSoftwareFoundation.Python.3.13_qbz5n2kfra8p0/LocalCache/local-packages/Python313/Scripts:/usr/bin/vendor_perl:/usr/bin/core_perl:/c/Users/ygkim/.claude/plugins/cache/superpowers-marketplace/double-shot-latte/1.2.0/bin:/c/Users/ygkim/.claude/plugins/cache/superpowers-marketplace/superpowers/4.3.1/bin:/c/Users/ygkim/.claude/plugins/cache/claude-hud/claude-hud/0.0.10/bin:/c/Users/ygkim/.claude/plugins/cache/superpowers-marketplace/claude-session-driver/1.0.1/bin:/c/Users/ygkim/.claude/plugins/cache/superpowers-marketplace/episodic-memory/1.0.15/bin:/c/Users/ygkim/.claude/plugins/cache/claude-plugins-official/superpowers/5.0.6/bin:/c/Users/ygkim/.claude/plugins/cache/claude-plugins-official/context7/unknown/bin:/c/Users/ygkim/.claude/plugins/cache/claude-plugins-official/github/unknown/bin:/c/Users/ygkim/.claude/plugins/cache/claude-plugins-official/ralph-loop/1.0.0/bin:/c/Users/ygkim/.claude/plugins/cache/claude-plugins-official/claude-md-management/1.0.0/bin:/c/Users/ygkim/.claude/plugins/cache/claude-plugins-official/serena/unknown/bin:/c/Users/ygkim/.claude/plugins/cache/claude-plugins-official/frontend-design/unknown/bin:/c/Users/ygkim/.claude/plugins/cache/claude-plugins-official/code-simplifier/1.0.0/bin:/c/Users/ygkim/.claude/plugins/cache/claude-dashboard/claude-dashboard/1.26.0/bin:/c/Users/ygkim/.claude/plugins/cache/openai-codex/codex/1.0.4/bin:/c/Users/ygkim/.claude/plugins/cache/everything-claude-code/everything-claude-code/2.0.0-rc.1/bin:/c/Users/ygkim/.claude/plugins/cache/claude-plugins-official/playwright/unknown/bin:/c/Users/ygkim/.claude/plugins/cache/fe-review-agents/fe-review-agents/0.6.0/bin:/c/Users/ygkim/.claude/plugins/cache/omc/oh-my-claudecode/4.13.7/bin'
