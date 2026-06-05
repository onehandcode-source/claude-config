---
name: 프로젝트 현재 상태
description: filesync_producer v0.4 브랜치 현재 작업 상태 및 최근 수정 이력
type: project
---

현재 브랜치: `finesync_producer_v0.4`

**Why:** 인터넷망 ↔ 업무망 ↔ 백업망 간 파일 동기화 시스템 개발 중. Producer는 Tibero DB를 폴링하여 RabbitMQ에 메시지를 발행하는 데몬.

---

## 스케줄러 구성 (2026-04-21 현재 실제 코드 기준)

Producer.java는 4개의 `@Scheduled` 메서드 모두 **활성 상태**:

| 메서드 | 주기 | Job |
|---|---|---|
| `scheduleFileTransfer` | fixedDelay **10초** | SyncQueueJob |
| `scheduleFileRecoveryTransfer` | fixedDelay **10초** | RecoveryQueueJob |
| `scheduleFileFailTransfer` | fixedDelay **10초** | FailQueueJob |
| `scheduleFileBackupTransfer` | fixedDelay **5초** (cron `*/30 * 1-6 * * *` 주석처리) | BackupQueueJob |

> **2026-04-21 기준 4개 Job 모두 활성**. BackupQueueJob은 현재 fixedDelay=5000(5초)로 실행 중 (개발/테스트 모드). 운영 배포 전 cron `0 */1 1-6 * * *` 로 복원 필요.

---

## 진행 중인 설계: 메시지 중복 방지 (2026-04-21)

**문제 지점**: `FileQStateUpdateService.addToQueue()` — MQ 전송 성공 → DB QUEUE_IN 업데이트 실패 → 다음 10초 주기에 같은 레코드 재발행 → 중복 발행.
코드 주석에도 명시됨: `// MQ에는 이미 발행됨. DB 업데이트 실패 시 다음 주기에 중복 발행 가능`

**검토한 3가지 접근법:**
- **방법 A (DB 선 업데이트)**: MQ 발행 전 DB를 QUEUE_IN(1)으로 선 마킹 → 다음 쿼리에서 제외 → 근본 해결. 팬텀 레코드 복구 로직 필요.
- **방법 B (rabbitmq-message-deduplication 플러그인)**: 큐에 `x-message-deduplication: true` 필요 → **기존 큐 재선언 불가로 차단됨**.
- **방법 C (Producer 인메모리 캐시)**: 앱 재시작 시 유실, 방법 A와 병행 가능.

**현재 상태**: 방법 B 차단 확인, 방법 A 또는 A+C 방향으로 재협의 예정.

---

## RabbitMQ 환경 정보 (2026-04-21 확인)

- 버전: **RabbitMQ 4.1.3** (`rabbitmq-server-4.1.3-1.el8.noarch`)
- Erlang: **27.3** (`esl-erlang_27.3_1~centos~8_x86_64`)
- OS: CentOS 8, 오프라인(인터넷 불가) 환경, rpm2cpio로 수동 설치
- 비관리자 계정으로 운영 중
- **플러그인 설치 가능**: .ez 파일 plugins 디렉토리 수동 배치 방식으로 가능
- **큐 재선언 불가**: 운영 중 기존 큐 삭제/재생성 불허

---

## Tibero 실행 계획 변화 조사 패턴 (2026-04-20)

특정 시각(21시) 이후 쿼리 성능 저하 발생 시 조사 방법:
```sql
-- 실행 계획 변경 여부 (plan_hash_value 비교)
SELECT sql_id, first_load_time, last_active_time, executions, plan_hash_value, sql_text
FROM v$sql
WHERE UPPER(sql_text) LIKE '%ETC_N_COL1%'
ORDER BY last_active_time DESC;

-- DB 재기동 시각 확인
SELECT startup_time FROM v$instance;

-- 자동 통계 수집 잡 스케줄 확인
SELECT job_name, enabled, schedule_name
FROM dba_scheduler_jobs
WHERE job_name LIKE '%GATHER_STATS%';
```
원인 후보: 21시 Tibero 자동 통계 수집 잡 실행 → NULL 비율 변경 → 인덱스 사용 여부 변화.

---

## 최근 수정된 핵심 버그들 (2026-03월~04월 기준)

1. `findBackupTargets` 페이징 미작동 — Pageable 파라미터만으로는 native query에서 ROWNUM 적용 안 됨. `ORDER BY FQ.C_NO` 추가로 해결.
2. `findByBackupQueue` — `size` 파라미터를 받았지만 쿼리에서 무시 → 전체 조회. `Pageable`로 수정.
3. `BackupQueueJob` LazyInitializationException — `FileQBackup.fileQ`는 `@ManyToOne(LAZY)`. `@Scheduled` 메서드에서 트랜잭션 없이 `fb.getFileQ()` 호출 시 예외. → `FileQBackupService.findBackupQueueWithFileQ` `@Transactional(readOnly=true)` 범위 내에서 proxy 초기화 후 `List<FileQ>` 반환으로 해결.
4. `BackupQueueJob.insertBackupTargets()` — 배치 insert 후 `entityManager.flush()/clear()` 추가.
5. `FileQueueStateUpdateService` → `FileQStateUpdateService`로 파일명 변경됨.
6. `SyncQueueJob.findBySyncQueue` 성능 튜닝 (2026-04-06):
   - JPQL → nativeQuery로 전환 (Oracle 힌트 적용 위해)
   - `(etcNCol1 IS NULL OR etcNCol1 IN ?)` → `COALESCE(ETC_N_COL1, 0) IN ?` (인덱스 활용)
   - `ORDER BY FQ.C_NO` 추가 (커서 페이징 정확성)
   - `/*+ INDEX(FQ IDX_TBL_FILEQ_002) */` 힌트 추가
7. **emptyFile queueStt=99 체인 단절 수정 (2026-04-17)**:
   - 빈 파일 요청 시 `queueStt=99`로 업데이트 → BACKUP(5)/BACKUP_SUCCESS(6) 신호가 Producer에 전달 안 됨 → 복원 체인 단절
   - 결론: 라우팅은 정상값(`ConsumerUtil.returnQueueStt`)으로, 손상 이력은 로그(`[EMPTY] process=빈파일생성완료`)로만 기록

---

## BackupQueueJob 구조 (2026-04-21, 활성화됨)

**처리 흐름 (현재 fixedDelay=5초)**:
```
[1단계] FileQ → FileQBackup INSERT 500건
         cDate: 오늘-7일 ~ 오늘-3일, etcNCol1=5, LEFT JOIN IS NULL(중복방지)
         lastInsertNo(AtomicInteger)부터 커서 조회 → 앱 재시작 시 0으로 초기화
              ↓
[2단계] FileQBackup WHERE queueStt=5 → 500건 조회 → MQ 전송
```

**설계 원칙**:
- INSERT와 MQ 전송 완전 분리: INSERT는 FileQ 기준, MQ 전송은 FileQBackup 기준
- 날짜 범위 `-7일~-3일`은 의도적 고정 (변경 금지)

---

## stuck 방어코드 패턴: resetStuckQueueInToBackup

**stuck 조건**: `TBL_FILEQ_BACKUP.QUEUE_STT=1` AND `TBL_FILEQ.ETC_N_COL1=6`
- 컨슈머가 FileQ.etcNCol1=6 업데이트 후 FileQBackup 업데이트 누락한 케이스

**락 방지 구현**:
- Repository: `nativeQuery=true` + `AND ROWNUM <= 100` → 한번에 최대 100건만 UPDATE
- Service: `@Transactional(propagation = REQUIRES_NEW)` → 배치마다 독립 트랜잭션, 락 즉시 해제
- Job: `do { batchCount = service.resetStuck(); total += batchCount; } while (batchCount > 0);`

---

**How to apply:** 스케줄러 변경이나 쿼리 수정 시 위 버그들이 재발하지 않았는지 확인. nativeQuery 전환 시 Oracle 힌트·COALESCE 패턴·ORDER BY 함께 검토. BackupQueueJob 운영 배포 전 cron 주기 복원 확인 필수.
