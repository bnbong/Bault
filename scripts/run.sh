#!/bin/bash

# iOS 실행 스크립트
# 환경변수를 개별 dart-define으로 전달하여 iOS 앱을 실행합니다.

set -e

echo "🍎 iOS 앱 실행 시작..."

# .env 파일에서 환경변수 로드
if [ -f ".env" ]; then
    echo "📄 .env 파일에서 환경 변수 로드 중..."
    export $(cat .env | grep -v '^#' | xargs)
else
    echo "❌ .env 파일을 찾을 수 없습니다!"
    exit 1
fi

# 필수 환경변수가 설정되었는지 확인
if [ -z "$GOOGLE_IOS_CLIENT_ID" ]; then
    echo "❌ GOOGLE_IOS_CLIENT_ID가 설정되지 않았습니다!"
    echo ".env 파일을 확인해주세요."
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

# 개별 dart-define을 사용하여 환경변수 전달
echo "🚀 iOS 앱 실행 중..."
flutter run \
    --dart-define=GOOGLE_WEB_CLIENT_ID="$GOOGLE_WEB_CLIENT_ID" \
    --dart-define=GOOGLE_IOS_CLIENT_ID="$GOOGLE_IOS_CLIENT_ID" \
    --dart-define=GOOGLE_IOS_CLIENT_ID_REVERSED="$GOOGLE_IOS_CLIENT_ID_REVERSED" \
    --dart-define=GOOGLE_ANDROID_CLIENT_ID="$GOOGLE_ANDROID_CLIENT_ID"
