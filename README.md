# Claude Code dotfiles

Claude Code 설정을 여러 PC에서 동일하게 유지하기 위한 dotfiles 저장소입니다.

---

## 포함 내용

| 경로 | 설명 |
|------|------|
| `.claude/settings.json` | 전역 설정 (모델, 테마, 권한 등) |
| `.claude/MEMORY.md` | 메모리 인덱스 |
| `.claude/memory/` | 대화 기억 파일 |
| `.claude/skills/` | 커스텀 스킬 |
| `.claude/plugins/` | 플러그인 설정 (캐시 제외) |

---

## 새 PC에서 설정하기

### 1. 저장소 클론

```bash
git clone https://github.com/onehandcode-source/claude-config.git ~/dotfiles
```

### 2. 기존 .claude 백업 (있는 경우)

```bash
# macOS / Linux / Git Bash
mv ~/.claude ~/.claude.bak

# Windows PowerShell
Rename-Item "$env:USERPROFILE\.claude" "$env:USERPROFILE\.claude.bak"
```

### 3. .claude 디렉토리 연결

**심볼릭 링크 방식 (권장)** — 설정 변경이 자동으로 git에 반영됨

```bash
# macOS / Linux / Git Bash
ln -s ~/dotfiles/.claude ~/.claude
```

```powershell
# Windows PowerShell (관리자 권한 또는 개발자 모드 필요)
New-Item -ItemType SymbolicLink `
  -Path "$env:USERPROFILE\.claude" `
  -Target "$env:USERPROFILE\dotfiles\.claude"
```

**단순 복사 방식** — 심볼릭 링크 없이 파일만 복사

```bash
cp -r ~/dotfiles/.claude ~/.claude
```

### 4. 플러그인 재설치

Claude Code를 열고 아래 명령을 순서대로 실행합니다.

```
/plugin marketplace add mvanhorn/last30days-skill
/plugin install last30days
/reload-plugins
```

> `plugins/cache/`는 저장소에 포함되지 않으므로 새 PC에서 다시 설치해야 합니다.

---

## 설정 변경 후 동기화

### 변경사항 push

```bash
cd ~/dotfiles
git add .claude/settings.json .claude/MEMORY.md
git commit -m "설정 업데이트"
git push
```

### 다른 PC에서 pull

```bash
cd ~/dotfiles
git pull
```

---

## Windows 개발자 모드 활성화 (심볼릭 링크 권한)

설정 → 개인 정보 및 보안 → 개발자용 → **개발자 모드 켜기**

또는 PowerShell (관리자):

```powershell
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\AppModelUnlock" /t REG_DWORD /f /v "AllowDevelopmentWithoutDevLicense" /d "1"
```
