# Safe Vibe

개인정보보호·시큐어코딩 Cursor 스킬.

한국 개인정보 보호법 웹 개발 의무(PIPA catalog 0.2.0)와 KISA SW 개발보안 가이드 약점(catalog 0.3.0)을 에이전트가 코드에 바로 쓰도록 묶었다.

## 설치

```bash
curl -fsSL https://raw.githubusercontent.com/days0854/safe-vibe/main/install.sh | bash
```

로컬 클론에서 설치:

```bash
bash install.sh
```

에이전트에게 두 스킬을 쓰라고 한 줄 규칙을 남기려면 `bash install.sh --with-init` (현재 디렉터리에 `.cursor/rules/safe-vibe.mdc`).

macOS / Linux / WSL. Cursor(`~/.cursor/skills`)에 두 스킬을 복사한다. `~/.claude`가 있으면 Claude Code 스킬 폴더에도 넣는다.

## 스킬

| 폴더 | 이름 | 내용 |
|---|---|---|
| `skills/pipa-privacy` | 개인정보보호 스킬 | 가입·동의·처리방침·탈퇴·쿠키·제3자·아동 등 의무 20항 |
| `skills/kisa-secure-coding` | 시큐어코딩 스킬 | 구현 49 + 설계 20 (SQL 삽입, XSS, 인증, 암호, 업로드 등) |

각 폴더에 `SKILL.md`, `catalog.json`, `logo.png`가 있다. 조문 전문과 원문 PDF는 없다.

## 주의

- **법률 자문이 아닙니다.** 적법·위법 판단, 심사 합격·준수 증명이 아닙니다.
- **원문 PDF 없음.** 가이드·법령 본문을 포함하지 않습니다.
- 카탈로그 버전을 올리지 마세요 (PIPA 0.2.0, KISA 0.3.0).

레포: https://github.com/days0854/safe-vibe

MIT License.
