#!/usr/bin/env python3
"""
민감한 정보 검사 및 치환 스크립트
구글 클라이언트 ID 등의 민감한 정보가 하드코딩되어 있으면 환경변수로 치환합니다.
"""

import re
import sys
import os
from typing import List, Tuple, Dict
import xml.etree.ElementTree as ET

# 민감한 정보 패턴 정의
SENSITIVE_PATTERNS = {
    'google_client_id': r'\b\d{12}-[a-z0-9]{32}\.apps\.googleusercontent\.com\b',
    'google_client_id_reversed': r'\bcom\.googleusercontent\.apps\.\d{12}-[a-z0-9]{32}\b',
    'firebase_api_key': r'\bAIza[0-9A-Za-z_-]{35}\b',
    'firebase_app_id': r'\b1:\d{12}:(?:android|ios):[a-f0-9]{40}\b',
}

# 파일별 치환 규칙
REPLACEMENT_RULES = {
    'ios/Runner/Info.plist': {
        'google_client_id': '$(GOOGLE_IOS_CLIENT_ID)',
        'google_client_id_reversed': '$(GOOGLE_IOS_CLIENT_ID_REVERSED)',
    },
    'android/app/src/main/AndroidManifest.xml': {
        'google_client_id': '${GOOGLE_ANDROID_CLIENT_ID}',
        'google_client_id_reversed': '${GOOGLE_ANDROID_CLIENT_ID_REVERSED}',
    },
    'web/index.html': {
        'google_client_id': '{{GOOGLE_WEB_CLIENT_ID}}',
        'firebase_api_key': '{{FIREBASE_API_KEY}}',
        'firebase_app_id': '{{FIREBASE_APP_ID}}',
    }
}

class SensitiveDataChecker:
    def __init__(self):
        self.issues_found = []
        self.files_modified = []

    def check_file(self, file_path: str) -> bool:
        """파일에서 민감한 정보를 검사하고 필요시 치환합니다."""
        if not os.path.exists(file_path):
            return True

        try:
            with open(file_path, 'r', encoding='utf-8') as f:
                content = f.read()
        except UnicodeDecodeError:
            # 바이너리 파일은 건너뛰기
            return True

        original_content = content
        issues = []

        # 각 패턴에 대해 검사
        for pattern_name, pattern in SENSITIVE_PATTERNS.items():
            matches = re.findall(pattern, content)
            if matches:
                for match in matches:
                    issues.append(f"  🔍 발견된 {pattern_name}: {self._mask_sensitive(match)}")

                    # 치환 규칙이 있으면 자동 치환
                    if file_path in REPLACEMENT_RULES and pattern_name in REPLACEMENT_RULES[file_path]:
                        replacement = REPLACEMENT_RULES[file_path][pattern_name]
                        content = content.replace(match, replacement)
                        issues.append(f"  ✅ 자동 치환: {replacement}")

        if issues:
            self.issues_found.append(f"\n📁 {file_path}:")
            self.issues_found.extend(issues)

            # 내용이 변경되었으면 파일 업데이트
            if content != original_content:
                with open(file_path, 'w', encoding='utf-8') as f:
                    f.write(content)
                self.files_modified.append(file_path)
                print(f"✅ 자동 치환 완료: {file_path}")

        return len(issues) == 0 or content != original_content

    def check_plist_file(self, file_path: str) -> bool:
        """Info.plist 파일 전용 검사 (XML 파싱 사용)"""
        if not os.path.exists(file_path):
            return True

        try:
            tree = ET.parse(file_path)
            root = tree.getroot()

            # plist의 dict 요소 찾기
            dict_elem = root.find('dict')
            if dict_elem is None:
                return True

            modified = False
            children = list(dict_elem)  # 모든 자식 요소를 리스트로 변환

            for i, child in enumerate(children):
                if child.tag == 'key':
                    if child.text == 'GIDClientID':
                        # 다음 string 요소 찾기
                        if i + 1 < len(children) and children[i + 1].tag == 'string':
                            string_elem = children[i + 1]
                            value = string_elem.text
                            if value and re.match(SENSITIVE_PATTERNS['google_client_id'], value):
                                string_elem.text = '$(GOOGLE_IOS_CLIENT_ID)'
                                modified = True
                                self.issues_found.append(f"\n📁 {file_path}:")
                                self.issues_found.append(f"  🔍 GIDClientID 하드코딩 발견")
                                self.issues_found.append(f"  ✅ 환경변수로 치환: $(GOOGLE_IOS_CLIENT_ID)")

                    elif child.text == 'CFBundleURLTypes':
                        # URL 스킴 검사
                        if i + 1 < len(children) and children[i + 1].tag == 'array':
                            url_types = children[i + 1]
                            for url_type in url_types.findall('dict'):
                                url_children = list(url_type)
                                for j, url_child in enumerate(url_children):
                                    if url_child.tag == 'key' and url_child.text == 'CFBundleURLSchemes':
                                        if j + 1 < len(url_children) and url_children[j + 1].tag == 'array':
                                            schemes_array = url_children[j + 1]
                                            for scheme in schemes_array.findall('string'):
                                                if scheme.text and re.match(SENSITIVE_PATTERNS['google_client_id_reversed'], scheme.text):
                                                    scheme.text = '$(GOOGLE_IOS_CLIENT_ID_REVERSED)'
                                                    modified = True
                                                    self.issues_found.append(f"\n📁 {file_path}:")
                                                    self.issues_found.append(f"  🔍 CFBundleURLSchemes 하드코딩 발견")
                                                    self.issues_found.append(f"  ✅ 환경변수로 치환: $(GOOGLE_IOS_CLIENT_ID_REVERSED)")

            if modified:
                tree.write(file_path, encoding='utf-8', xml_declaration=True)
                self.files_modified.append(file_path)
                print(f"✅ Info.plist 자동 치환 완료: {file_path}")

            return True

        except ET.ParseError as e:
            print(f"❌ XML 파싱 오류 {file_path}: {e}")
            return False

    def _mask_sensitive(self, value: str) -> str:
        """민감한 정보를 마스킹합니다."""
        if len(value) <= 8:
            return '***'
        return f"{value[:4]}...{value[-4:]}"

    def check_files(self, file_paths: List[str]) -> bool:
        """여러 파일을 검사합니다."""
        all_clean = True

        for file_path in file_paths:
            if file_path.endswith('Info.plist'):
                clean = self.check_plist_file(file_path)
            else:
                clean = self.check_file(file_path)

            if not clean:
                all_clean = False

        return all_clean

    def print_summary(self):
        """검사 결과 요약을 출력합니다."""
        if self.issues_found:
            print("\n🔒 민감한 정보 검사 결과:")
            for issue in self.issues_found:
                print(issue)

        if self.files_modified:
            print(f"\n✅ 자동 치환된 파일: {len(self.files_modified)}개")
            for file_path in self.files_modified:
                print(f"  - {file_path}")
            print("\n⚠️  변경된 파일들을 다시 스테이징해주세요:")
            print(f"git add {' '.join(self.files_modified)}")

def main():
    """메인 함수"""
    if len(sys.argv) < 2:
        print("사용법: python check_sensitive_data.py <파일1> <파일2> ...")
        sys.exit(1)

    file_paths = sys.argv[1:]
    checker = SensitiveDataChecker()

    print("🔍 민감한 정보 검사 시작...")

    # 검사할 파일들 필터링 (관련 파일만)
    relevant_files = []
    for file_path in file_paths:
        if any(pattern in file_path for pattern in [
            'Info.plist', 'AndroidManifest.xml', 'index.html',
            'google-services.json', 'GoogleService-Info.plist'
        ]):
            relevant_files.append(file_path)

    if not relevant_files:
        print("✅ 검사할 관련 파일이 없습니다.")
        sys.exit(0)

    print(f"📁 검사 대상 파일: {len(relevant_files)}개")
    for file_path in relevant_files:
        print(f"  - {file_path}")

    all_clean = checker.check_files(relevant_files)
    checker.print_summary()

    if not all_clean and not checker.files_modified:
        print("\n❌ 민감한 정보가 발견되었지만 자동 치환할 수 없습니다.")
        print("수동으로 환경변수를 사용하도록 수정해주세요.")
        sys.exit(1)
    elif checker.files_modified:
        print("\n✅ 민감한 정보를 환경변수로 자동 치환했습니다.")
        sys.exit(0)
    else:
        print("\n✅ 민감한 정보가 발견되지 않았습니다.")
        sys.exit(0)

if __name__ == "__main__":
    main()
