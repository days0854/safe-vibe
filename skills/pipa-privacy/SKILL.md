---
name: pipa-privacy
description: use this when building signup, consent, privacy policy, withdrawal, cookies, third-party sharing, or minors flows under Korean PIPA.
---

# 개인정보보호 스킬

한국 개인정보 보호법(PIPA) 웹 개발 의무를 Cursor/Grok 에이전트가 코드·화면에 바로 적용하기 위한 스킬이다.

- 카탈로그 버전 **0.2.0**. 버전을 올리지 말 것.
- 같은 폴더의 [`catalog.json`](catalog.json)만 본다.
- 활용 예시 100건은 `catalog.json`의 `cases`와 레포 `cases/pipa.json`이다. 항목명·조문번호·잘 틀리는 지점만. 원문 PDF·법령 전문 없음.
- 법률 조문 전문·가이드 PDF·원문 템플릿을 붙이거나 인용하지 않는다.

**이 스킬은 법률 자문이 아니다. 적법·위법 판단을 하지 않으며, 합격·준수 증명이 아니다.**

## 언제 쓰나

회원가입, 수집·이용 동의, 처리방침, 탈퇴, 쿠키, 제3자 제공·처리위탁, 국외이전, 만 14세 미만, 푸터·보호책임자, 생성형 AI 고지를 만들거나 고칠 때 이 스킬을 연다.

## 예전 MCP 도구 → 이 스킬

| MCP | 스킬에서 할 일 |
|---|---|
| `list_duties` | `catalog.json`의 20항을 읽고, 요청 기능(signup / policy / cookie / footer / api / third_party / ai / general)과 `priority`로 고른다. |
| `get_duty` | `id`(PIPA-1 … PIPA-20)로 한 줄을 연다. `unsafe_signals`와 `fix_principle`만 적용한다. |
| `get_scenario` / `list_scenarios` | 시나리오 원문은 이 레포에 없다. 기능이 signup·consent·policy·withdrawal·cookies·third-party·minors면 아래 표에서 관련 의무를 고른다. **As-Is를 재현하지 말고 `fix_principle`(To-Be)로 구현한다.** |
| `get_checklist` | 쓰기 전에 고른 의무의 `agent_when`·`fix_principle`을 체크리스트로 삼는다. |
| `get_template` | HTML 원문 템플릿은 없다. 빠진 칸(고지 4종 등)만 채우고 법률 문장을 창작하지 않는다. |
| `review_surface` | 작성한 UI·카피·API를 `unsafe_signals`와 대조한다. 걸리면 `fix_principle`로 고친다. |

### 작업 순서

1. 사용자 요청이 어떤 화면인지 고른다 (가입 / 동의 / 방침 / 탈퇴 / 쿠키 / 제3자 / 아동 / 푸터).
2. `catalog.json`에서 해당 `agent_when`·이름과 맞는 의무를 고른다. `priority`가 high인 것부터.
3. 코드·카피에 `unsafe_signals`가 있는지 본다.
4. `fix_principle`을 적용해 고친다. 조문 번호는 참고용이며 조문 본문을 쓰지 않는다.
5. 선택·마케팅·제3자·국외이전을 가입 필수 한 칸에 묶지 않았는지 다시 본다.

## 의무 20항

출처: `catalog.json` (PIPA catalog 0.2.0).

| ID | 의무 | 조문 | 우선 |
|---|---|---|---|
| PIPA-1 | 수집 최소화 | 제16조 | high |
| PIPA-2 | 수집·이용 고지 4종 | 제15조 제2항 | high |
| PIPA-3 | 동의 분리 | 제22조, 제22조 제1항 | high |
| PIPA-4 | 동의 처리와 동의 없는 처리 구분 표시 | 제22조 제3항 | medium |
| PIPA-5 | 만 14세 미만 법정대리인 동의 | 제22조의2 | high |
| PIPA-6 | 고유식별정보·주민등록번호 | 제24조, 제24조의2 | high |
| PIPA-7 | 민감정보 별도 동의 | 제23조 | medium |
| PIPA-8 | 제3자 제공 별도 동의·고지 | 제17조 | medium |
| PIPA-9 | 처리위탁 공개 | 제26조 | medium |
| PIPA-10 | 국외이전 고지·동의 또는 요건 | 제28조의8 | medium |
| PIPA-11 | 보유기간·파기 | 제21조 | high |
| PIPA-12 | 처리방침 수립·공개 | 제30조 | high |
| PIPA-13 | 쿠키·자동수집 고지·거부 | 제30조, 제30조 제1항 제7호 | high |
| PIPA-14 | 안전조치 암호화·접근통제 | 제29조 | high |
| PIPA-15 | 노출 방지 | 제34조의2 | medium |
| PIPA-16 | 개인정보 보호책임자 공개 | 제31조 | medium |
| PIPA-17 | 정보주체 권리 행사 창구 | 제35조, 제35조의2, 제36조, 제37조 | medium |
| PIPA-18 | 생성형 AI 학습·이용 고지 | 작성지침 부록1 | low |
| PIPA-19 | 자동화된 결정 고지 | 제37조의2 | low |
| PIPA-20 | 처리방침 변경 고지 | 제30조 | medium |

기능 힌트: 가입·최소수집·동의 = PIPA-1~4, 6, 7. 아동 = PIPA-5. 제3자·위탁·국외 = PIPA-8~10. 파기·탈퇴 = PIPA-11. 방침·쿠키·푸터·책임자·권리 = PIPA-12, 13, 16, 17, 20. 암호화·노출 = PIPA-14, 15. AI·자동결정 = PIPA-18, 19.

## 하지 말 것

- 법률 조문 전문, 작성지침·PDF 원문 붙여넣기
- 이 결과를 "법에 맞다 / 심사 합격"처럼 말하기
- 동의 없는 처리와 동의를 한 체크박스로 묶기
- 선택·마케팅·제3자·국외이전·쿠키를 가입 필수에 끼워 넣기
- 수집 항목·목적·제3자를 "등"으로 열어 두기
- 만 14세 게이트 없이 가입시키기
