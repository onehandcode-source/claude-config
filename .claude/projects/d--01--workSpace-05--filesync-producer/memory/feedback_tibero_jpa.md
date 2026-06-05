---
name: Tibero/Oracle JPA 쿼리 주의사항
description: Tibero(Oracle 호환) 환경에서 JPA native query + pagination, 배치 UPDATE 락 방지, @DynamicUpdate 주의사항
type: feedback
---

Tibero는 Oracle 호환 DB이므로 MySQL 문법의 `LIMIT` 절을 **지원하지 않는다**. Hibernate는 Oracle 방언으로 `ROWNUM <= ?` 형태로 변환한다.

**Why:** `nativeQuery = true` + projection interface(`List<SomeDto>`) 조합에서 Hibernate가 `Pageable`의 LIMIT을 SQL에 반영하지 않는 경우가 있다. 특히 `LEFT JOIN ... IS NULL` 같은 복잡한 native query에서 발생했고, ORDER BY 없이 커서 페이징을 쓰면 결과가 비결정적이다.

**How to apply:**
- Native query에서 페이징: `Pageable` 파라미터 + `ORDER BY` 필수 명시 (Hibernate가 ROWNUM으로 변환). MySQL 문법의 `LIMIT ?` 직접 작성 금지.
- `findBackupTargets` 사례: `Pageable pageable` + `ORDER BY FQ.C_NO`로 수정 후 `where rownum <= ?` 정상 적용 확인됨.
- `findByBackupQueue`: `JOIN FETCH` + `Pageable` 조합은 `@ManyToOne`에서만 안전. `@OneToMany`에서 쓰면 Hibernate가 in-memory pagination 경고(`HHH90003004`)를 내고 메모리에서 자름.
- 대량 배치 insert 후 native query를 재조회할 때는 `entityManager.flush()` + `entityManager.clear()` 명시 필요 (Hibernate 자동 flush가 native query 전에 보장되지 않음).

---

## NULL 컬럼 인덱스 미사용 문제

`(col IS NULL OR col IN ?)` 패턴은 B-tree 인덱스를 타지 못해 **Full Table Scan** 발생.

**Why:** Oracle/Tibero B-tree 인덱스는 NULL 값을 저장하지 않는다. `IS NULL` 조건이 포함되면 옵티마이저가 인덱스를 포기한다.

**How to apply:** `COALESCE(col, 0) IN ?` 으로 대체. 실제 사례: `findBySyncQueue`의 `fq.etcNCol1 IS NULL OR fq.etcNCol1 IN ?3` → `COALESCE(FQ.ETC_N_COL1, 0) IN ?3` (2026-04-06 수정).

---

## Oracle 옵티마이저 힌트

JPQL은 `/*+ ... */` 힌트를 **지원하지 않는다**. 힌트가 필요한 쿼리는 반드시 `nativeQuery = true`로 전환해야 한다.

**How to apply:**
- 힌트 별칭은 FROM 절에서 선언한 테이블 별칭 기준: `/*+ INDEX(FQ IDX_TBL_FILEQ_002) */`
- TBL_FILEQ 인덱스: `C_DATE` 기준 → `IDX_TBL_FILEQ_002`, `C_NO` 기준 → `SAFEIDB_CNO76000427`
- 실행 계획 캐시 초기화: `ALTER SYSTEM FLUSH SHARED_POOL` (DBA 권한 필요, 운영 트래픽 없는 시간대 수행)

---

## cursor 페이징 주의사항

`no > lastNo` 커서 방식은 반드시 `ORDER BY C_NO` 명시 필수.

**Why:** ORDER BY 없으면 Hibernate Oracle10gDialect의 ROWNUM wrapping이 오동작하고, 커서 기반 `lastNo = list.get(last).getNo()` 값이 비결정적이 되어 **재처리(중복) 또는 누락** 발생.

---

## 대용량 테이블 배치 UPDATE 락 방지 패턴 (2026-04-09)

1.5억건 테이블 업데이트 시 단일 UPDATE 쿼리는 장시간 락 점유 → 다른 트랜잭션 블로킹.

**How to apply:**
- Repository: `nativeQuery=true` + `AND ROWNUM <= 100` → 한번에 최대 100건만 UPDATE (ORDER BY 없어도 무방, 어떤 100건이든 동일 목적)
- Service: `@Transactional(propagation = REQUIRES_NEW)` → 배치마다 독립 트랜잭션으로 커밋 → 락 즉시 해제
- Caller: `do { count = service.batchUpdate(); total += count; } while (count > 0);` 루프로 전체 처리
- JPQL은 `ROWNUM` 미지원 → 반드시 `nativeQuery = true` 사용

---

## @DynamicUpdate 주의사항

`@DynamicUpdate` 엔티티에서 DB에 이미 같은 값이 있는 필드를 `setXxx()`로 설정하면 **dirty하지 않아 UPDATE SQL에서 제외**됨.

**Why:** Hibernate가 로드 시점 스냅샷 대비 변경된 필드만 포함. `setQueueStt(6)` 호출해도 DB 값이 이미 6이면 UPDATE 없음 → 다른 필드(bakDate 등)만 UPDATE됨.

**How to apply:** `@DynamicUpdate` 엔티티 수정 시 "이미 해당 값인 경우" 시나리오를 반드시 고려. 의심 시 DB에서 실제 컬럼 값 직접 확인 (`SELECT QUEUE_STT FROM TBL_FILEQ_BACKUP WHERE ...`).
