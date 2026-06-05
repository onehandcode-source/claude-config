---
name: project_production_issue
description: 2026-03-17 운영 환경에서 발생한 iService 503 오류 — 헬스체크 실패로 인스턴스 없음
type: project
---

2026-03-17에 운영 로그에서 `503 SERVICE_UNAVAILABLE "Unable to find instance for iService"` 오류 발생 확인.

**Why:** iService (내부망 anl1/anl2) 인스턴스에 대한 헬스체크 실패 또는 서비스 미등록 상태에서 라우팅 시도 발생. `ReactiveLoadBalancerClientFilter`에서 예외 발생.

**How to apply:** iService 관련 라우팅/헬스체크 작업 시 이 오류 패턴 참고. `spring.cloud.loadbalancer.health-check` 설정이 핵심 방어선.
