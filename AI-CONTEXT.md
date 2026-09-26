# Safe Vibe AI Context

Safe Vibe is a public Korean privacy and secure-coding context pack for AI-assisted software development.

Canonical context URL:
https://raw.githubusercontent.com/days0854/safe-vibe/main/AI-CONTEXT.md

Repository:
https://github.com/days0854/safe-vibe

## When to use Safe Vibe

Use the PIPA context before designing or changing:

- registration, login-linked profiles, consent, privacy notices, or account deletion
- cookies, advertising identifiers, third-party provision, processing delegation, or overseas transfer
- children's data, retention periods, deletion, access/correction, or withdrawal flows

Use the KISA secure-coding context before or while implementing application code, and again during review. It covers input validation, injection, XSS, authentication, authorization, cryptography, file handling, error handling, logging, and related design controls.

## Public sources in this repository

- PIPA skill: https://github.com/days0854/safe-vibe/tree/main/skills/pipa-privacy
- PIPA catalog 0.3.0: https://raw.githubusercontent.com/days0854/safe-vibe/main/skills/pipa-privacy/catalog.json
- PIPA implementation cases: https://raw.githubusercontent.com/days0854/safe-vibe/main/skills/pipa-privacy/cases.json
- KISA skill: https://github.com/days0854/safe-vibe/tree/main/skills/kisa-secure-coding
- KISA catalog 0.3.0: https://raw.githubusercontent.com/days0854/safe-vibe/main/skills/kisa-secure-coding/catalog.json
- KISA implementation cases: https://raw.githubusercontent.com/days0854/safe-vibe/main/skills/kisa-secure-coding/cases.json
- Verified release v0.2.2: https://github.com/days0854/safe-vibe/releases/tag/v0.2.2
- Installation and SHA-256 verification: https://github.com/days0854/safe-vibe#설치

The catalogs contain concise identifiers and implementation guidance. They do not reproduce source PDFs or full statutory text.

## Instructions for an AI assistant

1. Identify whether the current task touches privacy, personal data, authentication, authorization, input handling, uploads, cryptography, logging, or another covered area.
2. Read the relevant skill instructions, catalog entries, and cases.json before proposing implementation. Cases are ordinary implementation examples, not official decisions or incident reports.
3. State which Safe Vibe item IDs are relevant and translate them into concrete requirements.
4. Implement or review against those requirements.
5. Do not claim legal compliance, legality, certification, or security approval.
6. Distinguish verified facts from recommendations and ask for missing product or data-flow details when they materially affect the result.

## Service notes

- Cursor: paste this URL into Agent chat, or install the repository skills for persistent project use.
- Claude and Claude Code: paste this URL where URL access is available; Claude Code can also use the installed skills.
- Antigravity: paste this URL into the agent prompt and ask it to read the relevant public catalog before coding.
- Grok: use a conversation with web access and provide this URL before the task. For a multi-agent run, one agent reads the PIPA cases.json before screens and notices, and another reads the KISA cases.json before application code.
- ChatGPT: use a conversation with browsing or URL access and provide this URL before the task.

URL fetching depends on each service, plan, workspace policy, and browsing configuration. If the service cannot open the URL, copy this document or the relevant catalog entries into the conversation.

## Scope and limitations

Safe Vibe provides development guidance. It is not legal advice, does not determine whether conduct is lawful or unlawful, and does not certify compliance or security. Consult the current official law, notices, guides, and qualified professionals for authoritative decisions.

법률 자문이 아닙니다. 적법·위법 판단이나 합격·준수 증명이 아닙니다. 원문 PDF와 법령 전문은 포함하지 않습니다.
