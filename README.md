# Bault (Bnbong Vault)

개인 비밀번호를 안전하게 관리할 수 있는 모바일 애플리케이션입니다.

## 주요 기능

- 🔐 생체인식 기반 보안 인증
- 🔑 키-값 형태의 비밀번호 저장
- 🔒 비밀번호를 암호화하여 안전하게 저장
- 📱 직관적이고 심플한 UI
- ☁️ 구글 드라이브 동기화 (선택사항)
- 📋 비밀번호 원클릭 복사 기능
- 🌓 다크/라이트 모드 지원

## 설치 방법

배포 버전 1.0.0 출시 이후 더 상세하게 안내드릴 예정입니다.

### Android
1. [릴리즈 페이지](https://github.com/bnbong/Bault/releases)에서 최신 APK 파일을 다운로드
2. 다운로드한 APK 파일을 실행하여 설치

### iOS
1. App Store에서 "Bault" 검색
2. 설치 버튼 클릭

## 보안

- 모든 비밀번호는 암호화되어 저장됩니다.
- 생체인식 또는 마스터 비밀번호로 보호됩니다.
- 구글 드라이브 동기화 시에도 비밀번호 데이터는 암호화된 상태로 유지됩니다.

## 개발 환경

- Flutter SDK
- Dart
- Android Studio / Xcode

## 라이선스

이 프로젝트는 MIT 라이선스 하에 배포됩니다. 자세한 내용은 [LICENSE](./LICENSE) 파일을 참조하세요.

## 기여하기

버그 리포트나 기능 제안은 [이슈 트래커](https://github.com/bnbong/Bault/issues)를 이용해 주세요.

## 기타 문의

문의사항이 있으시다면 개발자 [bnbong](mailto:bbbong9@gmail.com)에게 메일을 보내주세요.

## 환경 설정

### 1. 환경변수 설정
`.env` 파일을 생성하고 다음 내용을 추가하세요:

```bash
# Google OAuth2.0 Client IDs
GOOGLE_WEB_CLIENT_ID=your_web_client_id_here
GOOGLE_IOS_CLIENT_ID=your_ios_client_id_here
GOOGLE_ANDROID_CLIENT_ID=your_android_client_id_here
```

### 2. 개발 환경 실행

#### iOS 시뮬레이터
```bash
./scripts/run_ios.sh
```

#### Android 에뮬레이터
```bash
flutter run -d android
```

#### 웹
```bash
flutter run -d chrome
```

### 3. 프로덕션 빌드

#### iOS
```bash
./scripts/build_ios.sh
```

#### Android
```bash
flutter build apk --dart-define=GOOGLE_ANDROID_CLIENT_ID="$GOOGLE_ANDROID_CLIENT_ID"
```

## 보안 주의사항

- `.env` 파일은 절대 커밋하지 마세요
- 공개 저장소에서는 환경변수를 통해 민감한 정보를 관리하세요
- 프로덕션 환경에서는 CI/CD 파이프라인의 시크릿 관리 기능을 사용하세요

## iOS 구글 로그인 디버깅

### 디버깅 기능

앱에는 구글 로그인 문제를 진단하기 위한 상세한 디버깅 기능이 포함되어 있습니다:

- 🔧 환경 변수 검증
- 📱 플랫폼별 설정 확인
- 🔍 단계별 로그인 과정 추적
- ❌ 에러 상세 분석
- 📋 설정 체크리스트 제공

### 로그 확인 방법

1. **Xcode Console**: iOS 시뮬레이터나 기기에서 실행 시
2. **Flutter Console**: `flutter run` 명령어 실행 시
3. **로그 필터링**: `[GoogleAuth]` 태그로 필터링

### 일반적인 문제 해결

#### 1. 환경 변수 문제
```bash
# 환경 변수 확인
./scripts/test_env.sh

# 문제가 있다면 .env 파일 수정 후 재빌드
./scripts/build_ios.sh
```

#### 2. iOS 설정 문제
- Info.plist의 URL 스킴 설정 확인
- 번들 ID와 구글 콘솔 설정 일치 확인
- 실제 기기에서 테스트 (시뮬레이터 제한)

#### 3. 네트워크 문제
- 인터넷 연결 확인
- 방화벽 설정 확인
- VPN 연결 해제 후 테스트

### 로그 예시

성공적인 로그인:
```
[GoogleAuth] 🔧 GoogleAuthService 초기화 시작
[GoogleAuth] ✅ 환경 변수 확인: GOOGLE_IOS_CLIENT_ID = 9497...ug9q
[GoogleAuth] 🍎 iOS 플랫폼 - iOS 클라이언트 ID 사용
[GoogleAuth] 🔄 구글 로그인 시도 시작
[GoogleAuth] ✅ 구글 계정 선택됨: user@example.com
[GoogleAuth] ✅ 구글 로그인 성공!
```

에러 발생 시:
```
[GoogleAuth] ❌ 플랫폼 예외 발생: sign_in_failed - 로그인 실패
[GoogleAuth] 🍎 Info.plist에 URL 스킴이 올바르게 설정되어 있는지 확인하세요
[GoogleAuth] 🍎 예상 URL 스킴: com.googleusercontent.apps.949755954051-qre900633c63145gj82p1rnd06kcug9q
```

## 프로젝트 구조

```
lib/
├── models/          # 데이터 모델
├── services/        # 비즈니스 로직
│   ├── impl/       # 서비스 구현체
│   └── auth_service.dart
├── providers/       # 상태 관리
├── screens/         # UI 화면
├── utils/          # 유틸리티
│   └── debug_logger.dart  # 디버깅 로거
└── main.dart

ios/
├── Runner/
│   ├── Info.plist  # iOS 앱 설정
│   └── AppDelegate.swift  # 구글 로그인 초기화
└── Podfile

scripts/
├── build_ios.sh    # iOS 빌드 스크립트
└── test_env.sh     # 환경 변수 테스트
```

## 개발 환경

- Flutter 3.2.3+
- Dart 3.0+
- iOS 12.0+
- Android API 21+

## 라이선스

MIT License - 자세한 내용은 [LICENSE](LICENSE) 파일을 참조하세요.
