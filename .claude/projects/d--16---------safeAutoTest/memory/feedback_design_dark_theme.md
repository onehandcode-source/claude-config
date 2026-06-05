---
name: feedback-design-dark-theme
description: 사용자가 다크 테마 + 에메랄드 강조색 + 사이드바 레이아웃으로 전체 UI 변경을 승인한 설계 결정
metadata: 
  node_type: memory
  type: feedback
  originSessionId: 111648a5-cecf-41e5-8d4c-b1414307bce6
---

사용자가 다크 모드 + 에메랄드 강조색(#10b981) + 좌측 사이드바 레이아웃으로 전체 UI를 변경했다.

**Why:** 장시간 사용하는 내부 테스트 자동화 도구이므로 눈 피로 감소 + 전문적인 느낌

**How to apply:**
- CSS 변수 기준: `--background: 222 21% 7%`, `--primary: 160 84% 39%` (에메랄드)
- 하드코딩 색상 금지: `bg-slate-*`, `text-blue-*`, `bg-white`, `bg-green-100`, `bg-gray-*` 대신 CSS 변수 클래스 사용
- 다크 배경에서의 상태색: `text-emerald-400`(성공), `text-red-400`(실패), `bg-emerald-900/40`(셀 배경)
- 사이드바: `bg-[#111827]` 고정값, 활성 항목 `bg-primary/20 text-primary`
- input/select/textarea는 globals.css에서 `@apply bg-background text-foreground` 기본값 설정 필요
