# Memory Index

- [user_language.md](user_language.md) — 사용자는 한국어로 응답받기를 원함
- [user_profile.md](user_profile.md) — 운영 장애 분석 중심 백엔드 개발자, 표/타임라인 형식 선호
- [project_overview.md](project_overview.md) — 시스템 구조(서버IP, 큐, CB, QUEUE_STT 전체 코드표, Producer Job 활성화 상태)
- [log_analysis_context.md](log_analysis_context.md) — 로그 파일 위치, 태그 패턴, 주요 에러 패턴 참조
- [incident_20260327.md](incident_20260327.md) — 2026-03-27 복합 장애(anl1 503→HANG오탐→CB재진입). P1 수정완료, [P2~P4] 미해결
- [incident_20260330.md](incident_20260330.md) — 2026-03-30 PrematureCloseException 500. Producer ImgCompressThread→외부압축서버→MQ 타이밍 문제 원인 확정
- [open_bugs.md](open_bugs.md) — BUG-1~4✅FIXED; BUG-6✅원인확인(99아님·정상라우팅); BUG-7 partial fix; [BUG-5]AV_CHG_FLAG rollback 미완; [BUG-8]CBConfig 이름불일치; [BUG-9]DLQ multiple=true 위험
- [feature_empty_file.md](feature_empty_file.md) — 0KB 빈 파일 처리(2026-04-08): 4xx/0bytes→빈파일생성, ETC_N_COL1=99 정책 폐기(정상라우팅 사용), AckDto.emptyFile 패턴
- [feature_batch_reset_stuck_queue.md](feature_batch_reset_stuck_queue.md) — resetStuckQueue 배치: ROWNUM서브쿼리+REQUIRES_NEW+do-while+INDEX힌트 필수 (1.5억건 테이블)
- [performance_cpu_tuning.md](performance_cpu_tuning.md) — CPU 100% 스파이크 분석: 리스너×MAX_CONCURRENT×BATCH×CONCURRENCY(10) 공식, PREFETCH=BATCH 원칙
- [pending_work.md](pending_work.md) — ControlController(미구현), BUG-8/9 수정 대기, [DEPLOY BLOCKER] backup profile 개발 URL 활성화
