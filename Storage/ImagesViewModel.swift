import Foundation

class ImagesViewModel {
    private let serverURL = "http://164.90.163.215:1337"
    private let token = "11c211d104fe7642083a90da69799cf055f1fe1836a211aca77c72e3e069e7fde735be9547f0917e1a1000efcb504e21f039d7ff55bf1afcb9e2dd56e4d6b5ddec3b199d12a2fac122e43b4dcba3fea66fe428e7c2ee9fc4f1deaa615fa5b6a68e2975cd2f99c65a9eda376e5b6a2a3aee1826ca4ce36d645b4f59f60cf5b74a"
    var imageURLs: [URL] = []
    
    func fetchImageURLs(completion: @escaping (Result<Void, Error>) -> Void) {
        getAllAssets(from: serverURL, token: token) { [weak self] result in
            switch result {
            case .success(let assets):
                self?.imageURLs = assets.compactMap {
                    guard let urlString = $0["url"] as? String else { return nil }
                    return URL(string: self?.serverURL.appending(urlString) ?? "")
                }
                completion(.success(()))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    private func getAllAssets(from url: String, token: String, completion: @escaping (Result<[[String: Any]], Error>) -> Void) {
        guard let assetsURL = URL(string: "\(url)/api/upload/files") else {
            completion(.failure(NSError(domain: "InvalidURLError", code: 0, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])))
            return
        }
        
        var request = URLRequest(url: assetsURL)
        request.httpMethod = "GET"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                completion(.failure(NSError(domain: "ServerError", code: 0, userInfo: [NSLocalizedDescriptionKey: "Unexpected status code"])))
                return
            }
            
            guard let data = data else {
                completion(.failure(NSError(domain: "NoDataError", code: 0, userInfo: [NSLocalizedDescriptionKey: "No data received from server"])))
                return
            }
            
            do {
                if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [[String: Any]] {
                    completion(.success(json))
                } else {
                    completion(.failure(NSError(domain: "ParsingError", code: 0, userInfo: [NSLocalizedDescriptionKey: "Unable to parse server response"])))
                }
            } catch {
                completion(.failure(error))
            }
        }
        task.resume()
    }
    
    func uploadImage(imageData: Data, completion: @escaping (Bool) -> Void) {
        guard let uploadURL = URL(string: "\(serverURL)/api/upload") else {
            completion(false)
            return
        }
        
        var request = URLRequest(url: uploadURL)
        request.httpMethod = "POST"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        let boundary = UUID().uuidString
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        var body = Data()
        
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"files\"; filename=\"testImage.jpg\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: image/jpeg\r\n\r\n".data(using: .utf8)!)
        body.append(imageData)
        body.append("\r\n--\(boundary)--\r\n".data(using: .utf8)!)
        
        let task = URLSession.shared.uploadTask(with: request, from: body) { data, response, error in
            guard error == nil, let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                completion(false)
                return
            }
            completion(true)
        }
        task.resume()
    }
}
