import StoreKit
import SwiftData
import SwiftUI

struct SettingTabView: View {

  @Environment(\.requestReview) var requestReview
  @ObservedObject private var notificationManager = NotificationManager.shared

  // 通知再スケジュール用に全カードを取得
  @Query private var allCards: [WordCard]

  // 通知のオンオフ状態
  @State private var isNotificationEnabled: Bool = NotificationManager.shared.isEnabled
  // 通知時刻
  @State private var notificationTime: Date = NotificationManager.shared.notificationTime

  var AppVersion: String {
    let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
    return version
  }

  var body: some View {
    NavigationStack {
      Form {
        // アプリ情報セクション
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

        // 通知設定セクション
        Section("通知") {
          Toggle(isOn: $isNotificationEnabled) {
            Label {
              Text("復習リマインダー")
                .fontWeight(.medium)
            } icon: {
              Image(systemName: "bell.fill")
                .foregroundStyle(.orange)
            }
          }
          .onChange(of: isNotificationEnabled) { _, newValue in
            notificationManager.isEnabled = newValue
            if newValue {
              // オンにした場合: 通知許可をリクエストしてスケジュール
              notificationManager.requestPermission { granted in
                if granted {
                  notificationManager.scheduleReviewNotifications(cards: Array(allCards))
                } else {
                  // 許可されなかった場合はオフに戻す
                  isNotificationEnabled = false
                  notificationManager.isEnabled = false
                }
              }
            } else {
              // オフにした場合: 全通知をキャンセル
              notificationManager.cancelAllNotifications()
            }
          }

          if isNotificationEnabled {
            DatePicker(selection: $notificationTime, displayedComponents: .hourAndMinute) {
              Label {
                Text("通知時刻")
                  .fontWeight(.medium)
              } icon: {
                Image(systemName: "clock.fill")
                  .foregroundStyle(.blue)
              }
            }
            .onChange(of: notificationTime) { _, newValue in
              notificationManager.notificationTime = newValue
              // 時刻変更時に通知を再スケジュール
              notificationManager.scheduleReviewNotifications(cards: Array(allCards))
            }
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
