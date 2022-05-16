//
//  ComicDataSource.swift
//  xkcd
//
//  Created by Thanh Huy Nguyen on 5/10/22.
//

import Foundation
import Combine

protocol FetchBookmark {}

/// Params for fetching next comics
struct BatchFetchParams {
    
    /// The bookmark for this batch
    let bookmark: FetchBookmark
    
    /// How many comics to fetch?
    let batchSize: Int
}

/// The result of a batch fetch
struct BatchFetchResult {
    
    /// The comics
    let comics: [Comic]
    
    /// The bookmark to be used to fetch the next batch
    /// No next batch available if nil
    let nextFetchBookmark: FetchBookmark?
}

/// A immutable data source for comics, can be remote or local
protocol ImmutableComicDataSource {
    
    /// Provides a publisher that can fetch the first batch of comics
    /// - Parameter size: The size of this first batch
    /// - Returns: A publisher that delivers the first batch, as well as the bookmark for the next one.
    func firstComics(size: Int) -> AnyPublisher<BatchFetchResult, Error>
    
    /// Provides a publisher that can fetch multiple comics at once
    /// - Parameter params: Parameters for the fetch.
    /// - Returns: A publisher that delivers a batch of comics, as well as the bookmark for the next one.
    func comics(withParams params: BatchFetchParams) -> AnyPublisher<BatchFetchResult, Error>
}
