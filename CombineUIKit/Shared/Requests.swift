//
//  Requests.swift
//  CombineUIKit
//
//  Created by Greg Price on 30/03/2021.
//

import Foundation
import Combine

enum API {
    
    static let jsonDecoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return decoder
    }()
    
    static func publisher(for request: URLRequest) -> AnyPublisher<Data, URLError> {
        URLSession.shared
            .dataTaskPublisher(for: request)
            .map(\.data)
            .eraseToAnyPublisher()
    }
}

extension URLComponents {
    
    static func unsplash(path: String, queryItems: [String: String]) -> URLComponents {
        var components = URLComponents()
        components.scheme = "https"
        components.host = "api.unsplash.com"
        components.path = path
        components.queryItems = queryItems.map { URLQueryItem(name: $0.key, value: $0.value) }
        return components
    }
}

extension URLRequest {
    
    static func unsplash(url: URL) -> URLRequest {
        let request = URLRequest(url: URL(string:  "https://api.unsplash.com/search/photos?page=1&per_page=50&query=mac&client_id=cNtxMzMLT8_GFa8TE8ACB5MWVJFOILOE57YRviGQxuI")!)
        return request

    }
    
    static func searchPhotos(query: String, perPage: Int = 80) -> URLRequest {
        
        
        let request = URLRequest(url: URL(string:  "https://api.unsplash.com/search/photos?page=1&per_page=50&query=\(query)&client_id=cNtxMzMLT8_GFa8TE8ACB5MWVJFOILOE57YRviGQxuI")!)
        
        return request

    }
}
