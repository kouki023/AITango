//
//  Cursor_TestApp.swift
//  Cursor_Test
//
//  Created by Kouki Funaishi on 2025/03/08.
//

import StoreKit
import SwiftData  // <--- 追加
import SwiftUI
import UIKit
import UserNotifications

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
