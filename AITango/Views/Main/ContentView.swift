//
//  ContentView.swift
//  Cursor_Test
//
//  Created by Kouki Funaishi on 2025/03/08.
//

import SwiftUI
import SwiftData // <--- 追加 (プレビューで使用するため)

struct ContentView: View {

    @State private var selectedTab: Tab = .wordbook

    private let feedbackGenerator = UIImpactFeedbackGenerator(style: .light)

    enum Tab{
        case wordbook
        case learning
        case setting
    }

    var body: some View {
        // TabViewで各機能画面を切り替える
        TabView(selection: $selectedTab) {
            WordbookListView() // 単語帳一覧画面を呼び出し
                .tabItem {
                    Label("単語帳", systemImage: "book.closed")
                }
                .tag(Tab.wordbook)

            
            LearningTabView( selectedMode: .normal) // 学習画面を呼び出し
                .tabItem {
                    Label("学習", systemImage: "lightbulb")
                }
                .tag(Tab.learning)


            SettingTabView()
                .tabItem {
                    Label("設定", systemImage: "gear")
                }
                .tag(Tab.setting)
            
        }
        .onChange(of: selectedTab) { oldState, newState in 
            feedbackGenerator.prepare()
            feedbackGenerator.impactOccurred()
        }
       
    }
}

// プレビュー設定
#if DEBUG
#Preview {
    ContentView()
        // プレビュー用にインメモリのModelContainerを使用
        .modelContainer(PreviewContainer.previewInMemoryWithLinkedData) // データがある方が確認しやすい
        // .modelContainer(previewContainer) // PreviewContainer.swift を使う場合
        .colorScheme(.dark)
}
#endif

