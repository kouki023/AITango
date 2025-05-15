import StoreKit
import SwiftUI

struct SettingTabView: View {

  @Environment(\.requestReview) var requestReview

  var body: some View {
    NavigationStack {
      Form {
        Section("アプリ") {
          HStack {
            Text("バージョン")
              .fontWeight(.medium)
            Spacer()
            Text("1.0.0")
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
