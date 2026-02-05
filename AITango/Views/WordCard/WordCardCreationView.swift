// Cursor_Test/Views/WordCard/WordCardCreationView.swift

import SwiftData
import SwiftUI

// 追加モードを定義
enum CreationMode: String, CaseIterable, Identifiable {
  case manual = "手動で追加"
  case automatic = "自動生成"
  var id: String { self.rawValue }
}

struct WordCardCreationView: View {
  @Environment(\.modelContext) private var modelContext
  @Environment(\.dismiss) private var dismiss
  var wordbook: Wordbook

  @State private var selectedMode: CreationMode = .manual
  @Namespace private var creationModeNamespace

  // 手動入力用
  @State private var frontText: String = ""
  @State private var backText: String = ""

  // 自動生成用
  @State private var generationCount: Int = 5
  @State private var generationTheme: String = ""
  @State private var isGenerating: Bool = false
  @State private var generatedPairs: [GeneratedWordPair] = []
  @State private var generationError: GeminiAPIService.GenerationError?
  @State private var showingErrorAlert: Bool = false
  @State private var frontContent: String = ""
  @State private var backContent: String = ""

  private let geminiService = GeminiAPIService()

  var isManualSaveDisabled: Bool {
    frontText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
      || backText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
  }

  var isGenerateDisabled: Bool {
    generationTheme.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || generationCount <= 0
      || isGenerating
  }

  var body: some View {
    NavigationStack {
      ZStack {
        // 背景グラデーション
        LinearGradient(
          colors: [
            Color(uiColor: .systemBackground),
            selectedMode == .manual ? Color.blue.opacity(0.03) : Color.purple.opacity(0.03),
          ],
          startPoint: .top,
          endPoint: .bottom
        )
        .ignoresSafeArea()

        VStack(spacing: 0) {
          // セグメントコントロール
          CapsuleSegmentedControl(
            items: Array(CreationMode.allCases),
            selection: $selectedMode,
            namespace: creationModeNamespace,
            highlightColor: selectedMode == .manual ? .blue : .purple,
            font: .subheadline
          )
          .padding(.horizontal)
          .padding(.top, 8)
          .frame(maxHeight: 50)
          .padding(.bottom, 12)

          // モードに応じたコンテンツ
          if selectedMode == .manual {
            manualInputForm
          } else {
            automaticGenerationForm
          }
        }
      }
      .navigationTitle(selectedMode == .manual ? "新しい単語カード" : "単語を自動生成")
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .navigationBarLeading) {
          Button("キャンセル") { dismiss() }
        }
        ToolbarItem(placement: .navigationBarTrailing) {
          if selectedMode == .manual {
            Button("保存") { saveManualWordCard() }
              .fontWeight(.semibold)
              .disabled(isManualSaveDisabled)
          } else {
            Button("保存") { saveGeneratedWordCards() }
              .fontWeight(.semibold)
              .disabled(generatedPairs.isEmpty || isGenerating)
          }
        }
      }
      .alert("エラー", isPresented: $showingErrorAlert, presenting: generationError) { error in
        Button("OK") {}
      } message: { error in
        Text(error.localizedDescription)
      }
      .animation(.spring(response: 0.3, dampingFraction: 0.8), value: selectedMode)
    }
  }

  // MARK: - 手動入力フォーム
  private var manualInputForm: some View {
    ScrollView {
      VStack(spacing: 20) {
        // 表面カード
        inputCard(
          title: "表面",
          subtitle: "英語など",
          icon: "textformat.abc",
          color: .blue,
          text: $frontText,
          placeholder: "単語を入力..."
        )

        // 裏面カード
        inputCard(
          title: "裏面",
          subtitle: "日本語訳など",
          icon: "character.book.closed",
          color: .green,
          text: $backText,
          placeholder: "意味を入力..."
        )

        Spacer()
      }
      .padding(.horizontal, 16)
      .padding(.vertical, 12)
    }
  }

  // MARK: - 入力カード
  private func inputCard(
    title: String, subtitle: String, icon: String, color: Color, text: Binding<String>,
    placeholder: String
  ) -> some View {
    VStack(alignment: .leading, spacing: 12) {
      HStack {
        ZStack {
          Circle()
            .fill(color.opacity(0.15))
            .frame(width: 36, height: 36)

          Image(systemName: icon)
            .font(.system(size: 16, weight: .semibold))
            .foregroundStyle(color)
        }

        VStack(alignment: .leading, spacing: 2) {
          Text(title)
            .font(.headline)
            .foregroundStyle(.primary)
          Text(subtitle)
            .font(.caption)
            .foregroundStyle(.secondary)
        }
      }

      TextEditor(text: text)
        .frame(minHeight: 100)
        .padding(12)
        .background(
          RoundedRectangle(cornerRadius: 12)
            .fill(Color(uiColor: .systemGray6))
        )
        .overlay(
          RoundedRectangle(cornerRadius: 12)
            .stroke(color.opacity(0.3), lineWidth: 1)
        )
        .overlay(
          Group {
            if text.wrappedValue.isEmpty {
              Text(placeholder)
                .foregroundStyle(.tertiary)
                .padding(.horizontal, 16)
                .padding(.vertical, 20)
                .allowsHitTesting(false)
            }
          },
          alignment: .topLeading
        )
    }
    .padding(16)
    .background(
      RoundedRectangle(cornerRadius: 16)
        .fill(Color(uiColor: .systemBackground))
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 4)
    )
  }

  // MARK: - 自動生成フォーム
  private var automaticGenerationForm: some View {
    ScrollView {
      VStack(spacing: 16) {
        // 生成条件カード
        generationSettingsCard

        // 生成ボタン
        generateButton

        // 生成結果プレビュー
        if !generatedPairs.isEmpty {
          generatedResultsCard
        }
      }
      .padding(.horizontal, 16)
      .padding(.vertical, 12)
    }
  }

  // MARK: - 生成設定カード
  private var generationSettingsCard: some View {
    VStack(spacing: 16) {
      // ヘッダー
      HStack {
        ZStack {
          Circle()
            .fill(Color.purple.opacity(0.15))
            .frame(width: 40, height: 40)

          Image(systemName: "wand.and.stars")
            .font(.system(size: 18, weight: .semibold))
            .foregroundStyle(.purple)
        }

        VStack(alignment: .leading, spacing: 2) {
          Text("生成条件")
            .font(.headline)
          Text("AIが単語を自動生成します")
            .font(.caption)
            .foregroundStyle(.secondary)
        }

        Spacer()
      }

      Divider()

      // 生成数
      HStack {
        Text("生成する単語数")
          .font(.subheadline)
        Spacer()
        Stepper("\(generationCount)", value: $generationCount, in: 1...30)
          .labelsHidden()
        Text("\(generationCount) 個")
          .font(.subheadline)
          .fontWeight(.medium)
          .foregroundStyle(.purple)
          .frame(width: 40)
      }

      // テーマ
      VStack(alignment: .leading, spacing: 8) {
        Text("テーマ")
          .font(.subheadline)
        TextField("例: 果物、旅行、ビジネス", text: $generationTheme)
          .textFieldStyle(ModernTextFieldStyle(color: .purple))
      }

      // 表面の内容
      VStack(alignment: .leading, spacing: 8) {
        Text("表面の内容")
          .font(.subheadline)
        TextField("例: 英語", text: $frontContent)
          .textFieldStyle(ModernTextFieldStyle(color: .blue))
      }

      // 裏面の内容
      VStack(alignment: .leading, spacing: 8) {
        Text("裏面の内容")
          .font(.subheadline)
        TextField("例: 日本語訳", text: $backContent)
          .textFieldStyle(ModernTextFieldStyle(color: .green))
      }
    }
    .padding(16)
    .background(
      RoundedRectangle(cornerRadius: 16)
        .fill(Color(uiColor: .systemBackground))
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 4)
    )
  }

  // MARK: - 生成ボタン
  private var generateButton: some View {
    Button {
      hideKeyboard()
      Task {
        await generateAndPreviewWords()
      }
    } label: {
      HStack(spacing: 10) {
        if isGenerating {
          ProgressView()
            .tint(.white)
          Text("生成中...")
        } else {
          Image(systemName: "wand.and.stars")
            .font(.title3)
          Text("単語を生成する")
            .fontWeight(.bold)
        }
      }
      .font(.headline)
      .foregroundStyle(.white)
      .padding(.vertical, 16)
      .frame(maxWidth: .infinity)
      .background(
        LinearGradient(
          colors: isGenerateDisabled
            ? [.gray.opacity(0.5), .gray.opacity(0.3)]
            : [.purple, .pink.opacity(0.8)],
          startPoint: .leading,
          endPoint: .trailing
        )
      )
      .clipShape(RoundedRectangle(cornerRadius: 14))
      .shadow(
        color: isGenerateDisabled ? .clear : .purple.opacity(0.4),
        radius: 10, x: 0, y: 5
      )
    }
    .disabled(isGenerateDisabled)
  }

  // MARK: - 生成結果カード
  private var generatedResultsCard: some View {
    VStack(alignment: .leading, spacing: 12) {
      HStack {
        Image(systemName: "checkmark.circle.fill")
          .foregroundStyle(.green)
        Text("生成された単語")
          .font(.headline)
        Spacer()
        Text("\(generatedPairs.count)件")
          .font(.subheadline)
          .foregroundStyle(.secondary)
      }

      Divider()

      ForEach(generatedPairs) { pair in
        HStack {
          Text(pair.english)
            .font(.subheadline)
            .fontWeight(.medium)
          Spacer()
          Text(pair.japanese)
            .font(.subheadline)
            .foregroundStyle(.secondary)
        }
        .padding(.vertical, 6)

        if pair.id != generatedPairs.last?.id {
          Divider()
        }
      }
    }
    .padding(16)
    .background(
      RoundedRectangle(cornerRadius: 16)
        .fill(Color(uiColor: .systemBackground))
        .overlay(
          RoundedRectangle(cornerRadius: 16)
            .stroke(Color.green.opacity(0.3), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 4)
    )
  }

  // MARK: - 保存処理
  private func saveManualWordCard() {
    let trimmedFront = frontText.trimmingCharacters(in: .whitespacesAndNewlines)
    let trimmedBack = backText.trimmingCharacters(in: .whitespacesAndNewlines)

    let newCard = WordCard(frontText: trimmedFront, backText: trimmedBack)
    saveWordCardToModelContext(newCard)

    dismiss()
  }

  private func generateAndPreviewWords() async {
    isGenerating = true
    generationError = nil
    generatedPairs = []

    let result = await geminiService.generateWords(
      count: generationCount, theme: generationTheme, frontContent: frontContent,
      backContent: backContent)

    switch result {
    case .success(let pairs):
      generatedPairs = pairs
      if pairs.isEmpty {
        generationError = .parsingError(
          "AIは単語を生成しましたが、有効な形式のペアが見つかりませんでした。テーマや指示を変えて試してください。")
        showingErrorAlert = true
      }
    case .failure(let error):
      generationError = error
      showingErrorAlert = true
    }

    isGenerating = false
  }

  private func saveGeneratedWordCards() {
    guard !generatedPairs.isEmpty else { return }

    for pair in generatedPairs {
      let newCard = WordCard(frontText: pair.english, backText: pair.japanese)
      saveWordCardToModelContext(newCard)
    }

    generatedPairs = []
    dismiss()
  }

  private func saveWordCardToModelContext(_ newCard: WordCard) {
    modelContext.insert(newCard)

    if wordbook.words == nil {
      wordbook.words = []
    }
    wordbook.words?.append(newCard)
    newCard.wordbook = wordbook
  }

  private func hideKeyboard() {
    UIApplication.shared.sendAction(
      #selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
  }
}

// MARK: - モダンなテキストフィールドスタイル
struct ModernTextFieldStyle: TextFieldStyle {
  let color: Color

  func _body(configuration: TextField<Self._Label>) -> some View {
    configuration
      .padding(12)
      .background(
        RoundedRectangle(cornerRadius: 10)
          .fill(Color(uiColor: .systemGray6))
      )
      .overlay(
        RoundedRectangle(cornerRadius: 10)
          .stroke(color.opacity(0.3), lineWidth: 1)
      )
  }
}

// プレビュー
#if DEBUG
  #Preview("Manual Mode") {
    NavigationStack {
      WordCardCreationView(wordbook: PreviewContainer.sampleWordbooks[0])
        .modelContainer(PreviewContainer.previewInMemory)
    }
  }

  #Preview("Automatic Mode") {
    NavigationStack {
      WordCardCreationView(wordbook: PreviewContainer.sampleWordbooks[0])
        .modelContainer(PreviewContainer.previewInMemory)
    }
  }
#endif
