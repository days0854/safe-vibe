# Safe Vibe

개인정보보호·시큐어코딩 Cursor 스킬.

한국 개인정보 보호법 웹 개발 의무(PIPA catalog 0.2.0)와 KISA SW 개발보안 가이드 약점(catalog 0.3.0)을 에이전트가 코드에 바로 쓰도록 묶었다.

## 설치

릴리스 파일을 내려받고 고정된 SHA-256이 일치할 때만 로컬 설치기를 실행합니다.

```bash
(
  set -eu
  SAFE_VIBE_VERSION='v0.1.0'
  SAFE_VIBE_SHA256='0a8a401dd05603be65845bf9710a4e3354100ed7978bab57c63d66943619a31c'
  SAFE_VIBE_TMP="$(mktemp -d "${TMPDIR:-/tmp}/safe-vibe-download.XXXXXX")"
  trap 'rm -rf "$SAFE_VIBE_TMP"' EXIT
  SAFE_VIBE_ARCHIVE="$SAFE_VIBE_TMP/safe-vibe-$SAFE_VIBE_VERSION.tar.gz"
  curl --proto '=https' --tlsv1.2 --fail --location --retry 3 \
    --connect-timeout 10 --max-time 120 \
    --output "$SAFE_VIBE_ARCHIVE" \
    "https://github.com/days0854/safe-vibe/releases/download/$SAFE_VIBE_VERSION/safe-vibe-$SAFE_VIBE_VERSION.tar.gz"
  if command -v sha256sum >/dev/null 2>&1; then
    SAFE_VIBE_ACTUAL="$(sha256sum "$SAFE_VIBE_ARCHIVE" | awk '{print $1}')"
  elif command -v shasum >/dev/null 2>&1; then
    SAFE_VIBE_ACTUAL="$(shasum -a 256 "$SAFE_VIBE_ARCHIVE" | awk '{print $1}')"
  else
    echo "sha256sum 또는 shasum이 필요합니다." >&2
    exit 1
  fi
  [ "$SAFE_VIBE_ACTUAL" = "$SAFE_VIBE_SHA256" ] || {
    echo "SHA-256 검증에 실패했습니다. 설치를 중단합니다." >&2
    exit 1
  }
  tar -xzf "$SAFE_VIBE_ARCHIVE" -C "$SAFE_VIBE_TMP"
  bash "$SAFE_VIBE_TMP/safe-vibe-$SAFE_VIBE_VERSION/install.sh"
)
```

다운로드 파일은 실행 전에 HTTPS, 고정 버전 및 SHA-256으로 검증됩니다. 프로젝트 규칙까지 만들려면 마지막 `bash` 명령에 `--with-init`을 추가합니다.

로컬 클론에서는 페이로드 해시를 검증한 뒤 같은 트랜잭션 설치기를 실행합니다.

```bash
bash install.sh
```

기존 `.cursor/rules/safe-vibe.mdc`는 덮어쓰지 않습니다.

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
