//
//  URLSessionNetworkClient.swift
//  xkcd
//
//  Created by Thanh Huy Nguyen on 5/14/22.
//

import Foundation
import Combine

/// A network client that is backed by URLSession
class URLSessionNetworkClient: NetworkClient {
    let urlSession: URLSession
    
    convenience init() {
        self.init(urlSession: URLSession.shared)
    }
    
    init(urlSession: URLSession) {
        self.urlSession = urlSession
    }
    
    func dataTaskPublisher(for url: URL) -> AnyPublisher<URLSession.DataTaskPublisher.Output, URLError> {
        return self.urlSession.dataTaskPublisher(for: url).eraseToAnyPublisher()
    }
    
}
