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

## 다운로드 및 설치

### Windows
1. [Releases](https://github.com/tttaliesin/twitcast-alarm/releases) 페이지에서 최신 버전 다운로드
2. `twitcast-alarm-windows.zip` 압축 해제
3. `twitcast_alarm.exe` 실행

### Android
1. [Releases](https://github.com/tttaliesin/twitcast-alarm/releases) 페이지에서 최신 버전 다운로드
2. `app-release.apk` 파일을 휴대폰으로 전송
3. APK 파일 설치 (출처를 알 수 없는 앱 설치 허용 필요)

---

## 직접 빌드하기

Releases에 원하는 버전이 없거나 직접 빌드하고 싶은 경우

### Windows APK 빌드 (Android 앱만)

#### 1. Flutter 설치
1. [Flutter 공식 사이트](https://flutter.dev/docs/get-started/install/windows) 접속
2. 최신 안정 버전 다운로드
3. `C:\src\flutter` 경로에 압축 해제
4. 환경 변수 Path에 `C:\src\flutter\bin` 추가
   - Windows 검색 → "환경 변수" → Path 편집 → 새로 만들기

#### 2. Android Studio 설치
1. [Android Studio](https://developer.android.com/studio) 다운로드 및 설치
2. Android Studio 실행 후 초기 설정 완료
3. SDK Manager에서 설치:
   - Android SDK Platform
   - Android SDK Build-Tools
   - Android SDK Command-line Tools

#### 3. 라이선스 동의 및 프로젝트 다운로드
```bash
# 라이선스 동의
flutter doctor --android-licenses

# 프로젝트 다운로드 (Git 설치 필요)
git clone https://github.com/tttaliesin/twitcast-alarm.git
cd twitcast-alarm

# 의존성 설치
flutter pub get

# APK 빌드
flutter build apk --release
```

빌드된 파일 위치: `build/app/outputs/flutter-apk/app-release.apk`

### Windows에서 Windows 앱 빌드

위 1~3번에 추가로:

#### 4. Visual Studio 2022 설치
1. [Visual Studio 2022](https://visualstudio.microsoft.com/ko/downloads/) Community 다운로드
2. 설치 시 "C++를 사용한 데스크톱 개발" 워크로드 선택 필수

#### 5. Windows 앱 빌드
```bash
flutter build windows --release
```

빌드된 파일 위치: `build/windows/x64/runner/Release/` 폴더 전체

---

## 개발자용 - 코드 수정 및 개발

앱을 수정하고 개발하려는 경우

```bash
# 프로젝트 클론
git clone https://github.com/tttaliesin/twitcast-alarm.git
cd twitcast-alarm

# 의존성 설치
flutter pub get

# 개발 모드 실행
flutter run -d windows  # Windows
flutter run -d android  # Android (기기 연결 필요)
```

## 빠른 시작 (개발 환경 구성 완료 후)

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

7. **✅ 백그라운드 모니터링 수정**: 앱 백그라운드 실행 시 모니터링 미동작 문제 해결
   - 백그라운드 서비스 콜백 연결 수정
   - 사용자 설정값(확인 주기) 백그라운드에 반영
   - 백그라운드 실행 로그 개선

8. **✅ 배터리 최적화 예외 처리**: Android 백그라운드 지속 실행 보장
   - 앱 첫 실행 시 배터리 최적화 예외 자동 요청
   - 배터리 세이버 모드에서도 백그라운드 모니터링 유지
   - Foreground Service와 배터리 최적화 예외 결합

9. **✅ 네이티브 백그라운드 모니터링 구현**: 앱 종료 후에도 백그라운드 동작
   - StreamMonitorService에서 직접 HTTP 요청 및 알람 재생
   - Flutter 앱 종료 후에도 Foreground Service가 스트림 감지
   - Kotlin 코루틴 기반 비동기 네트워크 처리
   - Android 14 이상 mediaPlayback Foreground Service 타입 추가

10. **✅ 알림 권한 자동 요청**: Android 13+ 대응
   - 앱 시작 시 알림 권한 자동 요청 (permission_handler)
   - 권한 거부 시 설정 화면으로 자동 이동
   - 배터리 최적화 예외와 함께 통합 관리

11. **✅ 알람 제어 시스템 개선**: 백그라운드/포그라운드 알람 통합 관리
   - Android: 백그라운드 서비스가 모든 알람 담당
   - Windows: Flutter가 직접 알람 재생
   - 알람 중복 재생 문제 해결
   - 알람 중지 버튼 정상 동작

12. **✅ 앱 재시작 시 백그라운드 서비스 자동 복원**
   - 모니터링 중인 스트림이 있으면 앱 시작 시 백그라운드 서비스 자동 시작
   - 앱 완전 종료 후 재시작해도 백그라운드 모니터링 지속
   - 중지/재시작 없이 바로 백그라운드 동작

## 문제 해결 가이드

### Android 백그라운드 알림이 표시되지 않는 경우

#### 증상
- 모니터링 토글을 켜도 알림이 나타나지 않음
- "백그라운드 실행 중인 앱" 목록에 앱이 표시되지 않음

#### 해결 방법

**1. 알림 권한 확인 (Android 13 이상)**
- 앱 최초 실행 시 알림 권한 팝업이 나타남
- "허용" 클릭 필요
- 수동 확인: 설정 → 앱 → 스드트캐안놓앱 → 권한 → 알림

**2. 배터리 최적화 예외 설정**
- 앱 최초 실행 시 자동으로 설정 화면 이동
- "허용" 선택 필요
- 수동 설정: 설정 → 배터리 → 배터리 최적화 → 모든 앱 표시 → 스드트캐안놓앱 → 최적화 안 함

**3. 앱 알림 설정 확인**
- 설정 → 앱 → 스드트캐안놓앱 → 알림
- "알림 표시" 및 "스트림 모니터" 채널 활성화 확인

**4. 로그 확인 (개발자용)**
```bash
# Android Studio Logcat 또는 ADB 사용
adb logcat -s StreamMonitorService:D MainActivity:D

# 정상 동작 시 나타나는 로그:
# MainActivity: 🔵 startBackgroundService 호출됨
# StreamMonitorService: ✅ StreamMonitorService 생성됨
# StreamMonitorService: 📍 알림 채널 생성 완료
# StreamMonitorService: ✅ startForeground() 호출 완료
# StreamMonitorService: 🚀 백그라운드 모니터링 시작
```

**5. Foreground Service 권한 문제**
- Android 14 이상에서 FOREGROUND_SERVICE_MEDIA_PLAYBACK 권한 필요
- 앱 재설치 시 자동으로 권한 부여됨

### 빌드 경고 관련

#### Java 버전 경고
```
warning: [options] source value 8 is obsolete
```
- permission_handler 라이브러리가 Java 8로 컴파일되어 발생
- 앱 동작에는 영향 없음 (경고만 표시됨)
- 무시해도 정상 작동

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
    ├── background_service_manager.dart    # ✅ 백그라운드 서비스 통합 관리
    ├── platform_channel.dart              # Android 플랫폼 채널
    ├── windows_background_service.dart    # Windows 백그라운드
    ├── system_tray_service.dart           # 시스템 트레이
    ├── alarm_history_service.dart         # ✅ 알람 히스토리 저장 서비스
    ├── battery_optimization_service.dart  # ✅ 배터리 최적화 관리
    └── notification_permission_service.dart # ✅ 알림 권한 요청 (Android 13+)
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
- [x] 백그라운드 모니터링 미동작 문제 수정
- [x] 배터리 최적화 예외 처리 (백그라운드 지속 실행)
- [x] 네이티브 백그라운드 모니터링 구현 (앱 종료 후에도 동작)
- [x] 알림 권한 자동 요청 (Android 13+ 대응)
- [x] 백그라운드 서비스 디버깅 로그 추가
- [x] 알람 제어 시스템 개선 (백그라운드 서비스 통합, 중복 재생 방지)
- [x] 앱 재시작 시 백그라운드 서비스 자동 복원

## 라이선스

MIT License

본 프로젝트는 다음 오픈소스 라이브러리 사용:
- Flutter SDK (BSD-3-Clause)
- audioplayers, workmanager, system_tray, window_manager, provider, permission_handler (MIT)
- http, shared_preferences (BSD-3-Clause)

## 기여

프로젝트 개선을 위한 이슈 등록 및 풀 리퀘스트 환영

## 주의사항

- 트위캐스트 이용약관 준수 필수
- 과도한 API 요청은 IP 차단 가능 (현재 30초 간격)
- 개인적 용도로만 사용
