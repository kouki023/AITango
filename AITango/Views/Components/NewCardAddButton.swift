import SwiftUI

struct NewCardAddButton: View {

    /// 表示する SF Symbol 名（配置先ごとに変更可能）
    var systemName: String = "book.badge.plus.fill"
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            // SF Symbol のみ、円形ボタン
            Image(systemName: systemName)
                .font(.system(size: 24, weight: .bold))
                .foregroundStyle(.white)
                .frame(width: 65, height: 65)
                .background(
                    Circle()
                        .fill(Color.accentColor)
                        .shadow(color: Color.accentColor.opacity(0.35), radius: 8, x: 0, y: 4)
                )
        }
        .scaleEffect(1.0)
        .buttonStyle(CircleAddButtonStyle())
    }
}

// MARK: - 円形ボタン用スタイル
struct CircleAddButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.9 : 1.0)
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
    }
}

// MARK: - Preview
#if DEBUG
    struct NewCardAddButton_Previews: PreviewProvider {
        static var previews: some View {
            NewCardAddButton(action: { print("押された") })
        }
    }
#endif
