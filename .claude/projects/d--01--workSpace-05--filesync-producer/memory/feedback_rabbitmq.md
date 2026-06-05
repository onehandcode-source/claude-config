---
name: RabbitMQ 운영 제약 및 설계 주의사항
description: 이 환경의 RabbitMQ 운영 제약, 플러그인 설치 방식, 버전 호환성
type: feedback
---

## RabbitMQ 환경 사양 (2026-04-21)

- 버전: RabbitMQ 4.1.3 (`rabbitmq-server-4.1.3-1.el8.noarch`)
- Erlang: 27.3 (`esl-erlang_27.3_1~centos~8_x86_64`)
- OS: CentOS 8
- 설치 방식: 인터넷 불가 환경, rpm 파일을 rpm2cpio로 수동 설치
- 계정: 비관리자 계정 사용 (admin 계정 아님)
- 플러그인 파일 설치 가능: plugins 디렉토리 수동 배치 후 `rabbitmq-plugins enable` 방식 가능

---

## rabbitmq-message-deduplication 플러그인 적용 (2026-04-21 확정)

4.1.3 호환 .ez 파일 존재 확인됨. 큐 재선언도 가능. **플러그인 방식으로 진행 결정.**

설계 문서: `doc/plans/2026-04-21-message-deduplication-design.md`

핵심 적용 내용:
- Queue 선언 시 `x-message-deduplication: true`, `x-cache-ttl: 300000`, `x-cache-size: 50000` 인수 추가 (`RMInitializer.java`)
- 메시지 발행 시 `x-deduplication-header: {cNo}` 헤더 추가 (`RabbitMqService.java`)
- 기존 큐 삭제 후 앱 재시작으로 재선언 (미처리 메시지 드레인 후 새벽 시간대 권장)

**How to apply:** 중복 메시지 방지 관련 추가 작업 시 위 설계 문서 참조.
