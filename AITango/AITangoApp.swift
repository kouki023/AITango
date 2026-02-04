//
//  Cursor_TestApp.swift
//  Cursor_Test
//
//  Created by Kouki Funaishi on 2025/03/08.
//

import SwiftUI
import SwiftData // <--- 追加
import UIKit
import StoreKit

// レビュー依頼を管理（ビルドに確実に含めるため App ファイル内に実装）
final class ReviewRequestManager {
    static let shared = ReviewRequestManager()
    private init() {}

    private let hasRequestedKey = "review.hasRequestedOnce"
    private let requiredActiveSeconds: TimeInterval = 120 // 3分

    private var accumulatedActiveSeconds: TimeInterval = 0
    private var becameActiveAt: Date?
    private var pendingTimer: Timer?

    func handleScenePhase(_ phase: UIScene.ActivationState) {
        switch phase {
        case .foregroundActive:
            startOrResumeTimer()
        case .foregroundInactive, .background, .unattached:
            pauseTimer()
        @unknown default:
            pauseTimer()
        }
    }

    private func startOrResumeTimer() {
        guard !UserDefaults.standard.bool(forKey: hasRequestedKey) else { return }
        let remaining = max(requiredActiveSeconds - accumulatedActiveSeconds, 0)
        guard remaining > 0 else { requestReviewIfPossible(); return }

        becameActiveAt = Date()
        pendingTimer?.invalidate()
        pendingTimer = Timer.scheduledTimer(withTimeInterval: remaining, repeats: false) { [weak self] _ in
            self?.accumulateNow()
            self?.requestReviewIfPossible()
        }
    }

    private func pauseTimer() {
        accumulateNow()
        pendingTimer?.invalidate()
        pendingTimer = nil
    }

    private func accumulateNow() {
        guard let start = becameActiveAt else { return }
        accumulatedActiveSeconds += Date().timeIntervalSince(start)
        becameActiveAt = nil
    }

    private func requestReviewIfPossible() {
        guard !UserDefaults.standard.bool(forKey: hasRequestedKey) else { return }
        if let scene = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .first(where: { $0.activationState == .foregroundActive }) {
            SKStoreReviewController.requestReview(in: scene)
            UserDefaults.standard.set(true, forKey: hasRequestedKey)
        }
    }
}

@main
struct AITangoApp: App {
    @Environment(\.scenePhase) private var scenePhase
    // SwiftData Model Containerの設定 --- ここから ---
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Wordbook.self,
            WordCard.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false) // 実機・シミュレータ用

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
            ContentView() // メインのViewを呼び出し
                .onAppear {
                    // 起動直後にすでにアクティブなら計測開始
                    if scenePhase == .active {
                        ReviewRequestManager.shared.handleScenePhase(.foregroundActive)
                    }
                }
        }
        .modelContainer(sharedModelContainer) // ModelContainerを環境に注入 --- 追加 ---
        .onChange(of: scenePhase) { _, newPhase in
            // フォアグラウンドのアクティブ時間を計測し、3分後にレビュー依頼を表示
            switch newPhase {
            case .active:
                ReviewRequestManager.shared.handleScenePhase(.foregroundActive)
            case .inactive:
                ReviewRequestManager.shared.handleScenePhase(.foregroundInactive)
            case .background:
                ReviewRequestManager.shared.handleScenePhase(.background)
            @unknown default:
                ReviewRequestManager.shared.handleScenePhase(.foregroundInactive)
            }
        }
    }
}
