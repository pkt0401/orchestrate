# 🎩 B:Essential Multi-Agent Orchestration System

AI 에이전트들이 협업하는 멀티에이전트 오케스트레이션 시스템.
JIAN(오케스트레이터)이 MIR(마케팅), ROY(개발) 팀에게 작업을 위임하고 병렬 실행합니다.

## 💰 비용 안내: 완전 무료!

이 시스템은 **완전 무료**로 사용할 수 있습니다.

| 플랜 | 일일 요청 수 | 비용 |
|------|-------------|------|
| 무료 계정 | 1,000건 | $0 |
| Google One Pro | 1,500건 | 월 구독료 |

> ✅ **개인 프로젝트나 학습 목적이라면 무료 플랜으로 충분합니다.**
>
> 사용 환경에 따라 완전 무료로 나만의 콘텐츠나 소프트웨어를 구현할 수 있습니다!

## 🏗️ 아키텍처

```
┌─────────────────────────────────────────────────────────┐
│                 JIAN (Orchestrator)                     │
│              orchestrate.py (Python/Gemini)             │
└─────────────────────┬───────────────────────────────────┘
                      │ tmux send-keys
          ┌───────────┴───────────┐
          ▼                       ▼
┌─────────────────┐     ┌─────────────────┐
│   MIR Team      │     │   ROY Team      │
│   (Marketing)   │     │  (Development)  │
├─────────────────┤     ├─────────────────┤
│ [10] MIR Master │     │ [20] ROY Master │
│ [11] WebScraper │     │ [21] TestWriter │
│ [12] CodeAnalyzer│    │ [22] Debugger   │
└─────────────────┘     └─────────────────┘
                              │
                              ▼
                   ┌─────────────────┐
                   │  CLAUDE Team    │
                   │  (Code Editing) │
                   ├─────────────────┤
                   │ [30] CLAUDE     │
                   └─────────────────┘
```

## 📋 Agent ID Registry

| ID | Name | Role | Team | Status |
|----|------|------|------|--------|
| 00 | JIAN | Orchestrator | - | ✅ 완료 |
| 10 | MIR | Master Agent | Marketing | ✅ 완료 |
| 11 | WebScraper | Subagent | Marketing | 🚧 TBD |
| 12 | CodeAnalyzer | Subagent | Marketing | 🚧 TBD |
| 20 | ROY | Master Agent | Development | ✅ 완료 |
| 21 | TestWriter | Subagent | Development | 🚧 TBD |
| 22 | Debugger | Subagent | Development | 🚧 TBD |
| 30 | CLAUDE | Code Agent | Development | ✅ 완료 |

> **Note:** 서브에이전트(11, 12, 21, 22)는 현재 기본 설정만 되어 있으며, 추후 전문화된 프롬프트와 도구가 추가될 예정입니다.

## 🚀 Quick Start

### 1. Prerequisites

- Windows 10/11 + WSL2
- Windows Terminal (권장)
- tmux (`sudo apt install tmux`)
- Node.js 18+ (WSL2 내)
- Python 3.8+ (WSL2 내)
- Gemini API Key ([발급받기](https://aistudio.google.com/apikey))

### 2. Gemini API 설정

```bash
# .env 파일 생성
echo 'GEMINI_API_KEY="AIza..."' > .env

# Python 의존성 설치
pip install google-genai python-dotenv
```

### 3. Repository 설치

```bash
git clone https://github.com/pkt0401/orchestrate.git
cd orchestrate
chmod +x .orchestration/orchestrate.sh
```

### 4. 에이전트 시작

```bash
./.orchestration/orchestrate.sh start
```
→ 7개의 tmux 세션이 생성됩니다. Windows Terminal에서 확인하려면:

```bash
tmux attach -t orchestra   # 전체 뷰 (Ctrl+b + n/p 로 창 전환)
```

### 5. 작업 위임 (Shell)

```bash
# MIR에게 콘텐츠 생성 요청
./.orchestration/orchestrate.sh send 10 "OSMU 콘텐츠 생성해줘"

# ROY에게 개발 요청
./.orchestration/orchestrate.sh send 20 "대시보드 만들어줘"

# CLAUDE에게 코드 수정 요청
./.orchestration/orchestrate.sh send 30 "orchestrate.py 리팩토링해줘"
```

### 6. Python으로 실행

```bash
# 사용 예시: python orchestrate.py "작업"
python orchestrate.py "대시보드 만들어줘"
```

## 📁 Directory Structure

```
.
├── .orchestration/
│   ├── orchestrate.sh      # 메인 오케스트레이션 스크립트
│   └── agents/             # 에이전트 작업 디렉토리
│       ├── 10-mir/         # MIR Master
│       ├── 11-webscraper/  # WebScraper (TBD)
│       ├── 12-codeanalyzer/# CodeAnalyzer (TBD)
│       ├── 20-roy/         # ROY Master
│       ├── 21-testwriter/  # TestWriter (TBD)
│       ├── 22-debugger/    # Debugger (TBD)
│       └── 30-claude/      # CLAUDE Code Agent
├── orchestrate.py          # Python 진입점 (Gemini Flash)
├── GEMINI.md               # 전역 설정 (Agent ID, Protocol)
└── README.md
```

## 📡 Communication Protocol

각 에이전트는 별도의 tmux 세션에서 실행됩니다.
JIAN(오케스트레이터)이 `tmux send-keys`를 통해 각 에이전트에게 명령을 전달합니다.

```bash
# 기본 문법
tmux send-keys -t {Agent_ID} "message" Enter

# 예시
tmux send-keys -t 10 "리포지토리 분석해줘" Enter  # → MIR
tmux send-keys -t 20 "웹앱 만들어줘" Enter        # → ROY
tmux send-keys -t 30 "코드 리팩토링해줘" Enter    # → CLAUDE
```

## 🎯 Use Cases

| 작업 | 담당 | 명령어 | Status |
|------|------|--------|--------|
| 콘텐츠 분석/생성 | MIR | `send 10 "분석해줘"` | ✅ |
| 웹 스크래핑 | WebScraper | `send 11 "스크래핑해줘"` | 🚧 TBD |
| 코드 분석 | CodeAnalyzer | `send 12 "코드 분석해줘"` | 🚧 TBD |
| 웹앱 개발 | ROY | `send 20 "개발해줘"` | ✅ |
| 테스트 작성 | TestWriter | `send 21 "테스트 작성해줘"` | 🚧 TBD |
| 디버깅 | Debugger | `send 22 "버그 수정해줘"` | 🚧 TBD |
| 코드 편집/리팩토링 | CLAUDE | `send 30 "리팩토링해줘"` | ✅ |

## 🔧 Commands

```bash
./.orchestration/orchestrate.sh start             # 모든 에이전트 시작 (7개)
./.orchestration/orchestrate.sh status            # 상태 확인
./.orchestration/orchestrate.sh send ID "msg"     # 메시지 전송
./.orchestration/orchestrate.sh kill              # 모든 에이전트 종료
```

## 🛠️ Troubleshooting

### tmux 세션이 안 보여요
```bash
tmux list-sessions          # 실행 중인 세션 확인
tmux attach -t orchestra    # 전체 뷰 세션에 연결
tmux attach -t 10           # MIR 세션에 직접 연결
```

### WSL2에서 Windows Terminal으로 tmux 보기
```bash
# Windows Terminal 새 탭에서 WSL2 열고:
tmux attach -t orchestra
# Ctrl+b + n/p 로 에이전트 창 전환
```

### Gemini API 오류
```bash
# .env 파일에 키가 올바르게 설정되어 있는지 확인
cat .env
# GEMINI_API_KEY="AIza..." 형태여야 합니다
```

### Gemini CLI가 응답하지 않아요
- 일일 요청 한도(1,000건)를 초과했을 수 있습니다
- 다음 날 자정(UTC)에 리셋됩니다

## 📝 Roadmap

- [x] JIAN Orchestrator 구현
- [x] MIR Master Agent 구현
- [x] ROY Master Agent 구현
- [x] CLAUDE Code Agent 구현 (30)
- [x] Python 진입점 구현 (orchestrate.py)
- [x] WSL2/Windows 환경 지원
- [ ] WebScraper 전문화 (11)
- [ ] CodeAnalyzer 전문화 (12)
- [ ] TestWriter 전문화 (21)
- [ ] Debugger 전문화 (22)
- [ ] 에이전트 간 자동 위임 구현

## 📄 License

MIT License

## 🙏 Credits

Built with:
- [Gemini Flash](https://aistudio.google.com/) - AI Orchestrator (무료)
- [Claude Code](https://claude.ai/code) - Code Agent (30)
- [tmux](https://github.com/tmux/tmux) - Terminal Multiplexer
- [WSL2](https://learn.microsoft.com/windows/wsl/) - Windows Linux 환경
- [Windows Terminal](https://aka.ms/terminal) - 터미널 환경
