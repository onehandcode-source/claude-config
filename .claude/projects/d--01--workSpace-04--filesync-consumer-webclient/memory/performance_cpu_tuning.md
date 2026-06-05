---
name: performance_cpu_tuning
description: 운영 CPU 100% 스파이크 분석 — 동시 HTTP 요청 수 공식, 설정 원칙 (2026-04-14)
type: project
---

## 배경

운영 서버에서 간헐적 CPU 100% 스파이크 발생. 2026-04-14 세션에서 코드 분석 완료.

## 최대 동시 HTTP 요청 수 공식

```
최대 동시 HTTP 요청 = 리스너 수(3) × MAX_CONCURRENT_CONSUMERS × BATCH_SIZE × FileDownloadService.CONCURRENCY(10)
```

CPU burst 조정 시 이 값을 기준으로 `BATCH_SIZE` 또는 `MAX_CONCURRENT_CONSUMERS`를 조정한다.

## 설정 원칙

- **`PREFETCH_COUNT`는 반드시 `BATCH_SIZE`와 동일하게 유지**: 불일치 시 PREFETCH가 실질적 limiter가 되어 BATCH_SIZE 의미 상실
- **`flatMap` concurrency 인자는 불필요**: BATCH_SIZE가 단일 제어 지점이므로 별도 인자 중복
- **recoveryListener는 `SINGLE_*` 상수 사용**: mainListener·archiveListener는 기본 상수 사용 — 두 세트 혼용 금지

## 관련 상수 위치

- `Consumer.java` 또는 `MessageBatchProcessorService.java` 내 static final 상수
- `FileDownloadService.CONCURRENCY = 10` (병렬 청크 다운로드 동시 수)

## CLAUDE.md 추가 여부

2026-04-14 세션에서 CLAUDE.md 업데이트 제안 (`적용할까요?`) 후 미적용 상태.
다음 세션에서 Architecture 섹션에 `### CPU 튜닝 수식` 항목 추가 여부 확인 필요.

**Why:** CPU 스파이크 재발 시 매번 코드 전체를 읽지 않아도 즉시 분석 가능
**How to apply:** CPU 이슈 보고 시 공식으로 최대 동시 요청 수 계산 → 어느 상수를 줄일지 판단
