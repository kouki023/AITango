// Cursor_Test/Views/WordCard/WordCardCreationView.swift

import SwiftUI
import SwiftData

// 追加モードを定義
enum CreationMode: String, CaseIterable, Identifiable {
    case manual = "手動で追加"
    case automatic = "自動生成 (Beta)"
    var id: String { self.rawValue }
}

struct WordCardCreationView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    var wordbook: Wordbook // カードを追加する対象の単語帳

    // --- ▼▼▼ State変数を追加 ▼▼▼ ---
    @State private var selectedMode: CreationMode = .automatic // 現在のモード
    @Namespace private var creationModeNamespace // セグメントコントロール用

    // 手動入力用
    @State private var frontText: String = ""
    @State private var backText: String = ""

    // 自動生成用
    @State private var generationCount: Int = 5 // 生成する単語数
    @State private var generationTheme: String = "" // 生成テーマ
    @State private var isGenerating: Bool = false // 生成中フラグ
    @State private var generatedPairs: [GeneratedWordPair] = [] // 生成結果プレビュー用
    @State private var generationError: GeminiAPIService.GenerationError? // エラー表示用
    @State private var showingErrorAlert: Bool = false // エラーアラート表示フラグ
    //追加分
    @State private var frontContent: String = ""
    @State private var backContent: String = ""

    // GeminiAPIServiceのインスタンスを保持
    private let geminiService = GeminiAPIService()
    // --- ▲▲▲ State変数ここまで ▲▲▲ ---


    // 手動保存ボタンの有効/無効を判定
    var isManualSaveDisabled: Bool {
        frontText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || // 表面か裏面のどちらかは入力必須
        backText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    // 自動生成実行ボタンの有効/無効を判定
    var isGenerateDisabled: Bool {
        generationTheme.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || generationCount <= 0 || isGenerating
    }

    var body: some View {
        // WordCardCreationView.swift の body 内

        NavigationStack {
            // VStackで Picker と if/else を囲む
            VStack(spacing: 0) { // spacing: 0 などで見た目を調整
                Picker("追加モード", selection: $selectedMode) {
                    ForEach(CreationMode.allCases) { mode in
                        Text(mode.rawValue).tag(mode)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)
                .padding(.bottom, 5) // Formとの間隔調整

                // モードに応じて表示を切り替え
                if selectedMode == .manual {
                    manualInputForm // 手動入力フォームを表示
                } else {
                    automaticGenerationForm // 自動生成フォームを表示
                }
            } // VStack の閉じ括弧
            // --- モディファイアを VStack に適用 ---
            .navigationTitle(selectedMode == .manual ? "新しい単語カード" : "単語を自動生成")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("キャンセル") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    if selectedMode == .manual {

                        Button("保存") { saveManualWordCard() }
                            .disabled(isManualSaveDisabled)
                            
                    } else {

                        Button("保存") { saveGeneratedWordCards() }
                           .disabled(generatedPairs.isEmpty || isGenerating)

                    }
                }
            }
            .alert("エラー", isPresented: $showingErrorAlert, presenting: generationError) { error in
                 Button("OK") {}
             } message: { error in
                 Text(error.localizedDescription)
             }
            .animation(.default, value: selectedMode) // animationもここに移動した方が良いかも
            // --- モディファイアここまで ---
        } // NavigationStack の閉じ括弧
        .animation(.default, value: selectedMode) // モード切り替え時にアニメーション
    }

    // --- ▼▼▼ 手動入力フォーム ▼▼▼ ---
    private var manualInputForm: some View {
        Form {
            Section("表面 (英語など)") {
                TextEditor(text: $frontText)
                    .frame(minHeight: 80)
            }
            Section("裏面 (日本語訳など)") {
                TextEditor(text: $backText)
                    .frame(minHeight: 80)
            }
        }
    }
    // --- ▲▲▲ 手動入力フォームここまで ▲▲▲ ---

    // --- ▼▼▼ 自動生成フォーム ▼▼▼ ---
    private var automaticGenerationForm: some View {
        Form {
            Section("生成条件") {
                // Stepper で数を +/- するか、TextField で直接入力させるか選択
                Stepper("生成する単語数： \(generationCount)", value: $generationCount, in: 1...30) // 上限は適宜設定

                HStack {
                   Text("テーマ：")
                        
                   TextField("例： 果物、旅行、ビジネス", text: $generationTheme)
               }
            }
            Section("表の内容"){
                TextField("例：英語", text: $frontContent)
            }
            Section("裏の内容"){
                TextField("例：日本語訳", text: $backContent)
            }

            Section {
                Button {
                    // キーボードを閉じる (任意)
                    hideKeyboard()
                    // 生成処理を開始
                    Task {
                       await generateAndPreviewWords()
                   }
                } label: {
                    HStack {
                        Spacer()
                        if isGenerating {
                            ProgressView() // 生成中はインジケーター
                                .padding(.trailing, 5)
                            Text("生成中...")
                        } else {
                            Image(systemName: "wand.and.stars")
                                .foregroundStyle(Color.blue)
                            Text("単語を生成する")
                                .foregroundStyle(Color.blue)
                                .fontWeight(.bold)
                        }
                        Spacer()
                    }
                }
                //.buttonStyle(.borderedProminent)
                .tint(.blue) // ボタンの色
                .disabled(isGenerateDisabled) // 条件を満たさない or 生成中は無効
            }
            .listRowBackground(
                Rectangle().fill(Color.blue.opacity(0.2))
            )

            // --- ▼▼▼ 生成結果プレビュー (任意) ▼▼▼ ---
            if !generatedPairs.isEmpty {
                Section("生成された単語 (\(generatedPairs.count)件)") {
                    List(generatedPairs) { pair in
                        HStack {
                           Text(pair.english)
                                .fontWeight(.medium)
                           Spacer()
                           Text(pair.japanese)
                                .foregroundColor(.gray)
                       }
                    }
                    // リストの高さを調整したい場合
                     .frame(minHeight: CGFloat(generatedPairs.count) * 45, maxHeight: 300)
                }
            }
             // --- ▲▲▲ プレビューここまで ▲▲▲ ---
        }
    }
    // --- ▲▲▲ 自動生成フォームここまで ▲▲▲ ---


    // --- ▼▼▼ 手動保存処理 ▼▼▼ ---
    private func saveManualWordCard() {
        let trimmedFront = frontText.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedBack = backText.trimmingCharacters(in: .whitespacesAndNewlines)

        let newCard = WordCard(frontText: trimmedFront, backText: trimmedBack)
        saveWordCardToModelContext(newCard) // 共通化された保存処理へ

        dismiss()
    }
    // --- ▲▲▲ 手動保存処理ここまで ▲▲▲ ---

    // --- ▼▼▼ Gemini API を呼び出して単語生成＆プレビュー ▼▼▼ ---
    private func generateAndPreviewWords() async {
        isGenerating = true
        generationError = nil // エラーをリセット
        generatedPairs = [] // 前回の結果をクリア

        let result = await geminiService.generateWords(count: generationCount, theme: generationTheme, frontContent: frontContent, backContent: backContent)

        switch result {
        case .success(let pairs):
            generatedPairs = pairs // 取得したペアをプレビュー用にセット
            if pairs.isEmpty {
                 // 成功したが0件だった場合のエラー（APIサービス側でエラーにする選択肢もある）
                generationError = .parsingError("AIは単語を生成しましたが、有効な形式のペアが見つかりませんでした。テーマや指示を変えて試してください。")
                showingErrorAlert = true
            }
        case .failure(let error):
            generationError = error // エラー情報をセット
            showingErrorAlert = true // アラートを表示
        }

        isGenerating = false // 生成完了
    }
    // --- ▲▲▲ 生成処理ここまで ▲▲▲ ---

    // --- ▼▼▼ 生成された単語を SwiftData に保存 ▼▼▼ ---
    private func saveGeneratedWordCards() {
        guard !generatedPairs.isEmpty else { return } // 保存対象がなければ何もしない

        for pair in generatedPairs {
            let newCard = WordCard(frontText: pair.english, backText: pair.japanese)
            saveWordCardToModelContext(newCard) // 共通化された保存処理へ
        }

        // 保存後、プレビューをクリア (任意)
         generatedPairs = []

        dismiss() // シートを閉じる
    }
    // --- ▲▲▲ 生成された単語の保存ここまで ▲▲▲ ---

    // --- ▼▼▼ WordCardをModelContextに保存する共通処理 ▼▼▼ ---
    private func saveWordCardToModelContext(_ newCard: WordCard) {
        // 1. ModelContextに挿入
        modelContext.insert(newCard)

        // 2. Wordbookとの関連付け
        if wordbook.words == nil {
            wordbook.words = []
        }
        wordbook.words?.append(newCard)

        // 3. CardからWordbookへの参照も設定
        newCard.wordbook = wordbook

        // SwiftDataは自動保存することが多いですが、確実に保存したい場合は try? modelContext.save() を呼ぶ
        // do {
        //     try modelContext.save()
        // } catch {
        //     print("Failed to save new card or update wordbook: \(error)")
        //     // エラーハンドリング (例: ユーザーに通知)
        // }
    }
    // --- ▲▲▲ 共通保存処理ここまで ▲▲▲ ---

    // --- ▼▼▼ キーボードを閉じるヘルパー ▼▼▼ ---
    private func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
    // --- ▲▲▲ キーボードヘルパーここまで ▲▲▲ ---
}

// --- ▼▼▼ プレビュー用の調整 ▼▼▼ ---
#Preview("Manual Mode") {
    // NavigationStack で囲むとタイトルが表示されやすい
    NavigationStack {
         WordCardCreationView(wordbook: PreviewContainer.sampleWordbooks[0])
            .modelContainer(PreviewContainer.previewInMemory)
    }

}

#Preview("Automatic Mode") {
    NavigationStack {
         WordCardCreationView(wordbook: PreviewContainer.sampleWordbooks[0]) // 初期モードを指定
            .modelContainer(PreviewContainer.previewInMemory)
    }
}
// --- ▲▲▲ プレビューここまで ▲▲▲ ---
