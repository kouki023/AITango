// AITango/Views/AudioPlayer/AudioPlayerTabView.swift

import SwiftData
import SwiftUI

struct AudioPlayerTabView: View {

  @Environment(\.modelContext) private var modelContext
  @Query(sort: [SortDescriptor(\Wordbook.createdAt, order: .reverse)]) private var wordbooks:
    [Wordbook]

  @State private var viewModel = AudioPlayerViewModel()
  @State private var showLanguageSettings = false

  var body: some View {
    NavigationStack {
      Group {
        if viewModel.selectedWordbook != nil {
          // 再生コントロール画面
          playerControlView
        } else {
          // 単語帳選択画面
          wordbookSelectionView
        }
      }
      .navigationTitle("再生")
      .toolbar {
        ToolbarItem(placement: .topBarTrailing) {
          Button {
            showLanguageSettings = true
          } label: {
            Image(systemName: "gearshape")
              .font(.system(size: 16, weight: .medium))
          }
        }
      }
      .sheet(isPresented: $showLanguageSettings) {
        languageSettingsSheet
      }
    }
  }

  // MARK: - 言語設定シート

  private var languageSettingsSheet: some View {
    NavigationStack {
      Form {
        Section {
          Picker("表面の言語", selection: $viewModel.frontLanguage) {
            ForEach(SpeechLanguage.allCases) { lang in
              Text(lang.displayName).tag(lang)
            }
          }

          Picker("裏面の言語", selection: $viewModel.backLanguage) {
            ForEach(SpeechLanguage.allCases) { lang in
              Text(lang.displayName).tag(lang)
            }
          }
        } header: {
          Text("読み上げ言語")
        } footer: {
          Text("カードの表面・裏面をそれぞれ選択した言語の音声で読み上げます")
        }
      }
      .navigationTitle("再生設定")
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .topBarTrailing) {
          Button("完了") {
            showLanguageSettings = false
          }
          .fontWeight(.semibold)
        }
      }
    }
    .presentationDetents([.medium])
  }

  // MARK: - 単語帳選択画面

  private var wordbookSelectionView: some View {
    Group {
      if wordbooks.isEmpty {
        emptyStateView
      } else {
        ScrollView {
          VStack(spacing: 12) {
            // ヘッダー説明
            HStack(spacing: 10) {
              Image(systemName: "speaker.wave.2.fill")
                .font(.title2)
                .foregroundStyle(
                  LinearGradient(
                    colors: [.purple, .blue],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                  )
                )
              VStack(alignment: .leading, spacing: 2) {
                Text("音声再生")
                  .font(.headline)
                  .fontWeight(.bold)
                Text("単語帳を選んで音声で学習しましょう")
                  .font(.caption)
                  .foregroundStyle(.secondary)
              }
              Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)

            // 単語帳リスト
            ForEach(wordbooks) { wordbook in
              wordbookCard(wordbook)
            }
          }
          .padding(.vertical, 12)
        }
      }
    }
  }

  // MARK: - 単語帳カード

  private func wordbookCard(_ wordbook: Wordbook) -> some View {
    Button {
      withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
        viewModel.selectWordbook(wordbook)
      }
    } label: {
      HStack(spacing: 14) {
        // アイコン
        ZStack {
          Circle()
            .fill(
              LinearGradient(
                colors: [.purple.opacity(0.3), .blue.opacity(0.2)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
              )
            )
            .frame(width: 48, height: 48)

          Image(systemName: "headphones")
            .font(.system(size: 20, weight: .semibold))
            .foregroundStyle(
              LinearGradient(
                colors: [.purple, .blue],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
              )
            )
        }

        // テキスト情報
        VStack(alignment: .leading, spacing: 4) {
          Text(wordbook.title)
            .font(.system(.body, design: .rounded, weight: .semibold))
            .foregroundStyle(.primary)
            .lineLimit(1)

          Text("\(wordbook.wordCount) 枚のカード")
            .font(.caption)
            .foregroundStyle(.secondary)
        }

        Spacer()

        // 矢印
        Image(systemName: "chevron.right")
          .font(.system(size: 14, weight: .semibold))
          .foregroundStyle(.tertiary)
      }
      .padding(14)
      .background(
        RoundedRectangle(cornerRadius: 14)
          .fill(Color(uiColor: .secondarySystemGroupedBackground))
      )
      .overlay(
        RoundedRectangle(cornerRadius: 14)
          .stroke(Color(uiColor: .separator).opacity(0.3), lineWidth: 1)
      )
    }
    .buttonStyle(.plain)
    .disabled(wordbook.wordCount == 0)
    .opacity(wordbook.wordCount == 0 ? 0.5 : 1.0)
    .padding(.horizontal, 16)
  }

  // MARK: - 再生コントロール画面

  private var playerControlView: some View {
    VStack(spacing: 0) {
      // 戻るボタン
      HStack {
        Button {
          withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
            viewModel.clearSelection()
          }
        } label: {
          HStack(spacing: 4) {
            Image(systemName: "chevron.left")
              .font(.system(size: 14, weight: .semibold))
            Text("単語帳選択")
              .font(.subheadline)
              .fontWeight(.medium)
          }
          .foregroundStyle(Color.accentColor)
        }
        Spacer()
      }
      .padding(.horizontal, 20)
      .padding(.top, 8)

      Spacer()

      // カード表示エリア
      cardDisplayArea

      Spacer()

      // 進捗バー
      progressSection

      // コントロールボタン
      controlButtons

      Spacer().frame(height: 30)
    }
  }

  // MARK: - カード表示エリア

  private var cardDisplayArea: some View {
    VStack(spacing: 16) {
      // 単語帳タイトル
      if let wordbook = viewModel.selectedWordbook {
        Text(wordbook.title)
          .font(.subheadline)
          .fontWeight(.medium)
          .foregroundStyle(.secondary)
      }

      // 現在のカード情報
      VStack(spacing: 20) {
        if let card = viewModel.currentCard {
          // 表面
          VStack(spacing: 6) {
            Text("おもて")
              .font(.caption2)
              .fontWeight(.bold)
              .textCase(.uppercase)
              .foregroundStyle(
                viewModel.currentSide == .front && viewModel.isPlaying
                  ? .purple : .secondary
              )
              .tracking(1.5)

            Text(card.frontText)
              .font(.system(.title2, design: .rounded, weight: .bold))
              .foregroundStyle(.primary)
              .multilineTextAlignment(.center)
              .lineLimit(3)
              .scaleEffect(viewModel.currentSide == .front && viewModel.isPlaying ? 1.02 : 1.0)
              .animation(.easeInOut(duration: 0.3), value: viewModel.currentSide)
          }
          .padding(.vertical, 12)

          // 区切り線
          Divider()
            .padding(.horizontal, 40)

          // 裏面
          VStack(spacing: 6) {
            Text("うら")
              .font(.caption2)
              .fontWeight(.bold)
              .textCase(.uppercase)
              .foregroundStyle(
                viewModel.currentSide == .back && viewModel.isPlaying
                  ? .blue : .secondary
              )
              .tracking(1.5)

            Text(card.backText)
              .font(.system(.title3, design: .rounded, weight: .semibold))
              .foregroundStyle(.secondary)
              .multilineTextAlignment(.center)
              .lineLimit(3)
              .scaleEffect(viewModel.currentSide == .back && viewModel.isPlaying ? 1.02 : 1.0)
              .animation(.easeInOut(duration: 0.3), value: viewModel.currentSide)
          }
          .padding(.vertical, 12)

        } else if viewModel.playbackState == .finished {
          // 再生完了
          VStack(spacing: 12) {
            Image(systemName: "checkmark.circle.fill")
              .font(.system(size: 48))
              .foregroundStyle(
                LinearGradient(
                  colors: [.green, .mint],
                  startPoint: .topLeading,
                  endPoint: .bottomTrailing
                )
              )
            Text("すべてのカードを再生しました")
              .font(.headline)
              .fontWeight(.semibold)
            Text("もう一度再生するか、別の単語帳を選びましょう")
              .font(.caption)
              .foregroundStyle(.secondary)
          }
        } else {
          // 待機中
          VStack(spacing: 12) {
            Image(systemName: "waveform")
              .font(.system(size: 40))
              .foregroundStyle(.tertiary)
              .symbolEffect(
                .variableColor.iterative,
                options: .repeating,
                isActive: false)
            Text("再生ボタンを押してスタート")
              .font(.subheadline)
              .foregroundStyle(.secondary)
          }
        }
      }
      .padding(24)
      .frame(maxWidth: .infinity)
      .background(
        RoundedRectangle(cornerRadius: 20)
          .fill(Color(uiColor: .secondarySystemGroupedBackground))
      )
      .overlay(
        RoundedRectangle(cornerRadius: 20)
          .stroke(
            viewModel.isPlaying
              ? LinearGradient(
                colors: [.purple.opacity(0.4), .blue.opacity(0.4)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
              )
              : LinearGradient(
                colors: [Color(uiColor: .separator).opacity(0.3)],
                startPoint: .leading,
                endPoint: .trailing
              ),
            lineWidth: viewModel.isPlaying ? 1.5 : 1
          )
      )
      .padding(.horizontal, 20)
    }
  }

  // MARK: - 進捗セクション

  private var progressSection: some View {
    VStack(spacing: 8) {
      // プログレスバー
      GeometryReader { geometry in
        ZStack(alignment: .leading) {
          RoundedRectangle(cornerRadius: 4)
            .fill(Color(uiColor: .systemGray5))
            .frame(height: 6)

          RoundedRectangle(cornerRadius: 4)
            .fill(
              LinearGradient(
                colors: [.purple, .blue],
                startPoint: .leading,
                endPoint: .trailing
              )
            )
            .frame(
              width: geometry.size.width * viewModel.progressValue,
              height: 6
            )
            .animation(.easeInOut(duration: 0.3), value: viewModel.progressValue)
        }
      }
      .frame(height: 6)

      // 進捗テキスト
      HStack {
        Text(viewModel.progressText)
          .font(.system(.caption, design: .rounded, weight: .medium))
          .foregroundStyle(.secondary)

        Spacer()

        if viewModel.isPlaying {
          HStack(spacing: 4) {
            Image(systemName: viewModel.currentSide == .front ? "textformat" : "textformat.abc")
              .font(.caption2)
            Text(viewModel.currentSide == .front ? "おもて" : "うら")
              .font(.caption)
              .fontWeight(.medium)
          }
          .foregroundStyle(viewModel.currentSide == .front ? .purple : .blue)
          .transition(.opacity)
        }
      }
    }
    .padding(.horizontal, 24)
    .padding(.bottom, 24)
  }

  private var controlButtons: some View {
    // 再生/一時停止トグルボタン
    Button {
      withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
        viewModel.togglePlayPause()
      }
    } label: {
      ZStack {
        Circle()
          .fill(Color.accentColor)
          .frame(width: 72, height: 72)

        Image(systemName: playPauseIconName)
          .font(.system(size: 28, weight: .bold))
          .foregroundStyle(.white)
          .contentTransition(.symbolEffect(.replace))
      }
    }
    .disabled(viewModel.cards.isEmpty)
    .opacity(viewModel.cards.isEmpty ? 0.4 : 1.0)
  }

  /// 再生/一時停止ボタンのアイコン名
  private var playPauseIconName: String {
    switch viewModel.playbackState {
    case .playing:
      return "pause.fill"
    case .finished:
      return "arrow.counterclockwise"
    case .idle:
      return "play.fill"
    }
  }

  // MARK: - 空の状態

  private var emptyStateView: some View {
    VStack(spacing: 16) {
      Image(systemName: "book.closed")
        .font(.system(size: 48))
        .foregroundStyle(.tertiary)

      Text("単語帳がありません")
        .font(.headline)
        .fontWeight(.semibold)

      Text("「単語帳」タブから単語帳を作成しましょう")
        .font(.subheadline)
        .foregroundStyle(.secondary)
        .multilineTextAlignment(.center)
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .padding(.bottom, 60)
  }
}

// MARK: - Preview

#if DEBUG
  #Preview("再生タブ") {
    AudioPlayerTabView()
      .modelContainer(PreviewContainer.previewInMemoryWithLinkedData)
  }

  #Preview("空の状態") {
    AudioPlayerTabView()
      .modelContainer(PreviewContainer.empty)
  }
#endif
