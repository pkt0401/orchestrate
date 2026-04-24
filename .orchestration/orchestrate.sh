#!/bin/bash
# B:Essential Multi-Agent Orchestration System v8 (Final)
# 
# Architecture:
#   - Each agent runs in a separate tmux session named by Agent ID
#   - iTerm windows attach to tmux sessions for visual monitoring
#   - Communication via: tmux send-keys -t {ID} "message" && tmux send-keys -t {ID} Enter
#
# Agent Registry:
#   10=MIR (Master), 11=WebScraper, 12=CodeAnalyzer
#   20=ROY (Master), 21=TestWriter, 22=Debugger
#   30=CLAUDE (Claude Code — real file edits, refactoring, debugging)

# Auto-detect workspace directory (where this script is located)
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
WORKSPACE="$(dirname "$SCRIPT_DIR")"
AGENTS_DIR="$SCRIPT_DIR/agents"

# iTerm profile - change this to your iTerm profile name, or use "Default"
ITERM_PROFILE="${ITERM_PROFILE:-Default}"

# Check prerequisites
check_prerequisites() {
    local missing=()
    
    if ! command -v tmux &> /dev/null; then
        missing+=("tmux (brew install tmux)")
    fi
    
    if ! command -v gemini &> /dev/null; then
        missing+=("gemini CLI (npm install -g @google/gemini-cli)")
    fi

    if ! command -v claude &> /dev/null; then
        missing+=("claude CLI (npm install -g @anthropic-ai/claude-code)")
    fi

    if [[ ${#missing[@]} -gt 0 ]]; then
        echo "⚠️  Missing prerequisites:"
        for item in "${missing[@]}"; do
            echo "   - $item"
        done
        echo ""
        echo "Please install the missing tools and try again."
        exit 1
    fi
}

create_agent_dirs() {
    echo "Creating agent directories if not exist..."
    mkdir -p "$AGENTS_DIR"/{10-mir,11-webscraper,12-codeanalyzer,20-roy,21-testwriter,22-debugger,30-claude}
}

create_tmux_sessions() {
    echo "Creating tmux sessions for all agents..."
    
    # Agent configurations: ID:DIR:NAME:CLI
    local agents=(
        "10:10-mir:MIR Master Agent:gemini"
        "11:11-webscraper:WebScraper:gemini"
        "12:12-codeanalyzer:CodeAnalyzer:gemini"
        "20:20-roy:ROY Master Agent:gemini"
        "21:21-testwriter:TestWriter:gemini"
        "22:22-debugger:Debugger:gemini"
        "30:30-claude:CLAUDE Code Agent:claude --dangerously-skip-permissions"
    )

    for agent in "${agents[@]}"; do
        IFS=':' read -r id dir_name display_name cli <<< "$agent"

        # Kill existing session if exists
        tmux kill-session -t "$id" 2>/dev/null

        # Create new session with correct working directory
        tmux new-session -d -s "$id" -c "$AGENTS_DIR/$dir_name"
        tmux send-keys -t "$id" "clear && echo '[$id] $display_name' && echo -n 'Path: ' && pwd && echo '' && $cli" Enter

        echo "  [$id] $display_name ($cli)"
    done

    echo "All 7 tmux sessions created!"
}

open_iterm_windows() {
    # WSL2/Linux: iTerm2 unavailable. Create a tmux 'view' session with 6 windows.
    echo "Opening tmux view session (WSL2 mode)..."

    tmux kill-session -t orchestra 2>/dev/null

    # Create view session: 6 windows, each attaching to an agent session
    tmux new-session -d -s orchestra -n "10-MIR"
    tmux send-keys -t orchestra:10-MIR "tmux attach -t 10" Enter

    for entry in "11-WebScraper 11" "12-CodeAnalyzer 12" "20-ROY 20" "21-TestWriter 21" "22-Debugger 22" "30-CLAUDE 30"; do
        win=$(echo "$entry" | cut -d' ' -f1)
        id=$(echo "$entry" | cut -d' ' -f2)
        tmux new-window -t orchestra -n "$win"
        tmux send-keys -t "orchestra:$win" "tmux attach -t $id" Enter
    done

    echo ""
    echo "====================================="
    echo " tmux 'orchestra' session is ready!"
    echo "====================================="
    echo ""
    echo "  Attach:          tmux attach -t orchestra"
    echo "  Switch windows:  Ctrl+b  (next/prev: n/p, or 0-5)"
    echo ""
    echo "  Or attach each agent directly:"
    echo "    tmux attach -t 10   # MIR"
    echo "    tmux attach -t 20   # ROY"
    echo "    tmux attach -t 30   # CLAUDE"
}

send_message() {
    local id=$1
    shift
    local message="$*"
    
    # Validate agent ID
    case $id in
        10|11|12|20|21|22|30) ;;
        *) echo "Error: Unknown agent ID: $id"; echo "Valid IDs: 10, 11, 12, 20, 21, 22, 30"; exit 1 ;;
    esac
    
    # Send message first, then Enter separately (proven reliable method)
    tmux send-keys -t "$id" "$message"
    sleep 0.3
    tmux send-keys -t "$id" Enter
    
    echo "Sent to Agent $id: $message"
}

kill_all() {
    echo "Killing all tmux sessions..."
    for id in 10 11 12 20 21 22 30; do
        tmux kill-session -t "$id" 2>/dev/null
    done
    echo "Done!"
}

status() {
    echo "=== tmux Sessions ==="
    tmux list-sessions 2>/dev/null || echo "No sessions running"
}

print_help() {
    echo "B:Essential Multi-Agent Orchestration System"
    echo ""
    echo "Usage: $0 <command> [args]"
    echo ""
    echo "Commands:"
    echo "  start       Launch all 7 agents (tmux + iTerm)"
    echo "  send <ID> <message>  Send message to agent"
    echo "  status      Show running tmux sessions"
    echo "  kill        Kill all tmux sessions"
    echo ""
    echo "Agent IDs:"
    echo "  10=MIR, 11=WebScraper, 12=CodeAnalyzer"
    echo "  20=ROY, 21=TestWriter, 22=Debugger"
    echo "  30=CLAUDE (Claude Code — real file edits)"
    echo ""
    echo "Examples:"
    echo "  $0 start"
    echo "  $0 send 10 'Analyze a repository'"
    echo "  $0 send 20 'Build a web app'"
    echo "  $0 send 30 'Refactor orchestrate.py to use async'"
    echo ""
    echo "Environment Variables:"
    echo "  ITERM_PROFILE  iTerm profile name (default: Default)"
}

case "$1" in
    start)
        check_prerequisites
        create_agent_dirs
        create_tmux_sessions
        sleep 2
        open_iterm_windows
        echo ""
        echo "=== Ready! ==="
        echo "Use: $0 send <ID> '<message>'"
        ;;
    send)
        [[ -z "$2" || -z "$3" ]] && echo "Usage: $0 send <ID> '<message>'" && exit 1
        send_message "$2" "${@:3}"
        ;;
    status)
        status
        ;;
    kill)
        kill_all
        ;;
    *)
        print_help
        ;;
esac
