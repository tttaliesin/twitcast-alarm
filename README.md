# 스타드림 트위캐스트 안 놓치려고 만든 앱

트위캐스트(Twitcast) 스트림을 모니터링하고 방송 시작 시 큰 소리로 알림을 주는 크로스 플랫폼 애플리케이션

## 주요 기능

- 최대 4개의 트위캐스트 스트림 동시 모니터링
- 각 스트림별 개별 시작/중지 제어
- 알람 볼륨 조절 기능
- 백그라운드 모니터링 (Windows 최소화 또는 Android 백그라운드 실행 시에도 작동)
- 설정 자동 저장
- 별도의 외부 프로그램 불필요
- **알람 히스토리**: 모든 알람 발생 기록 저장 및 통계 표시
- **설정 UI**: 볼륨, 재시도 횟수, 재시도 간격, 확인 주기 등 세부 설정 가능

## 빠른 시작

```bash
flutter pub get
flutter run -d windows  # 또는 -d android
```

## 테스트 실행

```bash
flutter test
```

## 릴리즈 빌드

```bash
# Windows
flutter build windows --release

# Android
flutter build apk --release
```

## 사용 방법

1. 트위캐스트 스트림 URL 입력 (최대 4개)
2. 토글 버튼을 눌러 각 스트림의 모니터링 시작/중지
3. 슬라이더로 알람 볼륨 조절
4. 앱이 30초마다 자동으로 스트림 상태 확인
5. 스트림이 라이브 상태가 되면 큰 소리로 알람 울림

## 기술적 세부사항

- HTTP 요청으로 트위캐스트 스트림 상태 확인
- WorkManager(Android) 및 isolate(Windows)를 통한 백그라운드 모니터링
- SharedPreferences로 설정 로컬 저장
- 앱이 최소화되거나 백그라운드 상태여도 알람 작동

## ✅ 최근 개선 사항

1. **✅ 지속적인 모니터링**: 스트림이 라이브 상태가 되어도 모니터링이 중단되지 않음
   - 스트림 종료 후 재방송 시에도 자동으로 알림 수신
   - 한 번 모니터링을 시작하면 수동으로 중지할 때까지 계속 감시

2. **✅ 네트워크 오류 재시도**: 일시적인 네트워크 오류 시 자동 재시도 (최대 3회)
   - 2초 간격으로 재시도하여 일시적 네트워크 문제 극복
   - 안정적인 스트림 모니터링 보장

3. **✅ 알람 히스토리 기능**: 모든 알람 기록을 저장하고 통계 제공
   - 전체/오늘/7일 알람 통계
   - 가장 활발한 스트림 분석
   - 개별 항목 삭제 및 전체 삭제 기능
   - 스와이프로 쉽게 삭제 가능

4. **✅ 설정 UI 개선**: 모든 설정을 UI에서 쉽게 조절 가능
   - 알람 볼륨 조절 (0~100%)
   - 네트워크 재시도 횟수 (1~10회)
   - 재시도 간격 (1~10초)
   - 확인 주기 (10~300초)
   - 기본값 초기화 기능

5. **✅ 안드로이드 무음모드 알람 지원**: 휴대폰이 무음/진동 모드여도 알람 재생
   - Android 네이티브 `USAGE_ALARM` 사용
   - 시스템 볼륨과 무관하게 알람 소리 재생
   - 별도 권한 요청 불필요

6. **✅ 유닛 테스트 구현**: 모델 레이어 테스트 완료
   - StreamInfo 모델 테스트 (10개 테스트)
   - AlarmHistory 모델 테스트 (13개 테스트)
   - JSON 직렬화/역직렬화 검증
   - 시간 포맷팅 로직 검증

## 알려진 문제점

### 잠재적 문제
1. **API 변경**: 트위캐스트 웹사이트 구조 변경 시 스트림 감지 실패 가능

## 프로젝트 구조

```
lib/
├── main.dart                              # 앱 진입점, 초기화
├── models/
│   ├── stream_info.dart                   # 스트림 정보 데이터 모델
│   └── alarm_history.dart                 # ✅ 알람 히스토리 데이터 모델
├── screens/
│   ├── home_screen.dart                   # 메인 화면 UI
│   ├── alarm_history_screen.dart          # ✅ 알람 히스토리 화면
│   └── settings_screen.dart               # ✅ 설정 화면
└── services/
    ├── alarm_service.dart                 # 알람 재생/중지 서비스
    ├── twitcast_api.dart                  # 트위캐스트 API 통신
    ├── stream_monitor_service.dart        # 스트림 모니터링 핵심 로직
    ├── background_service_manager.dart    # 백그라운드 서비스 통합 관리
    ├── platform_channel.dart              # Android 플랫폼 채널
    ├── windows_background_service.dart    # Windows 백그라운드
    ├── system_tray_service.dart           # 시스템 트레이
    └── alarm_history_service.dart         # ✅ 알람 히스토리 저장 서비스
```

## 개발 로드맵

### 완료된 작업 ✅
- [x] `platform_channel.dart` 구현 (Android 통신)
- [x] `windows_background_service.dart` 구현 (Windows 백그라운드)
- [x] `system_tray_service.dart` 구현 (시스템 트레이)
- [x] Android Foreground Service 구현
- [x] AndroidManifest.xml 권한 설정
- [x] 모니터링 중단 로직 개선 (지속 모니터링)
- [x] 네트워크 오류 재시도 메커니즘 (최대 3회, 2초 간격)
- [x] Windows 시스템 트레이 메뉴 및 종료 기능
- [x] 알람 히스토리 기록 기능 (통계 및 삭제 기능 포함)
- [x] 설정 UI 개선 (볼륨, 재시도 횟수, 확인 간격 등)
- [x] 홈화면, 설정창 에서의 불륨조절 동기화
- [x] 안드로이드 무음모드 알람 지원 (네이티브 USAGE_ALARM)
- [x] 유닛 테스트 작성 (StreamInfo, AlarmHistory 모델)

## 라이선스

MIT License

본 프로젝트는 다음 오픈소스 라이브러리 사용:
- Flutter SDK (BSD-3-Clause)
- audioplayers, workmanager, system_tray, window_manager, provider (MIT)
- http, shared_preferences (BSD-3-Clause)

## 기여

프로젝트 개선을 위한 이슈 등록 및 풀 리퀘스트 환영

## 주의사항

- 트위캐스트 이용약관 준수 필수
- 과도한 API 요청은 IP 차단 가능 (현재 30초 간격)
- 개인적 용도로만 사용
