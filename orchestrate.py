"""
B:Essential Multi-Agent Orchestration (Python / Gemini Flash - 무료)

흐름: 사용자 요청 → JIAN (분류·위임) → MIR (마케팅) 또는 ROY (개발)

설치: pip install google-genai
설정: export GEMINI_API_KEY="AIza..."
키 발급: https://aistudio.google.com/apikey
"""

import json
import os
import re
import subprocess
from dotenv import load_dotenv
from google import genai
from google.genai import types

load_dotenv()

ORCHESTRATE_SH = os.path.join(
    os.path.dirname(os.path.abspath(__file__)),
    ".orchestration",
    "orchestrate.sh",
)
CLAUDE_AGENT_ID = "30"

client = genai.Client(api_key=os.environ["GEMINI_API_KEY"])
MODEL = "gemini-2.5-flash-lite"

# ── 시스템 프롬프트 ─────────────────────────────────────────────────────────

JIAN_SYSTEM = """You are JIAN, the master orchestrator of the B:Essential multi-agent system.
Analyze the user's request and route it to the correct specialist agent.

Agents:
- MIR    : marketing, content creation, OSMU, market research, social media, blog posts
- ROY    : quick code generation or snippets where NO real file changes are needed (one-shot answers, explanations, small utility code)
- CLAUDE : real codebase work — editing existing files, multi-file refactoring, debugging in the actual repo, running tests, anything that needs filesystem access

Routing heuristic:
- If the user wants to MODIFY THIS REPO (edit files, refactor, fix bugs in existing code, add features to existing modules) → CLAUDE
- If the user wants generic code without touching the repo → ROY
- If the user wants marketing/content → MIR

Reply ONLY with valid JSON (no markdown fences):
{
  "agent": "MIR" or "ROY" or "CLAUDE",
  "task": "precise task description for the agent",
  "reasoning": "one-line reason"
}"""

MIR_SYSTEM = """You are MIR (Marketing Intelligence & Research).
Specialties: content analysis, blog/social-media copy, OSMU strategy, market research.
Deliver high-quality, actionable marketing content in Korean unless asked otherwise."""

ROY_SYSTEM = """You are ROY (Robust Operational Yield).
Specialties: web apps, Python/JS code, refactoring, debugging, testing, REST APIs.
Deliver clean, working code with brief explanations in Korean unless asked otherwise."""

# ── 에이전트 함수 ────────────────────────────────────────────────────────────

def _generate(system: str, prompt: str, max_tokens: int = 4096) -> str:
    response = client.models.generate_content(
        model=MODEL,
        config=types.GenerateContentConfig(
            system_instruction=system,
            max_output_tokens=max_tokens,
        ),
        contents=prompt,
    )
    return response.text


def jian_route(user_request: str) -> dict:
    """JIAN: 요청을 분석해 MIR 또는 ROY로 라우팅"""
    text = _generate(JIAN_SYSTEM, user_request, max_tokens=256)
    match = re.search(r"\{.*\}", text, re.DOTALL)
    if match:
        try:
            return json.loads(match.group())
        except json.JSONDecodeError:
            pass
    return {"agent": "ROY", "task": user_request, "reasoning": "fallback"}


def mir_execute(task: str) -> str:
    """MIR: 마케팅·콘텐츠 작업 실행"""
    return _generate(MIR_SYSTEM, task)


def roy_execute(task: str) -> str:
    """ROY: 개발·코드 작업 실행"""
    return _generate(ROY_SYSTEM, task)


def claude_dispatch(task: str) -> str:
    """CLAUDE: tmux 세션 30번에서 실행 중인 Claude Code에게 작업 위임."""
    if not os.path.exists(ORCHESTRATE_SH):
        return f"[ERROR] orchestrate.sh not found at {ORCHESTRATE_SH}"

    result = subprocess.run(
        ["bash", ORCHESTRATE_SH, "send", CLAUDE_AGENT_ID, task],
        capture_output=True,
        text=True,
    )
    if result.returncode != 0:
        return (
            "[ERROR] CLAUDE 디스패치 실패. tmux 세션 30이 살아있는지 확인하세요.\n"
            f"  실행: bash {ORCHESTRATE_SH} start\n"
            f"  stderr: {result.stderr.strip()}"
        )
    return (
        "✓ CLAUDE 에이전트(tmux 30)에게 작업 위임 완료.\n"
        "  실시간 진행: tmux attach -t 30  (또는 tmux attach -t orchestra → 30-CLAUDE 윈도우)\n"
        f"  전송된 작업: {task}"
    )


# ── 메인 오케스트레이터 ──────────────────────────────────────────────────────

def orchestrate(user_request: str) -> str:
    """JIAN → MIR | ROY 전체 흐름"""
    print(f"\n[JIAN] 분석 중 → \"{user_request[:60]}\"")

    routing   = jian_route(user_request)
    agent     = routing.get("agent", "ROY")
    task      = routing.get("task", user_request)
    reasoning = routing.get("reasoning", "")

    print(f"[JIAN] {agent} 에게 위임  ({reasoning})")
    print(f"[{agent}] 작업 실행 중…")

    if agent == "MIR":
        result = mir_execute(task)
    elif agent == "CLAUDE":
        result = claude_dispatch(task)
    else:
        result = roy_execute(task)

    print(f"[{agent}] 완료!")
    return result


# ── CLI 진입점 ───────────────────────────────────────────────────────────────

if __name__ == "__main__":
    import sys

    if len(sys.argv) > 1:
        req = " ".join(sys.argv[1:])
        print("\n" + "=" * 60)
        result = orchestrate(req)
        print(f"\n{'='*60}\n결과:\n{result}")
    else:
        samples = [
            "블로그 포스트 아이디어 3개 생성해줘",
            "파이썬으로 파일 목록을 JSON으로 반환하는 간단한 함수 작성해줘",
        ]
        for req in samples:
            print("\n" + "=" * 60)
            print(f"요청: {req}")
            print("=" * 60)
            result = orchestrate(req)
            print(f"\n결과:\n{result}\n")
