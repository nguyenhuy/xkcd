//
//  NetworkClient.swift
//  xkcd
//
//  Created by Thanh Huy Nguyen on 5/14/22.
//

import Foundation
import Combine

protocol NetworkClient {

    /// Returns a publisher that publishes data when the task completes, or terminates if the task fails with an error.
    /// - Parameter url: The URL from which to get the data
    /// - Returns: URLSession.DataTaskPublisher's output and error types for now. Can have our own types later if need to.
    func dataTaskPublisher(for url: URL) -> AnyPublisher<URLSession.DataTaskPublisher.Output, URLError>
}
