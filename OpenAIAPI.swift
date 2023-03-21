//
//  OpenAIAPI.swift
//  SirTalkaLot
//
//  Created by Ben Cady on 3/17/23.
//

import Foundation

struct OpenAIAPI {
    static let apiKey = "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"
    static let apiUrl = "https://api.openai.com/v1/engines/davinci-codex/completions"

    static func sendRequest(prompt: String, completion: @escaping (Result<String, Error>) -> Void) {
        var request = URLRequest(url: URL(string: apiUrl)!)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let json: [String: Any] = [
            "prompt": prompt,
            "max_tokens": 150,
            "n": 1,
            "stop": ["\n"]
        ]

        let jsonData = try! JSONSerialization.data(withJSONObject: json)
        request.httpBody = jsonData

        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }

            if let data = data {
                let json = try! JSONSerialization.jsonObject(with: data) as! [String: Any]
                if let choices = json["choices"] as? [[String: Any]],
                   let choice = choices.first,
                   let text = choice["text"] as? String {
                    completion(.success(text.trimmingCharacters(in: .whitespacesAndNewlines)))
                } else {
                    completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to parse response"])))
                }
            }
        }

        task.resume()
    }
}

