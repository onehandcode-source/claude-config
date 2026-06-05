---
name: pending_work
description: 설계는 완료됐지만 아직 구현되지 않은 작업 목록 (2026-04-21 기준)
type: project
---

## [PENDING-1] ControlController 구현 (2026-04-06 설계 완료, 구현 미완)

**상태**: 설계 문서 작성 완료, 실제 Java 클래스 미구현

**목적**: LB에서 라우팅된 요청으로 현재 서버의 `fileSyncConsumer.sh`를 start/stop/restart 제어

**설계 파일**: `docs/plans/2026-04-06-control-endpoint.md`, `docs/plans/2026-04-06-control-endpoint-design.md`

**엔드포인트**: `POST /control/api/{action}` (action: start/stop/restart)
- IP 화이트리스트 검증 (`control.allowed-ips`)
- ProcessBuilder로 `sh {script} {action}` 실행
- exit code 0 → 200, 그 외 → 500

**Why:** 구현 계획이 있는데 코드가 없으면 다음 세션에서 혼란 방지
**How to apply:** 이 기능 구현 요청 시 설계 문서를 먼저 참조할 것

---

## [PENDING-2] CLAUDE.md CPU 튜닝 수식 추가 (2026-04-14 제안, 미적용)

**상태**: 세션에서 추가 제안 후 사용자 미승인

**내용**: Architecture 섹션에 `### CPU 튜닝 수식` 항목 추가
- 최대 동시 HTTP 요청 = 리스너 수(3) × MAX_CONCURRENT_CONSUMERS × BATCH_SIZE × CONCURRENCY(10)
- PREFETCH_COUNT = BATCH_SIZE 유지 원칙

**Why:** 운영 CPU 스파이크 분석 시 즉시 판단 가능
**How to apply:** 사용자가 CLAUDE.md 업데이트 요청 시 이 항목 포함

---

## [PENDING-3] BUG-8 수정 — CBConfig 이름 불일치 (2026-04-21 발견)

**상태**: 수정 미완

**내용**: `CBConfig.CIRCUIT_BREAKER_NAME = "filesync"` → `"filesync-main"` / `"filesync-recovery"` 각각 Customizer 등록
또는 `circuitbreaker.properties`의 `ignore-exceptions` 속성으로 통합

**Why:** 현재 ignoreException 커스터마이저가 실제 CB 인스턴스에 적용되지 않음 (BUG-8 참조)

---

## [PENDING-4] BUG-9 수정 — DLQ handleMessageMultiAck multiple=true 위험 (2026-04-21 발견)

**상태**: 수정 미완

**내용**: `ConsumerUtil.handleMessageMultiAck`에서 finalOps 전용 ACK는 `multiple=false`로 변경하거나, retryFlux 이후에 finalOps ACK 처리하도록 순서 변경

**Why:** 배치 내 finalOps + retryFlux 혼재 시 재시도 메시지 실수 ACK 위험 (BUG-9 참조)

---

## [DEPLOY BLOCKER] application-backup.properties 개발 URL 활성화 (2026-04-21 확인)

**상태**: 운영 배포 전 반드시 복구 필요

**내용**:
```properties
# 현재 (잘못됨)
file.ipath.load_balancer_server=http://172.21.0.27:8080   ← 개발 URL
backup.source.file.url=http://172.21.0.27:8080/iPath/api/request/file

# 복구 필요
file.ipath.load_balancer_server=http://10.177.18.138:8080  ← 운영 URL
```

**Why:** backup 프로파일로 배포 시 개발 서버로 요청이 전송됨. 운영 배포 즉시 장애 발생.
**How to apply:** backup 프로파일 배포 전 반드시 이 파일의 URL 확인.
