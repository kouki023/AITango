import StoreKit
import SwiftUI

struct SettingTabView: View {

  @Environment(\.requestReview) var requestReview

  var AppVersion: String {
    let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
    return version
  }

  var body: some View {
    NavigationStack {
      Form {
        Section("アプリ") {
          HStack {
            Text("バージョン")
              .fontWeight(.medium)
            Spacer()
            Text("\(AppVersion)")
              .foregroundStyle(Color.gray)
              .fontWeight(.medium)
          }
        }
        Section("その他") {
          Button("アプリを評価する") {
            requestReview()
          }
        }
      }
      .navigationTitle("設定")
    }

  }

}

// SwiftUIプレビュー用のコード
struct SettingTabView_Previews: PreviewProvider {
  static var previews: some View {
    SettingTabView()
  }
}
