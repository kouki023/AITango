//
//  Cursor_TestApp.swift
//  Cursor_Test
//
//  Created by Kouki Funaishi on 2025/03/08.
//

import BackgroundTasks
import StoreKit
import SwiftData  // <--- 追加
import SwiftUI
import UIKit
import UserNotifications

// MARK: - バックグラウンドタスク用 AppDelegate
/// 12時間ごとにバックグラウンドで通知を再スケジュールする
class AppDelegate: NSObject, UIApplicationDelegate {

  /// バックグラウンドタスクの識別子
  static let bgTaskIdentifier = "com.aitango.notification.refresh"

  func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
  ) -> Bool {
    // バックグラウンドタスクを登録
    BGTaskScheduler.shared.register(
      forTaskWithIdentifier: Self.bgTaskIdentifier, using: nil
    ) { task in
      guard let appRefreshTask = task as? BGAppRefreshTask else { return }
      self.handleAppRefresh(task: appRefreshTask)
    }
    return true
  }

  /// バックグラウンドタスクの処理: SwiftDataからカードを取得し通知を再スケジュール
  private func handleAppRefresh(task: BGAppRefreshTask) {
    // 次回のバックグラウンドタスクを予約
    Self.scheduleNextBackgroundRefresh()

    let manager = NotificationManager.shared
    guard manager.isEnabled else {
      task.setTaskCompleted(success: true)
      return
    }

    // バックグラウンド用のModelContainerを作成してカードを取得
    do {
      let schema = Schema([Wordbook.self, WordCard.self])
      let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
      let container = try ModelContainer(for: schema, configurations: [config])
      let context = ModelContext(container)
      let descriptor = FetchDescriptor<WordCard>()
      let allCards = try context.fetch(descriptor)
      manager.scheduleReviewNotifications(cards: allCards)
      print("🔄 バックグラウンドで通知を再スケジュールしました（\(allCards.count) 枚）")
    } catch {
      print("バックグラウンドタスクエラー: \(error.localizedDescription)")
    }

    task.setTaskCompleted(success: true)
  }

  /// 次回のバックグラウンドリフレッシュを予約（12時間後）
  static func scheduleNextBackgroundRefresh() {
    let request = BGAppRefreshTaskRequest(identifier: bgTaskIdentifier)
    request.earliestBeginDate = Date(timeIntervalSinceNow: 12 * 60 * 60)  // 12時間後
    do {
      try BGTaskScheduler.shared.submit(request)
      print("⏰ 次回バックグラウンドリフレッシュを予約しました")
    } catch {
      print("バックグラウンドタスク予約エラー: \(error.localizedDescription)")
    }
  }
}

// レビュー依頼を管理（学習完了時にのみ表示）
final class ReviewRequestManager {
  static let shared = ReviewRequestManager()
  private init() {}

  private let hasRequestedKey = "review.hasRequestedOnce"

  /// 学習完了時に呼び出す。まだレビュー依頼をしていなければダイアログを表示する。
  func requestReviewIfNeeded() {
    guard !UserDefaults.standard.bool(forKey: hasRequestedKey) else { return }
    if let scene = UIApplication.shared.connectedScenes
      .compactMap({ $0 as? UIWindowScene })
      .first(where: { $0.activationState == .foregroundActive })
    {
      SKStoreReviewController.requestReview(in: scene)
      UserDefaults.standard.set(true, forKey: hasRequestedKey)
    }
  }
}

@main
struct AITangoApp: App {
  // AppDelegateをSwiftUIアプリに接続
  @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

  // SwiftData Model Containerの設定 --- ここから ---
  var sharedModelContainer: ModelContainer = {
    let schema = Schema([
      Wordbook.self,
      WordCard.self,
    ])
    let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)  // 実機・シミュレータ用

    do {
      // ここでコンテナを作成
      return try ModelContainer(for: schema, configurations: [modelConfiguration])
    } catch {
      // エラー発生時はアプリをクラッシュさせる (開発初期段階)
      fatalError("Could not create ModelContainer: \(error)")
    }
  }()
  // --- ここまで ---

  var body: some Scene {
    WindowGroup {
      ContentView()  // メインのViewを呼び出し
        .onAppear {
          scheduleNotificationsOnLaunch()
          // 次回のバックグラウンドリフレッシュを予約
          AppDelegate.scheduleNextBackgroundRefresh()
        }
    }
    .modelContainer(sharedModelContainer)  // ModelContainerを環境に注入 --- 追加 ---
  }

  /// アプリ起動時に分散学習の復習通知をスケジュールする
  private func scheduleNotificationsOnLaunch() {
    let manager = NotificationManager.shared
    guard manager.isEnabled else { return }

    // SwiftDataから全カードを取得
    let context = sharedModelContainer.mainContext
    let descriptor = FetchDescriptor<WordCard>()
    do {
      let allCards = try context.fetch(descriptor)
      manager.scheduleReviewNotifications(cards: allCards)
    } catch {
      print("通知スケジュール用カード取得エラー: \(error.localizedDescription)")
    }
  }
}
