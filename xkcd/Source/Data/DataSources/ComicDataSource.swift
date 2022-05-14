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

/// The result of a single comic fetch
struct SingleFetchResult {
    
    /// The comic
    let comic: Comic
    
    /// The bookmark to be used to fetch the next comic(s)
    /// No next batch available if nil
    let nextFetchBookmark: FetchBookmark?
}

/// A data source for comics, can be remote or local
protocol ComicDataSource {
    
    /// - Returns: A publisher that delivers the most recent comic
    func latestComic() -> AnyPublisher<SingleFetchResult, Error>
    
    /// - Returns: A publisher that delivers the comic with that id
    /// - Parameter id: The comic id
    func comic(withId id: Int) -> AnyPublisher<SingleFetchResult, Error>
    
    /// Provides a publisher that can fetch multiple comics at onces
    /// - Returns: A publisher that delivers a batch of comics, as well as the starting key for the next batch.
    /// - Parameter params: Parameters for the fetch.
    func comics(withParams params: BatchFetchParams) -> AnyPublisher<BatchFetchResult, Error>
}
