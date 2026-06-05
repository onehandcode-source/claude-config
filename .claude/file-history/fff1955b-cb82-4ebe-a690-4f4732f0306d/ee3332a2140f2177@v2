# USER/ADMIN 화면 분리 구현 — 진행 중

## Context
사용자 요청: 샘플 HTML(`docs/sampleHtml/termbase-atlas-project/`)을 기준으로 USER(`/app/*`)와 ADMIN(`/admin/*`) 레이아웃을 완전 분리. Big Bang 방식으로 기존 경로 일괄 교체.

상세 계획: `docs/plans/2026-05-27-user-admin-split-plan.md`

---

## 완료된 작업 (Wave 1)
- `src/app/AdminRoute.jsx` ✅
- `src/layouts/UserLayout.jsx` ✅
- `src/layouts/components/UserSidebar.jsx` ✅
- `src/layouts/AdminLayout.jsx` ✅
- `src/layouts/components/AdminSidebar.jsx` ✅
- 14개 플레이스홀더 페이지 (`src/features/app/*`, `src/features/admin/*`) ✅

---

## 남은 작업

### Wave 2: 기존 파일 수정 (순차)
1. `src/layouts/components/LayoutHeader.jsx` — `homeRoute` + `SidebarComponent` prop 추가
2. `src/app/router.jsx` — `/app/*` + `/admin/*` 이중 구조 전면 재작성
3. `src/features/auth/LoginPage.jsx` — 역할별 리다이렉트 (ADMIN→/admin/dashboard, USER→/app/home)

### Wave 3: 구 파일 제거
- 구 features 파일 12개 + MainLayout + SidebarSurface + menuItems

### Wave 4-5: 각 화면 구현 (병렬)
- USER 화면 6개 + ADMIN 화면 8개

---

## 검증
```bash
npm run build && npm start
# USER 로그인 → /app/home, ADMIN → /admin/dashboard
```
