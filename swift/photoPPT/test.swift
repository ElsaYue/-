//
//  test.swift
//  photoPPT
//
//  Created by Figo on 2024/10/26.
//

import SwiftUI

struct TestView: View {
    @State private var content: String = ""
    
    var body: some View {
        VStack {
            Text(content)
                .padding()
            
            Button("发送请求") {
                print("按钮被点击")
                sendRequest()
            }
            .padding()
        }
    }
    
    func sendRequest() {
        guard let url = URL(string: "http://8.147.233.248:4000/") else {
            print("URL 无效")
            content = "无效的 URL"
            return
        }
        
        print("开始发送请求到: \(url)")
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            if let error = error {
                print("请求错误: \(error.localizedDescription)")
                DispatchQueue.main.async {
                    self.content = "错误: \(error.localizedDescription)"
                }
                return
            }
            
            if let httpResponse = response as? HTTPURLResponse {
                print("HTTP 状态码: \(httpResponse.statusCode)")
            }
            
            if let data = data {
                print("收到数据长度: \(data.count) 字节")
                if let responseString = String(data: data, encoding: .utf8) {
                    print("响应内容: \(responseString)")
                    DispatchQueue.main.async {
                        self.content = responseString
                    }
                } else {
                    print("无法将数据解析为字符串")
                    DispatchQueue.main.async {
                        self.content = "无法解析响应"
                    }
                }
            } else {
                print("没有收到数据")
                DispatchQueue.main.async {
                    self.content = "无响应数据"
                }
            }
        }.resume()
    }
}

struct TestView_Previews: PreviewProvider {
    static var previews: some View {
        TestView()
    }
}
