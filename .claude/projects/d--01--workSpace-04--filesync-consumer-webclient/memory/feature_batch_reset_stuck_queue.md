---
name: feature_batch_reset_stuck_queue
description: resetStuckQueueInToBackup 배치 최적화 (2026-04-09): ROWNUM 100건, REQUIRES_NEW, INDEX 힌트 필수
type: project
---

## resetStuckQueueInToBackup 배치 최적화 (2026-04-09)

**배경**: TBL_FILEQ 테이블에 1.5억 건 이상 존재. stuck 상태 큐를 백업 초기화하는 배치 작업에서 락 발생 우려.

**구현 위치**:
- `FileQBackupRepository.resetStuckQueueInToBackup` — Native Query
- `FileQBackupService` — `@Transactional(REQUIRES_NEW)`
- `BackupQueueJob` — do-while 루프

**핵심 설계 결정**:

### 1. ROWNUM 위치는 서브쿼리 안
```sql
UPDATE TBL_FILEQ_BACKUP fb SET ...
WHERE fb.FILEQ_C_NO IN (
  SELECT /*+ INDEX(fq IDX_TBL_FILEQ_002) */ fq.NO FROM TBL_FILEQ fq
  WHERE fq.C_DATE >= :sDate AND fq.C_DATE <= :eDate
  AND fq.ETC_N_COL1 = :etcNCol1
  AND ROWNUM <= 100   ← 서브쿼리 안에! 외부 UPDATE에는 ROWNUM 적용 불가
)
AND fb.QUEUE_STT = 'STUCK'
```

### 2. INDEX 힌트 필수
`/*+ INDEX(fq IDX_TBL_FILEQ_002) */` — C_DATE 범위 필터 시 옵티마이저 Full Scan 방지.
1.5억 건에서 UPDATE 서브쿼리는 SELECT보다 실행계획 예측이 더 어려워 힌트가 없으면 Full Scan 선택 가능성 높음. 기존 FileQRepository 쿼리와 동일한 패턴으로 일관성 유지.

### 3. REQUIRES_NEW 트랜잭션
배치 1회(100건) 완료 시 독립 트랜잭션 커밋 → 락 즉시 해제 → 다음 배치 실행.

### 4. BackupQueueJob do-while 루프
```java
int updated;
do {
    updated = fileQBackupService.resetStuckQueueInToBackup(...);
} while (updated > 0);
```
결과 0건이 나올 때까지 반복 처리.

**Why:** 락 발생을 배치 1회 커밋마다 해제하여 1.5억 건 대용량 테이블에서 다른 트랜잭션 블로킹 방지.
**How to apply:** 유사한 대용량 테이블 배치 UPDATE 시 동일 패턴(ROWNUM 서브쿼리+REQUIRES_NEW+do-while+INDEX힌트) 적용.
