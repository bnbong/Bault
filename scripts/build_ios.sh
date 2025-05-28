#!/bin/bash

# iOS 빌드 스크립트
# 환경 변수를 dart-define으로 전달하여 iOS 앱을 빌드합니다.
# PlistBuddy를 사용하여 Info.plist에 환경변수 값을 동적으로 주입합니다.

set -e

echo "🍎 iOS 빌드 시작..."

# .env 파일에서 환경 변수 로드
if [ -f ".env" ]; then
    echo "📄 .env 파일에서 환경 변수 로드 중..."
    export $(cat .env | grep -v '^#' | xargs)
else
    echo "❌ .env 파일을 찾을 수 없습니다!"
    exit 1
fi

# 필수 환경 변수 확인
if [ -z "$GOOGLE_IOS_CLIENT_ID" ]; then
    echo "❌ GOOGLE_IOS_CLIENT_ID가 설정되지 않았습니다!"
    exit 1
fi

if [ -z "$GOOGLE_IOS_CLIENT_ID_REVERSED" ]; then
    echo "❌ GOOGLE_IOS_CLIENT_ID_REVERSED가 설정되지 않았습니다!"
    exit 1
fi

echo "✅ 환경 변수 확인 완료"
echo "  - GOOGLE_IOS_CLIENT_ID: $GOOGLE_IOS_CLIENT_ID"
echo "  - GOOGLE_IOS_CLIENT_ID_REVERSED: $GOOGLE_IOS_CLIENT_ID_REVERSED"

# Info.plist 업데이트
echo "🔧 Info.plist 업데이트 중..."
./scripts/update_info_plist.sh

# Flutter 의존성 설치
echo "📦 Flutter 의존성 설치 중..."
flutter pub get

# iOS 의존성 설치
echo "🔧 iOS 의존성 설치 중..."
cd ios
pod install --repo-update
cd ..

# Flutter 빌드 (환경 변수를 dart-define으로 전달)
echo "🔨 Flutter iOS 빌드 중..."
flutter build ios \
    --dart-define=GOOGLE_WEB_CLIENT_ID="$GOOGLE_WEB_CLIENT_ID" \
    --dart-define=GOOGLE_IOS_CLIENT_ID="$GOOGLE_IOS_CLIENT_ID" \
    --dart-define=GOOGLE_IOS_CLIENT_ID_REVERSED="$GOOGLE_IOS_CLIENT_ID_REVERSED" \
    --dart-define=GOOGLE_ANDROID_CLIENT_ID="$GOOGLE_ANDROID_CLIENT_ID" \
    --release

echo "🎉 iOS 빌드 완료!"
echo "📱 다음 단계: 실제 iOS 기기에서 구글 로그인 테스트"
