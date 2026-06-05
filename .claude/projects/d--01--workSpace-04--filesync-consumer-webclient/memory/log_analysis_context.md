---
name: log_analysis_context
description: 로그 파일 위치, 명명 규칙, 분석 패턴, docs 참고 경로 — 장애 분석 시 바로 활용
type: reference
---

## 로그 파일 위치 (프로젝트 내)

```
logs/
├── ewas1_consumer/fileSyncConsumer.log        # 현재 로그
├── ewas1_consumer/fileSyncConsumer_1.log      # 롤오버 로그
├── ewas2_consumer/fileSyncConsumer.log
├── ewas2_consumer/fileSyncConsumer_1.log
├── iwas1_consumer/fileSyncConsumer.log
├── iwas1_consumer/fileSyncConsumer_1.log
├── iwas2_consumer/fileSyncConsumer.log
├── iwas2_consumer/fileSyncConsumer_1.log
├── back1_consumer/fileSyncConsumer.log
├── back2_consumer/fileSyncConsumer.log
├── ewas1_LB/fileSyncLoadBalancer.log
├── ewas1_LB/fileSyncLoadBalancer_1.log        # LB 롤오버 로그
└── iwas1_LB/fileSyncLoadBalancer.log
```

## 핵심 로그 패턴

### Consumer 로그 태그
- `[RECV ]` 수신, `[DLQ  ]` DLQ 분기, `[START]` 다운로드 시작
- `[HEAD ]` 헤더 조회, `[DOWN ]` 다운로드, `[RETRY]` 재시도
- `[ACK  ]` ACK 완료, `[NACK ]` NACK 완료

### 주요 에러 패턴
| 패턴 | 의미 |
|------|------|
| `500 Internal Server Error` | 다운로드 실패 (fatal=false → DLQ 재시도) |
| `503 Service Unavailable` | 파일 서버 불가 (CB 임계치 누적 위험) |
| `PrematureCloseException` | 백엔드 연결 강제 종료 (LB에서 500 변환) |
| `HANG 판정` | RMHeartbeatMonitor가 처리 HANG 감지 → 재시작 |
| `RECOVERY_AUDIT ... Not found FileQ` | recoveryQueue 메시지의 cNo가 DB에 없음 |
| `CallNotPermittedException: CircuitBreaker ... OPEN` | CB OPEN 중 즉시 NACK |
| `Channel closed; cannot ack/nack` | AMQP 채널 소멸 → 미ACK 재전달 주의 |

### LB 로그 패턴
```
[TRANSFER] 완료 | {source} → {route} → {backend} | {method} {path} | {status} | ...
[TRANSFER] 오류 | {source} → ? | {method} {path} | 원인: {exception}
```

## docs/ 내 참고 문서

- `docs/guides/LOG-ANALYSIS-GUIDE.md` — 상세 분석 명령어 및 케이스별 대응 (9가지 케이스)
- `docs/incidents/incident-2026-03-27.md` — 2026-03-27 복합 장애 전체 타임라인
- `docs/changes/CHANGES.md` — 전체 변경 이력 (아키텍처 변경 포함)
- `docs/plans/2026-03-27-cb-health-probe.md` — RMUpstreamHealthProbe 구현 계획
- `docs/plans/2026-04-06-control-endpoint.md` — control endpoint 구현 계획 (설계 진행 중, 2026-04-06)
