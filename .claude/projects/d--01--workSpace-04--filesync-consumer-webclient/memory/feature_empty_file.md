---
name: feature_empty_file
description: 0KB 빈 파일 처리 기능 — 파일 없음(4xx) 또는 0 bytes 시 빈 파일 생성 후 정상 라우팅과 동일하게 ACK 처리 (2026-04-08 구현)
type: project
---

## 배경

운영 환경에서 파일 업로드 시스템의 크기 체크 로직 부재로 0 bytes 파일이 NAS에 올라오는 경우 발생.
기존에는 400/0 bytes → DLQ로 보내지는 문제가 있었음.

## 처리 규칙 (2026-04-21 확정)

- **파일 없음 (4xx 응답)** 또는 **0 bytes (Content-Length=0)**: 0KB 빈 파일 생성 → ACK
- DLQ 미진입 (재시도 없음)
- DB 업데이트: `queueStt` = 정상 라우팅 상태 그대로 (`returnQueueStt()` 결과)
- **ETC_N_COL1=99는 사용하지 않음** — 초기 설계 의도였으나 폐기. 99 특수값 코드 정책 없음.
- 빈 파일 여부는 로그의 `[EMPTY]` 태그로만 확인

## 구현 파일 (2026-04-08)

| 파일 | 변경 내용 |
|------|---------|
| `AckDto.java` | `boolean emptyFile` 필드 추가 (정상 라우팅과 동일하게 ACK 처리) |
| `FileHandlerService.java` | `handleFileDownloadAndSave` → `Mono<Boolean>` (true=emptyFile), `isEmptyFileError()` 헬퍼 |
| `MessageProcessingService.java` | `messageProcessing` 반환 타입 `Mono<Boolean>` (`.then()` 제거) |
| `MessageBatchProcessorService.java` | `.map(isEmpty → AckDto.emptyFile=isEmpty)` + `.switchIfEmpty()` 추가 |

## 핵심 패턴: AckDto 확장

새로운 처리 경로(특수 상태값) 추가 시 사용하는 패턴:
1. `AckDto`에 boolean 플래그 추가
2. `handleFileDownloadAndSave`에서 `Mono<Boolean>` 신호 전달
3. `MessageBatchProcessorService`에서 `.map()` + `.switchIfEmpty()`로 AckDto 빌드
4. `handleUpdateAndAck`에서 플래그 체크 → 필요 시 queueStt 오버라이드

## 기술 세부사항

- 4xx 감지: `WebClientResponseException.getRawStatusCode()` ∈ [400, 500)
- 0 bytes 감지: `IllegalStateException` 메시지에 `"0 bytes"` 포함
- emptyFile 신호: `FileDto.builder().fileSize(0L).build()` (내부 신호, enum 없음)
- `CircuitBreakerOperator.of(cb)`는 `Mono<Boolean>`에도 직접 적용 가능 (`.then()` 불필요)

**Why:** 운영 환경에서 0KB 파일이 DLQ에 쌓이는 문제 해소.
**How to apply:** 유사한 특수 처리 경로 추가 시 이 패턴을 참조.
