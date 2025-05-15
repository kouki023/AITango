//
//  Cursor_TestApp.swift
//  Cursor_Test
//
//  Created by Kouki Funaishi on 2025/03/08.
//

import SwiftUI
import SwiftData // <--- 追加

@main
struct AITangoApp: App {
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
        }
        .modelContainer(sharedModelContainer) // ModelContainerを環境に注入 --- 追加 ---
    }
}
