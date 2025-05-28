#!/bin/bash

# Info.plist 업데이트 스크립트
# PlistBuddy를 사용하여 환경변수 값을 Info.plist에 동적으로 주입합니다.

set -e

echo "🔧 Info.plist 업데이트 시작..."

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

# Info.plist 파일 경로
INFO_PLIST_PATH="ios/Runner/Info.plist"

if [ ! -f "$INFO_PLIST_PATH" ]; then
    echo "❌ Info.plist 파일을 찾을 수 없습니다: $INFO_PLIST_PATH"
    exit 1
fi

echo "✅ 환경 변수 확인 완료"
echo "  - GOOGLE_IOS_CLIENT_ID: $GOOGLE_IOS_CLIENT_ID"
echo "  - GOOGLE_IOS_CLIENT_ID_REVERSED: $GOOGLE_IOS_CLIENT_ID_REVERSED"

# PlistBuddy를 사용하여 Info.plist 업데이트
echo "🔨 PlistBuddy로 Info.plist 업데이트 중..."

# GIDClientID 업데이트
/usr/libexec/PlistBuddy -c "Set :GIDClientID $GOOGLE_IOS_CLIENT_ID" "$INFO_PLIST_PATH"
echo "✅ GIDClientID 업데이트 완료: $GOOGLE_IOS_CLIENT_ID"

# CFBundleURLSchemes 업데이트 (첫 번째 URL 타입)
/usr/libexec/PlistBuddy -c "Set :CFBundleURLTypes:0:CFBundleURLSchemes:0 $GOOGLE_IOS_CLIENT_ID_REVERSED" "$INFO_PLIST_PATH"
echo "✅ CFBundleURLSchemes 업데이트 완료: $GOOGLE_IOS_CLIENT_ID_REVERSED"

echo "🎉 Info.plist 업데이트 완료!"

# 업데이트된 내용 확인
echo ""
echo "📋 업데이트된 Info.plist 내용 확인:"
echo "GIDClientID: $(/usr/libexec/PlistBuddy -c "Print :GIDClientID" "$INFO_PLIST_PATH")"
echo "CFBundleURLSchemes[0]: $(/usr/libexec/PlistBuddy -c "Print :CFBundleURLTypes:0:CFBundleURLSchemes:0" "$INFO_PLIST_PATH")"
