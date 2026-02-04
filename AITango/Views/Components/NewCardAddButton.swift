import SwiftUI



struct CapsuleButtonStyle: ButtonStyle {
    // ボタンの背景色（デフォルトは青）
    var backgroundColor: Color = .blue
    // ボタンの文字色（デフォルトは白）
    var foregroundColor: Color = .white

    // ボタンの本体を生成するメソッド
    func makeBody(configuration: Configuration) -> some View {
        configuration.label // ボタンに表示されるテキストやアイコンなど
            .padding(.horizontal, 10) // 水平方向にパディングを追加
            .padding(.vertical, 15)   // 垂直方向にパディングを追加
            .background(backgroundColor) // 背景色を設定
            .foregroundColor(foregroundColor) // 文字色を設定
            .clipShape(Capsule()) // ビューをカプセル形状にクリップ
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0) // 押されたときに少し縮小するアニメーション
            .animation(.easeOut(duration: 0.2), value: configuration.isPressed) // アニメーション効果を追加
    }
}




struct NewCardAddButton: View{

    let action: () -> Void
    let titleText: String

    var body: some View{
        Button(action: action){
            HStack{
                Image(systemName: "plus")
                .fontWeight(.heavy)

                Text(titleText)
                .fontWeight(.heavy)
            }
            //.padding()
            
        }
        .buttonStyle(CapsuleButtonStyle(backgroundColor: .orange)) // 作成したカプセルスタイルを適用（色をオレンジに指定）
        
    }

}




// プレビュー用の設定
struct CustomButtonView_Previews: PreviewProvider {
    static var previews: some View {
        NewCardAddButton(action: {print("押された")}, titleText: "New Card")
    }
}
