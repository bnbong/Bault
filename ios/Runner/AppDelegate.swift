import Flutter
import UIKit
import GoogleSignIn

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)

    // 구글 로그인 초기화
    if let path = Bundle.main.path(forResource: "GoogleService-Info", ofType: "plist"),
       let plist = NSDictionary(contentsOfFile: path),
       let clientId = plist["CLIENT_ID"] as? String {
      GIDSignIn.sharedInstance.configuration = GIDConfiguration(clientID: clientId)
      print("✅ 구글 로그인 초기화 완료 - 클라이언트 ID: \(clientId)")
    } else {
      // GoogleService-Info.plist가 없는 경우 Info.plist에서 클라이언트 ID 가져오기
      if let clientId = Bundle.main.object(forInfoDictionaryKey: "GIDClientID") as? String {
        GIDSignIn.sharedInstance.configuration = GIDConfiguration(clientID: clientId)
        print("✅ 구글 로그인 초기화 완료 (Info.plist) - 클라이언트 ID: \(clientId)")
      } else {
        print("❌ 구글 클라이언트 ID를 찾을 수 없습니다. GoogleService-Info.plist 또는 Info.plist의 GIDClientID를 확인하세요.")
      }
    }

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  // URL 스킴 처리 (iOS 9.0+)
  override func application(
    _ app: UIApplication,
    open url: URL,
    options: [UIApplication.OpenURLOptionsKey : Any] = [:]
  ) -> Bool {
    print("🔗 URL 스킴 처리: \(url.absoluteString)")

    // 구글 로그인 URL 스킴 처리
    if GIDSignIn.sharedInstance.handle(url) {
      print("✅ 구글 로그인 URL 스킴 처리 완료")
      return true
    }

    // Flutter 플러그인 URL 처리
    return super.application(app, open: url, options: options)
  }
}
