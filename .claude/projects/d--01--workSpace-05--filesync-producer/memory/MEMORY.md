# MEMORY.md

Memory index for filesync_producer project.

- [User Profile](user_profile.md) — 한국 공공기관 백엔드 개발자, Java/Spring Boot/RabbitMQ/Tibero, 한국어 소통
- [Tibero/Oracle JPA 주의사항](feedback_tibero_jpa.md) — NULL 인덱스·COALESCE, Oracle 힌트 nativeQuery, ROWNUM 배치 UPDATE 락 방지, @DynamicUpdate 동일값 dirty 미감지
- [프로젝트 현재 상태](project_state.md) — 4개 Job 모두 활성, BackupQueueJob fixedDelay=5초(운영 배포 전 cron 복원 필요), 메시지 중복 방지 설계 진행 중
- [커뮤니케이션 방식](feedback_communication.md) — 한국어 필수, 실행 로그 기반 결과 확인 선호
- [RabbitMQ 운영 제약](feedback_rabbitmq.md) — 큐 재선언 불가, deduplication 플러그인 차단됨, 4.1.3/Erlang27.3/CentOS8/rpm2cpio 환경
