---
name: kisa-secure-coding
description: use this when writing or reviewing application code for KISA SW 개발보안 가이드 약점 (SQL injection, XSS, auth, crypto, file upload, etc.).
---

# 시큐어코딩 스킬

KISA 소프트웨어 개발보안 가이드 약점을 Cursor/Grok 에이전트가 코드에 바로 적용하기 위한 스킬이다.

- 카탈로그 버전 **0.3.0**. 버전을 올리지 말 것.
- 같은 폴더의 [`catalog.json`](catalog.json)만 본다. 구현 49 + 설계 20.
- 구현 사례는 같은 폴더의 [`cases.json`](cases.json)이다. `catalog.json`의 `case_count`와 같다. 항목명·CWE·잘 틀리는 지점만. 가이드 PDF 원문 없음.
- 가이드 PDF 원문·예제 코드를 붙이거나 인용하지 않는다.

**전면 상용 SAST가 아니다. 법률 자문·인증 합격 증명이 아니다.** high로 보이는 지적은 검토하고, 오탐이면 이유를 남긴다. 결과 없음은 안전이 아니다.

## 언제 쓰나

애플리케이션 코드를 쓰거나 리뷰할 때. 특히 SQL, XSS, 인증·인가, 암호, 파일 업로드, 리다이렉트, 명령 실행, 세션, 시크릿 하드코딩.

## 구현 사례

코드를 쓰기 전에 `cases.json`에서 같은 결함의 `name`과 `mistake`를 찾는다. `sourceIds`가 `IMP-*` 또는 `DES-*`이므로 그 id를 `catalog.json`에서 열어 `fix` 또는 `fix_principle`로 고친다. 사례 번호 `KISA-1`과 기준 id는 다르다.

사례는 일반 구현 사례다. 실제 사고도 공식 처분도 아니다. 합격이라고 말하지 않는다.

동의, 고지, 처리방침, 보유, 파기, 아동 가입은 개인정보 `cases.json`을 본다. 비밀번호, 토큰, 세션, 경로, 권한, 쿼리, 오류 본문은 이 파일을 본다.

여러 에이전트로 나눌 때는 이 사례를 맡은 에이전트가 소스 결함을 피하고, 개인정보 사례를 맡은 에이전트가 화면과 고지를 맞춘다.

## 예전 MCP 도구 → 이 스킬

| MCP | 스킬에서 할 일 |
|---|---|
| `list_rules` | `catalog.json`의 `rules`(구현 49)와 `design_rules`(설계 20)를 읽는다. 기능 계획이면 설계도 본다. language / category / 기능으로 좁힌다. |
| `get_rule` | `IMP-*` 또는 `DES-*` id로 한 줄을 연다. `summary`·`cwe`·`unsafe`·`agent_checks`·`fix`만 적용한다. |
| `get_checklist` | 파일을 쓰기 전, 기능(sql / upload / auth / crypto / redirect / xss / command / session)에 맞는 IMP(+관련 DES)를 체크리스트로 삼는다. |
| `review_code` | 작성·수정 직후 `unsafe` 신호와 `agent_checks`로 코드를 대조한다. 걸리면 `fix`를 적용한다. |

### 작업 순서

1. 기능 착수 전: 관련 규칙을 `catalog.json`에서 고른다. 새 기능이면 설계 항목(`DES-*`)도 본다.
2. 코드를 쓴다. 사용자 입력을 SQL·HTML·경로·명령·URL에 붙이지 않는다.
3. 작성 후 `agent_checks`를 질문처럼 코드에 던져 본다. high(삽입·XSS·인증·암호·업로드)는 통과할 때까지 고친다.
4. 시크릿·키·비밀번호를 소스에 넣지 않는다.

기능 → 규칙 힌트:

- sql → IMP-1.1, DES-1.1
- xss → IMP-1.4
- upload → IMP-1.6, DES-1.10
- auth → IMP-2.1, IMP-2.2, IMP-2.9, IMP-2.16, DES-2.1, DES-2.2
- crypto → IMP-2.4 ~ IMP-2.8, IMP-2.14, DES-2.5, DES-2.6
- redirect → IMP-1.7
- command → IMP-1.5, DES-1.4
- session → IMP-6.1, DES-4.1

## 구현 49항

출처: `catalog.json` (KISA catalog 0.3.0).

**입력데이터 검증 및 표현**
- `IMP-1.1` SQL 삽입 (CWE-89)
- `IMP-1.2` 코드 삽입 (CWE-94, CWE-95)
- `IMP-1.3` 경로 조작 및 자원 삽입 (CWE-22, CWE-99)
- `IMP-1.4` 크로스사이트 스크립트 (CWE-79)
- `IMP-1.5` 운영체제 명령어 삽입 (CWE-78)
- `IMP-1.6` 위험한 형식 파일 업로드 (CWE-434)
- `IMP-1.7` 신뢰되지 않는 URL 주소로 자동접속 연결 (CWE-601)
- `IMP-1.8` 부적절한 XML 외부 개체 참조 (CWE-611)
- `IMP-1.9` XML 삽입 (CWE-643)
- `IMP-1.10` LDAP 삽입 (CWE-90)
- `IMP-1.11` 크로스사이트 요청 위조 (CWE-352)
- `IMP-1.12` 서버사이드 요청 위조 (CWE-918)
- `IMP-1.13` HTTP 응답분할 (CWE-113)
- `IMP-1.14` 정수형 오버플로우 (CWE-190)
- `IMP-1.15` 보안기능 결정에 사용되는 부적절한 입력값 (CWE-807)
- `IMP-1.16` 메모리 버퍼 오버플로우
- `IMP-1.17` 포맷 스트링 삽입 (CWE-134)

**보안기능**
- `IMP-2.1` 적절한 인증 없는 중요 기능 허용 (CWE-306)
- `IMP-2.2` 부적절한 인가 (CWE-285)
- `IMP-2.3` 중요한 자원에 대한 잘못된 권한 설정 (CWE-732)
- `IMP-2.4` 취약한 암호화 알고리즘 사용 (CWE-327)
- `IMP-2.5` 암호화되지 않은 중요정보 (CWE-312, CWE-319)
- `IMP-2.6` 하드코드된 중요정보 (CWE-259, CWE-321)
- `IMP-2.7` 충분하지 않은 키 길이 사용 (CWE-326)
- `IMP-2.8` 적절하지 않은 난수 값 사용 (CWE-330)
- `IMP-2.9` 취약한 비밀번호 허용 (CWE-521)
- `IMP-2.10` 부적절한 전자서명 확인 (CWE-347)
- `IMP-2.11` 부적절한 인증서 유효성 검증 (CWE-295)
- `IMP-2.12` 사용자 하드디스크에 저장되는 쿠키를 통한 정보노출 (CWE-539)
- `IMP-2.13` 주석문 안에 포함된 시스템 주요정보 (CWE-615)
- `IMP-2.14` 솔트 없이 일방향 해쉬 함수 사용 (CWE-759)
- `IMP-2.15` 무결성 검사 없는 코드 다운로드 (CWE-494)
- `IMP-2.16` 반복된 인증시도 제한 기능 부재 (CWE-307)

**시간 및 상태**
- `IMP-3.1` 경쟁조건: 검사 시점과 사용 시점(TOCTOU) (CWE-367)
- `IMP-3.2` 종료되지 않는 반복문 또는 재귀함수 (CWE-674, CWE-835)

**에러처리**
- `IMP-4.1` 오류 메시지 정보노출 (CWE-209)
- `IMP-4.2` 오류상황 대응 부재 (CWE-390)
- `IMP-4.3` 부적절한 예외 처리 (CWE-754)

**코드오류**
- `IMP-5.1` Null Pointer 역참조 (CWE-476)
- `IMP-5.2` 부적절한 자원 해제 (CWE-404)
- `IMP-5.3` 해제된 자원 사용
- `IMP-5.4` 초기화되지 않은 변수 사용
- `IMP-5.5` 신뢰할 수 없는 데이터의 역직렬화 (CWE-502)

**캡슐화**
- `IMP-6.1` 잘못된 세션에 의한 데이터 정보노출 (CWE-488, CWE-543)
- `IMP-6.2` 제거되지 않고 남은 디버그 코드 (CWE-489)
- `IMP-6.3` Public 메서드부터 반환된 Private 배열 (CWE-495)
- `IMP-6.4` Private 배열에 Public 데이터 할당 (CWE-496)

**API 오용**
- `IMP-7.1` DNS lookup에 의존한 보안결정 (CWE-350)
- `IMP-7.2` 취약한 API 사용

## 설계 20항

기능 계획·설계 리뷰 때 본다. 상세는 `catalog.json`의 `design_rules`.

- `DES-1.1` DBMS 조회 및 결과 검증
- `DES-1.2` XML 조회 및 결과 검증
- `DES-1.3` 디렉토리 서비스 조회 및 결과 검증
- `DES-1.4` 시스템 자원 접근 및 명령어 수행 입력값 검증
- `DES-1.5` 웹 서비스 요청 및 결과 검증
- `DES-1.6` 웹 기반 중요 기능 수행 요청 유효성 검증
- `DES-1.7` HTTP 프로토콜 유효성 검증
- `DES-1.8` 허용된 범위내 메모리 접근
- `DES-1.9` 보안기능 입력값 검증
- `DES-1.10` 업로드·다운로드 파일 검증
- `DES-2.1` 인증 대상 및 방식
- `DES-2.2` 인증 수행 제한
- `DES-2.3` 비밀번호 관리
- `DES-2.4` 중요자원 접근통제
- `DES-2.5` 암호키 관리
- `DES-2.6` 암호연산
- `DES-2.7` 중요정보 저장
- `DES-2.8` 중요정보 전송
- `DES-3.1` 예외처리
- `DES-4.1` 세션통제

## 하지 말 것

- 가이드 PDF·원문 예제를 그대로 붙이기
- 이 결과를 "KISA 인증 통과"처럼 말하기
- `eval` / `innerHTML` / 문자열 SQL / `shell=True` / 공개 리다이렉트 / 평문 비밀번호를 남긴 채 끝내기
