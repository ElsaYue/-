//
//  network.swift
//  photoPPT
//
//  Created by Figo on 2024/10/26.
//

import Foundation
import Combine

class NetworkManager: NSObject, URLSessionDataDelegate {
    static let shared = NetworkManager()
    private var session: URLSession!
    private var dataSubject: PassthroughSubject<String, Error>?
    
    private override init() {
        super.init()
        let config = URLSessionConfiguration.default
        session = URLSession(configuration: config, delegate: self, delegateQueue: nil)
    }
    
    func processImageStream(imageData: Data) -> AnyPublisher<String, Error> {
        let urlString = "http://8.147.233.248:4000/process_image"
        guard let url = URL(string: urlString) else {
            return Fail(error: NSError(domain: "无效URL", code: 0, userInfo: nil)).eraseToAnyPublisher()
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let base64Image = imageData.base64EncodedString()
        let jsonBody: [String: Any] = ["image_base64": base64Image]
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: jsonBody)
        } catch {
            return Fail(error: error).eraseToAnyPublisher()
        }
        
        dataSubject = PassthroughSubject<String, Error>()
        
        let task = session.dataTask(with: request)
        task.resume()
        
        return dataSubject!.eraseToAnyPublisher()
    }
    
    func processTextStream(allText: String) -> AnyPublisher<String, Error> {
        let urlString = "http://8.147.233.248:4000/process_text"
        guard let url = URL(string: urlString) else {
            return Fail(error: NSError(domain: "无效URL", code: 0, userInfo: nil)).eraseToAnyPublisher()
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let jsonBody: [String: Any] = ["all_text": allText]
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: jsonBody)
        } catch {
            return Fail(error: error).eraseToAnyPublisher()
        }
        
        dataSubject = PassthroughSubject<String, Error>()
        
        let task = session.dataTask(with: request)
        task.resume()
        
        return dataSubject!.eraseToAnyPublisher()
    }
    
    func processTextMeaningStream(text: String) -> AnyPublisher<String, Error> {
        let urlString = "http://8.147.233.248:4000/process_text_meaning"
        guard let url = URL(string: urlString) else {
            return Fail(error: NSError(domain: "无效URL", code: 0, userInfo: nil)).eraseToAnyPublisher()
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let jsonBody: [String: Any] = ["text": text]
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: jsonBody)
        } catch {
            return Fail(error: error).eraseToAnyPublisher()
        }
        
        dataSubject = PassthroughSubject<String, Error>()
        
        let task = session.dataTask(with: request)
        task.resume()
        
        return dataSubject!.eraseToAnyPublisher()
    }
    
    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        if let string = String(data: data, encoding: .utf8) {
            dataSubject?.send(string)
        }
    }
    
    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        if let error = error {
            dataSubject?.send(completion: .failure(error))
        } else {
            dataSubject?.send(completion: .finished)
        }
        dataSubject = nil
    }
    
    func processKeyword(allText: String) -> AnyPublisher<String, Error> {
        let urlString = "http://8.147.233.248:4000/process_keyword"
        guard let url = URL(string: urlString) else {
            return Fail(error: NSError(domain: "无效URL", code: 0, userInfo: nil)).eraseToAnyPublisher()
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let jsonBody: [String: Any] = ["all_text": allText]
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: jsonBody)
        } catch {
            return Fail(error: error).eraseToAnyPublisher()
        }
        
        return URLSession.shared.dataTaskPublisher(for: request)
            .tryMap { data, response in
                guard let httpResponse = response as? HTTPURLResponse,
                      (200...299).contains(httpResponse.statusCode) else {
                    throw NSError(domain: "服务器错误", code: 0, userInfo: nil)
                }
                
                let jsonResult = try JSONDecoder().decode(KeywordResponse.self, from: data)
                return jsonResult.result
            }
            .eraseToAnyPublisher()
    }
}

struct KeywordResponse: Codable {
    let result: String
}
