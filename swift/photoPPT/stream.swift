//
//  stream.swift
//  photoPPT
//
//  Created by Figo on 2024/10/27.
//

import SwiftUI
import Combine

class StreamManager: ObservableObject {
    @Published var responseText = ""
    var cancellables = Set<AnyCancellable>()
}

struct StreamView: View {
    @StateObject private var streamManager = StreamManager()
    @State private var isProcessing = false
    
    var body: some View {
        VStack {
            ScrollView {
                Text(streamManager.responseText)
                    .padding()
            }
            
            Button("处理图片") {
                processImage()
            }
            .disabled(isProcessing)
            .padding()
            
            if isProcessing {
                ProgressView()
            }
        }
    }
    
    private func processImage() {
        guard let imageURL = Bundle.main.url(forResource: "WechatIMG19500", withExtension: "jpeg"),
              let imageData = try? Data(contentsOf: imageURL) else {
            print("无法加载图片")
            return
        }
        
        isProcessing = true
        streamManager.responseText = ""
        
        NetworkManager.shared.processImageStream(imageData: imageData)
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { completion in
                isProcessing = false
                switch completion {
                case .finished:
                    break
                case .failure(let error):
                    print("错误: \(error.localizedDescription)")
                    streamManager.responseText += "\n处理图片时发生错误：\(error.localizedDescription)"
                }
            }, receiveValue: { value in
                streamManager.responseText += value  // 追加接收到的值
            })
            .store(in: &streamManager.cancellables)
    }
}

struct StreamView_Previews: PreviewProvider {
    static var previews: some View {
        StreamView()
    }
}
