// Cursor_Test/Views/Components/CapsuleSegmentedControl.swift

import SwiftUI
import UIKit


// --- ▼▼▼ 各セグメントを表示するための新しいプライベートView ▼▼▼ ---
private struct SegmentItemView<SelectionValue>: View where SelectionValue: Hashable & CaseIterable & RawRepresentable, SelectionValue.RawValue == String {
    let item: SelectionValue
    @Binding var selection: SelectionValue
    let namespace: Namespace.ID

    // スタイル関連のパラメータも受け取る
    let selectedTextColor: Color
    let deselectedTextColor: Color
    let highlightColor: Color
    let font: Font
    let verticalPadding: CGFloat
    let horizontalPadding: CGFloat
    let animation: Animation // タップ時のアニメーション用

    // 触覚フィードバックジェネレータ (タップごとに生成するシンプルな方法)
    private func triggerHapticFeedback() {
        // 現在の選択と異なる場合にのみフィードバックを再生
        if selection != item {
            let generator = UIImpactFeedbackGenerator(style: .heavy) // .light や .medium が適切
            let intensityValue: CGFloat = 0.5
            generator.prepare() // 準備 (任意だが推奨)
            generator.impactOccurred(intensity: intensityValue) // タップに対するインパクトフィードバック
        }
    }

    var body: some View {
        ZStack {
            // 選択中のハイライト (変更なし)
            if selection == item {
                Capsule()
                    .fill(highlightColor)
                    .matchedGeometryEffect(id: "highlight", in: namespace)
                    .shadow(color: .black.opacity(0.1), radius: 2, y: 1)
            }

            // テキスト表示 (変更なし)
            Text(item.rawValue)
                .font(font)
                .fontWeight(.bold)
                //.fontWeight(selection == item ? .medium : .regular)
                .padding(.vertical, verticalPadding)
                .padding(.horizontal, horizontalPadding)
                .frame(maxWidth:.infinity)
                .foregroundColor(selection == item ? selectedTextColor : deselectedTextColor)
                .contentShape(Rectangle())
                .accessibilityLabel(item.rawValue)
                
        }
        .contentShape(Capsule())
        .onTapGesture {
            // --- 触覚フィードバックをトリガー ---
            triggerHapticFeedback()
            // ---

            // アニメーション付きで選択状態を変更
            withAnimation(animation) {
                selection = item
            }
        }
        // アクセシビリティ設定 (変更なし)
        .accessibilityElement(children: .combine)
        .accessibilityHint("選択肢を変更します")
        .accessibilityAddTraits(selection == item ? .isSelected : [])
    }
}
// --- ▲▲▲ 新しいView定義ここまで ▲▲▲ ---


// --- CapsuleSegmentedControl 本体 ---
struct CapsuleSegmentedControl<SelectionValue>: View where SelectionValue: Hashable & CaseIterable & RawRepresentable, SelectionValue.RawValue == String {

    // プロパティ (変更なし)
    let items: [SelectionValue]
    @Binding var selection: SelectionValue
    let namespace: Namespace.ID

    // スタイルパラメータ (変更なし)
    var selectedTextColor: Color = .white
    var deselectedTextColor: Color = .accentColor
    var highlightColor: Color = .accentColor
    var backgroundColor: Color = Color(uiColor: .systemGray5)
    var font: Font = .subheadline
    var verticalPadding: CGFloat = 8
    var horizontalPadding: CGFloat = 12
    var spacing: CGFloat = 4
    var animation: Animation = .interactiveSpring(response: 0.3, dampingFraction: 0.7, blendDuration: 0.3)

    var body: some View {
        HStack(spacing: spacing) {
            ForEach(items, id: \.self) { item in
                
                SegmentItemView(
                    item: item,
                    selection: $selection,
                    namespace: namespace,
                    selectedTextColor: selectedTextColor,
                    deselectedTextColor: deselectedTextColor,
                    highlightColor: highlightColor,
                    font: font,
                    verticalPadding: verticalPadding,
                    horizontalPadding: horizontalPadding,
                    animation: animation // アニメーションも渡す
                )
                
            }
        }
        .background(backgroundColor) // 背景色
        .clipShape(Capsule()) // 全体をカプセル形状に
        .frame(maxHeight: 70)
    }
}

// --- プレビュー用のヘルパー  ---
private enum PreviewMode: String, CaseIterable {
    case first = "選択肢 A"
    case second = "選択肢 B"
    case third = "選択肢 C"
}

#Preview("Default Style") { // デフォルトスタイルプレビュー (変更なし)
    struct PreviewWrapper: View {
        @State private var currentMode: PreviewMode = .first
        @Namespace private var previewNamespace

        var body: some View {
            VStack {
                Text("選択中: \(currentMode.rawValue)")
                    .padding(.bottom)

                CapsuleSegmentedControl(
                    items: Array(PreviewMode.allCases),
                    selection: $currentMode,
                    namespace: previewNamespace
                )
                .padding()
            }
        }
    }
    return PreviewWrapper()
}

#Preview("Custom Style") { // カスタムスタイル用のプレビュー (変更なし)
    struct PreviewWrapper: View {
        @State private var currentMode: PreviewMode = .second
        @Namespace private var previewNamespace

        var body: some View {
            VStack {
                Text("選択中: \(currentMode.rawValue)")
                    .padding(.bottom)

                CapsuleSegmentedControl(
                    items: Array(PreviewMode.allCases),
                    selection: $currentMode,
                    namespace: previewNamespace,
                    selectedTextColor: .black,
                    deselectedTextColor: .indigo,
                    highlightColor: .orange,
                    backgroundColor: .indigo.opacity(0.1),
                    font: .caption.weight(.bold),
                    verticalPadding: 10,
                    horizontalPadding: 16,
                    spacing: 2,
                    animation: .smooth(duration: 0.4)
                )
                .padding()
            }
        }
    }
    return PreviewWrapper()
}
