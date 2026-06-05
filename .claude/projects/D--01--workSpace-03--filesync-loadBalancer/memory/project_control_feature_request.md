---
name: project_control_feature_request
description: 중앙 앱에서 LB를 통해 특정 서버 인스턴스에 start/stop/restart 명령을 파라미터로 전달하는 기능 요청
type: project
---

2026-04-06에 새 기능 설계 논의 시작.

**요구사항:**
- 중앙 어플리케이션 → LB 서버 → 특정 Consumer 서버(예: ewas1)로 제어 명령 전달
- 파라미터 형태: `server=ewas1, action=start` (예시)
- 수신한 endpoint에서 sh 파일을 커맨드라인으로 직접 실행
- LB가 파라미터를 보고 특정 인스턴스(ewas1 = eService[0])로 라우팅 가능한지 설계 검토 중

**Why:** 중앙에서 각 서버 인스턴스를 원격 제어하는 운영 편의성 확보.

**How to apply:** 이 기능 설계 시 — LB에서 파라미터 기반 특정 인스턴스 선택(기본 RoundRobin 우회 필요), Consumer 서버에 제어 endpoint 추가, sh 실행 방식 결정이 핵심 설계 포인트.
