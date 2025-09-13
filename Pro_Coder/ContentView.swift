import SwiftUI
// --------------- “匯入 SwiftUI 框架，用來建 UI”

struct ServerReply: Codable {
    let status: String
    let message: ChatMessageData
}
// --------------- “定義伺服器回傳 JSON 的資料格式（最外層結構）”

struct ChatMessageData: Codable {
    let text: String
}
// --------------- “伺服器回傳的訊息內容格式（內層 text）”

struct ChatMessage: Identifiable {
    let id = UUID()
    let text: String
    let isUser: Bool
}
// --------------- “本地端聊天訊息模型，供 SwiftUI 顯示使用”

struct ContentView: View {

    #if targetEnvironment(simulator)
        private let serverBase = "http://127.0.0.1:3000"
    #else
        private let serverBase = "http://172.20.10.2:3000"
    #endif
// --------------- “依照實機/模擬器切換伺服器位址”

    @State private var inputText: String = " "
    @State private var messages: [ChatMessage] = [
        ChatMessage(text: "Hello，我是甲方", isUser: false)
    ]
// --------------- “設定輸入框與訊息列表的狀態變數（UI 自動更新）”

    var body: some View {
        VStack {
// --------------- “整體 UI vertical 垂直排列”

            ScrollView {
// --------------- “可捲動區域顯示所有訊息氣泡”

                ForEach(messages) { m in
// --------------- “逐一渲染每一則訊息”

                    HStack {
// --------------- “每條訊息水平排列（左邊伺服器、右邊使用者）”

                        if m.isUser {
                            Spacer()
                            Text(m.text)
                                .padding()
                                .background(.blue)
                                .foregroundColor(.white)
                                .cornerRadius(10)
                            // --------------- “使用者訊息靠右顯示”
                        } else {
                            Text(m.text)
                                .padding()
                                .background(.gray.opacity(0.2))
                                .cornerRadius(10)
                            Spacer()
                            // --------------- “伺服器訊息靠左顯示”
                        }
                    }
                    .padding(.horizontal)
                    // --------------- “訊息泡泡左右留白”
                }
            }

            HStack {
// --------------- “輸入框 + 送出按鈕水平排列區域”

                TextField("輸入訊息", text: $inputText)
                    .textFieldStyle(.roundedBorder)
                // --------------- “聊天輸入框”

                Button("送出") {
                    guard !inputText.isEmpty else { return }
                    // --------------- “避免空訊息送出”

                    let text = inputText
                    messages.append(ChatMessage(text: text, isUser: true))
                    // --------------- “先把使用者訊息加到畫面上”

                    inputText = ""
                    // --------------- “清空輸入框”

                    sendMessage(text)
                    // --------------- “送到伺服器”
                }
            }
            .padding()
            // --------------- “輸入區塊上下留白”
        }
    }

    private func sendMessage(_ text: String) {
        guard let url = URL(string: "\(serverBase)/message") else { return }
        // --------------- “組合 API 路徑：POST /message”

        let payload = ["text": text]
        guard let body = try? JSONSerialization.data(withJSONObject: payload) else { return }
        // --------------- “把文字包成 JSON 格式傳給伺服器”

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = body
        // --------------- “設定 HTTP POST 請求內容”

        URLSession.shared.dataTask(with: request) { data, _, error in
        // --------------- “使用 URLSession 發送 HTTP 請求”

            if let error = error {
                DispatchQueue.main.async {
                    messages.append(ChatMessage(text: "❌ \(error.localizedDescription)", isUser: false))
                }
                return
                // --------------- “若發生錯誤（伺服器未開等）顯示錯誤訊息”
            }

            guard let data = data else { return }
            // --------------- “確保有收到資料”

            if let reply = try? JSONDecoder().decode(ServerReply.self, from: data) {
                DispatchQueue.main.async {
                    messages.append(ChatMessage(text: reply.message.text, isUser: false))
                }
                // --------------- “成功解析 JSON → 顯示伺服器回覆”
            } else {
                let raw = String(data: data, encoding: .utf8) ?? "(no data)"
                DispatchQueue.main.async {
                    messages.append(ChatMessage(text: "⚠️ 非預期回應：\(raw)", isUser: false))
                }
                // --------------- “解析失敗 → 印出原始文字方便除錯”
            }
        }
        .resume()
        // --------------- “啟動 HTTP 請求”
    }
}

#Preview {
    ContentView()
}
// --------------- “Xcode 預覽畫面”
