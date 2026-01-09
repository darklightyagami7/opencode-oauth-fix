# OpenCode OAuth Fix

OpenCode에서 Anthropic Claude OAuth 인증 오류를 해결하는 가이드입니다.

> **English version below**

---

## 문제

OpenCode에서 Claude Pro/Max OAuth 인증 시 다음 오류 발생:

```
This credential is only authorized for use with Claude Code and cannot be used for other API requests.
```

## 해결 방법

[PR #13](https://github.com/anomalyco/opencode-anthropic-auth/pull/13)의 다층 우회 방식을 적용합니다.

### 우회 방식 설명

| 방법 | 변환 예시 | 설명 |
|------|----------|------|
| Method 1 | `read_file` → `ReadFile_tool` | PascalCase + `_tool` 접미사 |
| Method 2 | `read_file` → `read_file_a3f7k2` | 랜덤 접미사 (자동 폴백) |

Method 1이 차단되면 자동으로 Method 2로 전환됩니다.

---

## 빠른 설치 (원클릭)

```bash
curl -fsSL https://raw.githubusercontent.com/chulrolee/opencode-oauth-fix/main/scripts/setup.sh | bash
```

또는 스크립트를 다운로드 후 실행:

```bash
git clone https://github.com/chulrolee/opencode-oauth-fix.git
cd opencode-oauth-fix
chmod +x scripts/setup.sh
./scripts/setup.sh
```

---

## 수동 설치

### 준비물

- **Bun** v1.3.5 이상
- **Git**

```bash
# Bun 설치 (없는 경우)
curl -fsSL https://bun.sh/install | bash
```

### Step 1: 패치 폴더 생성 및 클론

```bash
mkdir -p ~/Developer/opencode-patch
cd ~/Developer/opencode-patch

# 플러그인 클론
git clone https://github.com/anomalyco/opencode-anthropic-auth.git
cd opencode-anthropic-auth

# PR #13 적용
git fetch origin pull/13/head:pr-13
git checkout pr-13
bun install
cd ..

# OpenCode 클론
git clone https://github.com/anomalyco/opencode.git
cd opencode
bun install
```

### Step 2: 플러그인 경로 수정

`packages/opencode/src/plugin/index.ts` 파일에서 플러그인 경로를 수정합니다:

```typescript
const BUILTIN = [
  "opencode-copilot-auth@0.0.9",
  "file:///Users/YOUR_USERNAME/Developer/opencode-patch/opencode-anthropic-auth/index.mjs"
]
```

`YOUR_USERNAME`을 본인의 macOS 사용자 이름으로 변경하세요:

```bash
whoami  # 사용자 이름 확인
```

### Step 3: OpenCode 빌드

```bash
cd ~/Developer/opencode-patch/opencode/packages/opencode
bun run build -- --single
```

### Step 4: PATH 설정

`~/.zshrc` (또는 `~/.bashrc`)에 추가:

```bash
export PATH="$HOME/Developer/opencode-patch/opencode/packages/opencode/dist/opencode-darwin-arm64/bin:$PATH"
```

적용:

```bash
source ~/.zshrc
```

### Step 5: 확인

```bash
which opencode
# /Users/YOUR_USERNAME/Developer/opencode-patch/opencode/.../bin/opencode

opencode --version
# 0.0.0-dev-YYYYMMDDHHMM
```

---

## 사용법

```bash
opencode
```

### Method 2 강제 사용 (옵션)

Method 1이 막힌 경우 환경변수로 강제 전환:

```bash
export OPENCODE_USE_RANDOMIZED_TOOLS=true
opencode
```

---

## 원복 방법

패치를 제거하고 원래 버전으로 돌아가려면:

1. `~/.zshrc`에서 PATH 라인 삭제
2. `source ~/.zshrc` 실행
3. (옵션) 패치 폴더 삭제: `rm -rf ~/Developer/opencode-patch`

---

## 참고 링크

- [Issue #12: The auth no longer works](https://github.com/anomalyco/opencode-anthropic-auth/issues/12)
- [PR #13: Multi-layered bypass](https://github.com/anomalyco/opencode-anthropic-auth/pull/13)
- [OpenCode 원본 레포](https://github.com/anomalyco/opencode)

---

## 기여

문제가 있거나 개선 사항이 있으면 Issue를 열어주세요!

---

# English

## Problem

When using Claude Pro/Max OAuth authentication in OpenCode:

```
This credential is only authorized for use with Claude Code and cannot be used for other API requests.
```

## Solution

Apply the multi-layered bypass from [PR #13](https://github.com/anomalyco/opencode-anthropic-auth/pull/13).

### Bypass Methods

| Method | Example | Description |
|--------|---------|-------------|
| Method 1 | `read_file` → `ReadFile_tool` | PascalCase + `_tool` suffix |
| Method 2 | `read_file` → `read_file_a3f7k2` | Random suffix (auto fallback) |

---

## Quick Install

```bash
curl -fsSL https://raw.githubusercontent.com/chulrolee/opencode-oauth-fix/main/scripts/setup.sh | bash
```

---

## Manual Install

### Prerequisites

- **Bun** v1.3.5+
- **Git**

### Steps

```bash
# 1. Create patch directory
mkdir -p ~/Developer/opencode-patch
cd ~/Developer/opencode-patch

# 2. Clone and setup plugin with PR #13
git clone https://github.com/anomalyco/opencode-anthropic-auth.git
cd opencode-anthropic-auth
git fetch origin pull/13/head:pr-13
git checkout pr-13
bun install
cd ..

# 3. Clone and setup OpenCode
git clone https://github.com/anomalyco/opencode.git
cd opencode
bun install

# 4. Update plugin path in packages/opencode/src/plugin/index.ts
# Change YOUR_USERNAME to your macOS username (run: whoami)

# 5. Build
cd packages/opencode
bun run build -- --single

# 6. Add to PATH (~/.zshrc or ~/.bashrc)
export PATH="$HOME/Developer/opencode-patch/opencode/packages/opencode/dist/opencode-darwin-arm64/bin:$PATH"

# 7. Apply
source ~/.zshrc
```

---

## License

MIT

---

**Last Updated**: 2026-01-09
