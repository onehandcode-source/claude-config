# HR System Project Memory

## Stack (2026-02-26 마이그레이션 완료)
- Next.js 16 (App Router)
- shadcn/ui + Radix UI (MUI v7 → 마이그레이션 완료)
- Tailwind CSS v4 (CSS-first, postcss: @tailwindcss/postcss)
- lucide-react (MUI icons 대체)
- Framer Motion (페이지 전환 애니메이션)
- next-auth v4, Prisma + PostgreSQL
- @tanstack/react-query v5, Zustand v5
- sonner (toast), react-big-calendar (유지)
- dayjs

## 주요 파일 경로
- `src/app/globals.css` — shadcn CSS 변수 (oklch, primary=#6366f1 indigo-500)
- `src/components/ui/` — shadcn 컴포넌트 19개
- `src/hooks/useIsMobile.ts` — window.matchMedia 640px 기준
- `src/components/common/PageTransition.tsx` — framer-motion 래퍼
- `src/components/layout/DashboardShell.tsx` — AnimatePresence 적용
- `src/components/providers/ThemeProvider.tsx` — pass-through only

## Tailwind v4 특이사항
- `tailwind.config.js` 없음 (CSS-first)
- `globals.css` 상단에 `@import "tailwindcss"` 필요 (shadcn init 조건)
- shadcn init: `npx shadcn@latest init -d` (globals.css에 @import "tailwindcss" 있어야 감지)

## 패턴 규칙
- Box/Typography/Stack/Grid → Tailwind div
- Chip(상태) → Badge + statusClass 객체 패턴 (bg-yellow/green/red-100)
- Dialog → shadcn Dialog (DialogContent > DialogHeader > DialogFooter)
- Select → shadcn Select + SelectTrigger/SelectValue/SelectContent/SelectItem
- RadioGroup → shadcn RadioGroup + RadioGroupItem
- Switch + FormControlLabel → Switch + Label div
- useMediaQuery → useIsMobile() hook
- ToggleButtonGroup → shadcn ToggleGroup
- DatePicker(@mui/x-date-pickers) → native `<input type="date">` + dayjs(str).toISOString()

## 색상 (oklch)
- primary: oklch(0.585 0.233 277.1) = #6366f1 indigo-500
- secondary: oklch(0.585 0.239 300.4) = #8b5cf6 violet-500
- background: oklch(0.984 0.003 247.9) = #f8fafc slate-50
- border: oklch(0.922 0.012 259.9) = #e2e8f0 slate-200
- sidebar bg: #0f172a (slate-900)

## 사용자 선호
- 한국어 UI
- 다크 사이드바 (#0f172a) + 밝은 메인 영역
