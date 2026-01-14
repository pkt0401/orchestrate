#!/bin/zsh
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

WORKSPACE="/Users/roysmac/Dev"
AGENTS_DIR="$WORKSPACE/.orchestration/agents"
ITERM_PROFILE="Roy's Agents"

create_tmux_sessions() {
    echo "Creating tmux sessions for all agents..."
    
    # Agent configurations: ID:DIR:NAME
    local agents=(
        "10:10-mir:MIR Master Agent"
        "11:11-webscraper:WebScraper"
        "12:12-codeanalyzer:CodeAnalyzer"
        "20:20-roy:ROY Master Agent"
        "21:21-testwriter:TestWriter"
        "22:22-debugger:Debugger"
    )
    
    for agent in "${agents[@]}"; do
        IFS=':' read -r id dir_name display_name <<< "$agent"
        
        # Kill existing session if exists
        tmux kill-session -t "$id" 2>/dev/null
        
        # Create new session with correct working directory
        tmux new-session -d -s "$id" -c "$AGENTS_DIR/$dir_name"
        tmux send-keys -t "$id" "clear && echo '[$id] $display_name' && echo 'Path: \$(pwd)' && echo '' && gemini" Enter
        
        echo "  [$id] $display_name"
    done
    
    echo "All 6 tmux sessions created!"
}

open_iterm_windows() {
    echo "Opening iTerm windows..."
    
    osascript <<EOF
tell application "iTerm"
    activate
    
    -- MIR Team Window
    create window with profile "$ITERM_PROFILE"
    set mirWindow to current window
    
    tell current session of mirWindow
        set name to "10-MIR"
        write text "tmux attach -t 10"
    end tell
    
    tell mirWindow to create tab with profile "$ITERM_PROFILE"
    tell current session of mirWindow
        set name to "11-WebScraper"
        write text "tmux attach -t 11"
    end tell
    
    tell mirWindow to create tab with profile "$ITERM_PROFILE"
    tell current session of mirWindow
        set name to "12-CodeAnalyzer"
        write text "tmux attach -t 12"
    end tell
    
    delay 1
    
    -- ROY Team Window
    create window with profile "$ITERM_PROFILE"
    set royWindow to current window
    
    tell current session of royWindow
        set name to "20-ROY"
        write text "tmux attach -t 20"
    end tell
    
    tell royWindow to create tab with profile "$ITERM_PROFILE"
    tell current session of royWindow
        set name to "21-TestWriter"
        write text "tmux attach -t 21"
    end tell
    
    tell royWindow to create tab with profile "$ITERM_PROFILE"
    tell current session of royWindow
        set name to "22-Debugger"
        write text "tmux attach -t 22"
    end tell
end tell
EOF
    
    echo "iTerm windows opened!"
}

send_message() {
    local id=$1
    shift
    local message="$*"
    
    # Validate agent ID
    case $id in
        10|11|12|20|21|22) ;;
        *) echo "Error: Unknown agent ID: $id"; echo "Valid IDs: 10, 11, 12, 20, 21, 22"; exit 1 ;;
    esac
    
    # Send message first, then Enter separately (proven reliable method)
    tmux send-keys -t "$id" "$message"
    sleep 0.3
    tmux send-keys -t "$id" Enter
    
    echo "Sent to Agent $id: $message"
}

kill_all() {
    echo "Killing all tmux sessions..."
    for id in 10 11 12 20 21 22; do
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
    echo "  start       Launch all 6 agents (tmux + iTerm)"
    echo "  send <ID> <message>  Send message to agent"
    echo "  status      Show running tmux sessions"
    echo "  kill        Kill all tmux sessions"
    echo ""
    echo "Agent IDs:"
    echo "  10=MIR, 11=WebScraper, 12=CodeAnalyzer"
    echo "  20=ROY, 21=TestWriter, 22=Debugger"
    echo ""
    echo "Examples:"
    echo "  $0 start"
    echo "  $0 send 10 'BMAD 리포지토리 분석해줘'"
    echo "  $0 send 20 '웹사이트 만들어줘'"
}

case "$1" in
    start)
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
