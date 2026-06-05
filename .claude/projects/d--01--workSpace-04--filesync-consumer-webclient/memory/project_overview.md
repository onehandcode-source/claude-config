---
name: project_overview
description: filesync-consumer-webclient 프로젝트 개요 — 아키텍처, 서버 구성, 큐 구조
type: project
---

## 시스템 개요

Java Spring Boot 기반 RabbitMQ 파일 동기화 Consumer 서비스. 메시지를 수신하여 파일 서버에서 파일을 다운로드하고 백업한다.

## 서버 구성

| 서버 | IP | 역할 |
|------|-----|------|
| ewas1_consumer | 10.176.62.211:8082 | eQueue consumer |
| ewas2_consumer | 10.176.62.212:8082 | eQueue consumer |
| iwas1_consumer | — | iQueue consumer |
| iwas2_consumer | — | iQueue consumer |
| back1_consumer | — | archiveQueue (백업) consumer |
| back2_consumer | — | archiveQueue (백업) consumer |
| ewas_LB | 27.101.236.83:8080 | ePath 파일 요청 LB (Spring Cloud Gateway) |
| iwas_LB | 10.177.18.138:8080 | iPath 파일 요청 LB |
| anl1 | 10.177.18.138 | 파일 원본 서버 (iPath/eService) |
| anl2 | 10.177.18.139 | 파일 원본 서버 (iPath/eService) |
| DB | 10.176.62.215/216:8080 | Tibero DB (이중화) |

## 큐 구조

| 큐 | Listener | 서킷브레이커 |
|----|---------|------------|
| eQueue | mainListener | filesync-main |
| iQueue | mainListener | filesync-main |
| archiveQueue | archiveListener | (CB 미적용, BackupSyncService 직접 HTTP 호출) |
| eRecoveryQueue / iRecoveryQueue | recoveryListener | filesync-recovery |

## 파일 요청 URL 설정

- `file.epath.load_balancer_server=http://27.101.236.83:8080`
- `file.ipath.load_balancer_server=http://10.177.18.138:8080`
- `file.backup.load_balancer_server=http://10.188.142.189:8080`
- `backup.server.trigger.url=http://10.188.142.189:8080/bPath/api/trigger/archive`

## Producer Job 활성화 상태 (2026-04-21 확인)

Producer 애플리케이션의 스케줄러 Job 현황:
- **SyncQueueJob** (10초마다): ✅ **활성** — `cSendSt=0,3` + `queueInSt=0` 레코드 조회 → MQ 발행
- **BackupQueueJob** (`*/30 * 1-6 * * *`): 🔴 **주석처리** — 새벽 1~6시 사이 30초마다 500건 백업 처리
- **RecoveryQueueJob** (10초마다): 🔴 **주석처리**
- **FailQueueJob** (10초마다): 🔴 **주석처리**

**How to apply**: BackupJob/RecoveryJob 미활성 상태에서 운영 중. 백업/복원 프로세스 이슈 발생 시 Job 활성화 여부 확인 필요.

## 주요 컴포넌트

- **RMHeartbeatMonitor**: 30초 주기로 리스너 처리 HANG 감지 및 자동 재시작
- **RMListenerMetrics**: 리스너별 inFlight 메시지 수 추적 (receive/complete)
- **CBListenerConfig**: CB 상태 변화(OPEN/HALF_OPEN/CLOSED) 이벤트 핸들러 — mainListener 제어
- **RMUpstreamHealthProbe**: CB OPEN 상태에서 30초 주기로 upstream HEAD probe → 복구 감지 시 수동 HALF_OPEN 전환 (2026-03-27 이후 추가)
- **DlqRetryProcessService**: dlqCount > 3 이면 FINAL_DLQ 처리 (updateFail + ACK)
- **MessageBatchProcessorService**: 배치 메시지 병렬 처리, 재시도, 서킷브레이커 연동
- **BackupSyncService**: archiveQueue 전용 — 백업 서버에 HTTP POST 요청 후 응답 처리

## QUEUE_STT 상태 코드 (ETC_N_COL1)

| 값 | Enum | 의미 |
|----|------|------|
| 0 | READY | 처리 대기 (초기값) |
| 1 | QUEUE_IN | 작업 큐 등록됨 |
| 2 | SUCCESS | 완료 |
| 3 | FAIL | DLQ 재시도 대기 |
| 4 | DLQ_FINAL | 최종 실패 (담당자 확인 필요) |
| 5 | BACKUP | eQueue/iQueue 완료 후 → Producer가 archiveQueue 발행 대기 |
| 6 | BACKUP_SUCCESS | archiveQueue 완료 (백업 완료) |
| 7 | IRECOVERY_BACKUP | 백업서버→업무망 복원 대상 |
| 8 | ERECOVERY_BACKUP | 업무망→인터넷망 복원 대상 |
| 9 | PRIORITY | 우선순위 처리 대상 |
| 10 | DLQ_PENDING | fatal 실패 확정, Producer가 fQueue 발행 대기 |
| 99 | (enum 없음) | 파일 없음(4xx) 또는 0 bytes → 0KB 빈 파일 생성된 케이스. **현재 코드는 정상 라우팅 queueStt 사용** (feature_empty_file.md 참조) |

정상 완료 흐름: `(C_SEND_ST=1, ETC_N_COL1=5)` → Producer archiveQueue 발행 → `(1, 6)` 최종

**Why:** 운영 장애 분석 시 컨텍스트 복구 속도를 높이기 위해 저장
**How to apply:** 장애 분석, 코드 리뷰, 설정 변경 시 이 구조를 기반으로 빠르게 판단
