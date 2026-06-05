---
name: open_bugs
description: 버그 목록 — Consumer 코드에서 발견된 버그와 원인 분석 결과 (2026-04-21 기준)
type: project
---

## [BUG-1] DlqRetryProcessService — 최종 DLQ 처리 중 unacked 상태 고착 ✅ FIXED 2026-04-03

**수정 내용**: `finalOps` flatMap 내 `Mono.fromRunnable()` 이후 `onErrorResume(IllegalStateException.class)` 추가.
DB 레코드 없음 시 RECOVERY_AUDIT 로거에 에러 기록 + `Mono.empty()` 반환 → ACK 처리됨.

---

## [BUG-2] C_SEND_ST=0, ETC_N_COL1=5 레코드 지속 발생

**상태**: 근본 원인 미확정 (Consumer 코드 범위 내 원인 특정 불가)

**추정 원인 (Producer 측)**: Producer가 `ETC_N_COL1=5` 레코드를 archiveQueue 발행 대상으로 클레임할 때 `C_SEND_ST=0`으로 리셋하는 UPDATE 수행 추정. 이후 archiveQueue 처리 실패 or Consumer 최종 업데이트 실패 시 `(0, 5)` 상태 고착.

**단서**: `FileQRepository.updateEtcNCol1Only` 주석 — "backupProcess에서 C_SEND_ST 덮어쓰기 방지 목적" → 과거에 Producer가 C_SEND_ST를 덮어쓰는 이슈가 있었던 흔적.

**Why:** Consumer 코드만으로는 이 상태를 생성할 수 없음. Producer 코드 확인 필요.
**How to apply:** C_SEND_ST 관련 이슈 논의 시 이 분석을 기반으로 Producer 코드 확인 방향 제시.

---

## [BUG-3] FileQ.singoNo primitive int → C_SINGO_NO null 시 unacked 고착 ✅ FIXED 2026-04-07

**수정 내용**: `private int singoNo` → `private Integer singoNo`

**주의**: `FileQ.cDirection`, `FileQ.cSendSt` 도 primitive `int`로 선언. nullable DB 컬럼이면 동일 위험 존재.

**Why**: nullable DB 컬럼을 primitive 타입에 매핑하면 Hibernate unboxing 시 NPE → ACK/NACK 이전 예외 전파 → unacked 고착.

---

## [BUG-4] recoveryListener — TBL_FILEQ_BACKUP.QUEUE_STT 8 미반영 → 1 고착 ✅ FIXED 2026-04-09

**수정 내용 (FileQBackupService.java)**: `find → set → save` 제거 → 직접 JPQL `@Modifying` UPDATE 쿼리 3종 추가.

**Why**: JPA dirty checking 기반 save()는 트랜잭션 경계·캐시 타이밍에 따라 실제 UPDATE 미실행 가능. 직접 @Modifying JPQL이 안전.
**How to apply**: QUEUE_STT 업데이트 누락 재발 시 1) `updateQueueStt*` 메서드 UPDATE 0건 warn 로그 확인, 2) RECOVERY_QUEUE_NAME 값 확인.

---

## [BUG-5] iRecoveryQueue 복원 후 QUEUE_STT=1 고착 + ETC_N_COL1 미반영 (2026-04-16)

**상태**: 원인 분석 완료, 수정 미완 (DB 컬럼 존재 확인 필요)

**코드 위치**: `FileQService.java` — `updateSuccess()` 내 `updateAvChgFlag` 호출

```java
if (cSendSt == SUCCESS && queueStt == ERECOVERY_BACKUP(8)) {
    fileQueueRepository.updateAvChgFlag(cNo, "N");  // ← 예외 시 @Transactional rollback
}
```
- `updateAvChgFlag` 예외 → `@Transactional` rollback → `updateSuccessCols`도 rollback → `ETC_N_COL1` 원복
- 예외가 `handleUpdateAndAck`로 propagate → `updateBackupRecovery` 호출 안 됨 → `queue_stt=1` 유지

**발생 경위**: 2026-04-14 커밋에서 `save()` → `@Modifying UPDATE`로 변환 시, JPA 캐시로 no-op이었던 `updateAvChgFlag`가 실제 SQL로 실행되기 시작 → `TBL_FILEQ.AV_CHG_FLAG` 컬럼이 DB에 없으면 SQL 에러.

**확인 SQL**: `SELECT COUNT(*) FROM USER_TAB_COLUMNS WHERE TABLE_NAME='TBL_FILEQ' AND COLUMN_NAME='AV_CHG_FLAG';`

**수정 방향**:
- 컬럼 없음 확인 시: `ALTER TABLE TBL_FILEQ ADD (AV_CHG_FLAG VARCHAR2(1));`
- 단기: `updateAvChgFlag` 호출을 try-catch로 격리 → rollback 방지

**Why**: save()→@Modifying 변환 이후 기존에 no-op이던 updateAvChgFlag가 실제 SQL로 실행, 예외 시 상위 트랜잭션 전체 rollback되는 신규 경로 생성.
**How to apply**: iRecoveryQueue 처리 후 DB 미반영 재발 시 updateAvChgFlag SQL 에러 여부 + AV_CHG_FLAG 컬럼 존재 여부를 1순위로 확인.

---

## [BUG-6] 복원 경로에서 0KB 파일 전파 — 원본 파일 자체가 0KB (2026-04-17) ✅ 원인 확인

**조사 결과**: 백업망에 저장된 파일 자체가 0KB. 복원 경로를 따라 0KB 파일이 전파됨. Consumer의 0 bytes 판정 → `isEmptyFileError` → 빈 파일 생성 → 정상 라우팅 ACK 처리.

> **주의**: 초기 메모리에 "queueStt=99"로 기록되었으나 **99는 실제로 사용되지 않음** (2026-04-21 확정). `returnQueueStt()`는 99를 반환하지 않으며 emptyFile=true여도 정상 라우팅 상태(BACKUP 등)로 업데이트됨.

**근본 원인**: 백업망 저장 시점에서 파일이 0KB로 저장된 경위 확인 필요. Producer ImgCompressThread 타이밍 문제(2026-03-30 이슈) 또는 BUG-2와 연관 가능성.

**How to apply**: 복원 테스트 중 0KB 파일 발생 시 먼저 백업망(B_data1 경로)의 파일 실제 크기 확인.

---

## [BUG-7] Producer 무한 재발급 — Consumer DB 미업데이트 경로 (2026-04-20)

**상태**: `updateSuccess updated==0` 경로 → FileQService.java 에서 `warn+return` → `IllegalStateException` 으로 변경 **완료** (커밋 "fix; 피드백 수정", 2026-04-21). `updateAvChgFlag` rollback 경로(BUG-5)는 미해결.

**Consumer 측 확인된 두 가지 위험 경로**:
1. `updateAvChgFlag` 예외 → @Transactional rollback → `updateSuccessCols`도 rollback → DB ETC_N_COL1 미업데이트 → ACK 정상 → Producer가 READY(0) 상태로 재조회 → 재발급 (BUG-5와 동일 경로)
2. `updateSuccess updated==0` → (수정 전) silent return + ACK → DB 미업데이트 → 재발급. (수정 후) IllegalStateException → ACK → DLQ 경로

**확인 필요**: Producer 재발급 트리거 조건이 `ETC_N_COL1 IN (0, 9)`인지, QUEUE_IN(1)도 포함하는지.

**Why**: Consumer ACK 후 DB 미업데이트 상태를 남기는 경로가 Producer 무한 재발급의 근본 원인.
**How to apply**: 무한 재발급 이슈 시 → 해당 cNo의 ETC_N_COL1 현재 값 확인 → 0 또는 1이면 이 경로 의심.

---

## [BUG-8] CBConfig ignoreException 커스터마이저 이름 불일치 — 미적용 상태 (2026-04-21)

**상태**: 발견됨, 수정 미완

**위치**: `CBConfig.java`

```java
private static final String CIRCUIT_BREAKER_NAME = "filesync";  // ← 잘못된 이름
return CircuitBreakerConfigCustomizer.of(CIRCUIT_BREAKER_NAME, builder ->
    builder.ignoreException(ex -> !ConsumerUtil.isRetryException(ex)));
```

**실제 CB 인스턴스 이름**: `filesync-main`, `filesync-recovery` (circuitbreaker.properties)

**영향**: CBConfig의 `ignoreException(ConsumerUtil.isRetryException)` 로직이 실제 CB에 전혀 적용되지 않음. 단, `circuitbreaker.properties`에 `ignore-exceptions=WebClientResponseException$NotFound`가 properties로 설정되어 있어 NotFound는 무시됨. `ConsumerUtil.isRetryException()`에서 정의한 나머지 예외 분류는 CB에 반영 안 됨.

**수정 방향**: `CIRCUIT_BREAKER_NAME = "filesync"` → `"filesync-main"`, `"filesync-recovery"` 각각 별도 Customizer 등록. 또는 properties의 `ignore-exceptions`로 통합.

**Why**: 이름 불일치로 Customizer가 실제 CB 인스턴스에 바인딩되지 않음. CB 장애 분류 로직이 의도한 대로 동작하지 않음.
**How to apply**: CB OPEN/CLOSE 동작이 예상과 다를 때 CBConfig ignoreException 적용 여부 확인.

---

## [BUG-9] DLQ finalOps — handleMessageMultiAck multiple=true → 재시도 메시지 실수 ACK 위험 (2026-04-21)

**상태**: 발견됨, 수정 미완

**위치**: `ConsumerUtil.handleMessageMultiAck()` → `channel.basicAck(highestTag, true)` (multiple=true)

**위험 시나리오**: 한 배치 내에 count>3 (finalOps 처리) + count≤3 (retryFlux 반환) 메시지가 혼재하고, finalOps 메시지의 delivery tag가 retryFlux 메시지 tag보다 높은 경우, `multiple=true` ACK이 retryFlux 메시지도 함께 ACK → 재시도 없이 메시지 소실.

**현재 흐름**:
```
finalOps → collectList → handleMessageMultiAck(basicAck(highestTag, true)) → .then()
→ thenMany(retryFlux) → 재시도 메시지 반환 (NACK은 caller가 처리)
```

**수정 방향**: `handleMessageMultiAck`에서 finalOps 용도는 개별 ACK(`multiple=false`)를 사용하거나, retryFlux 처리 이후에 finalOps ACK를 수행하도록 순서 변경.

**Why**: multiple=true는 해당 tag 이하의 모든 미ACK 메시지를 ACK함. 배치 내 tag 순서가 보장되지 않으면 의도치 않은 메시지 소실 위험.
**How to apply**: DLQ 재시도 메시지가 예상보다 빨리 사라지거나 finalDLQ에 도달하면 이 경로 확인.
