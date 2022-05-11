//
//  ComicsDataSource.swift
//  xkcd
//
//  Created by Thanh Huy Nguyen on 5/10/22.
//

import Foundation
import Combine

/// Params for fetching next comics
struct BatchFetchParams {
    
    /// The bookmark for this page
    let bookmark: Int
    
    /// How many comics to fetch?
    let batchSize: Int
}

/// The result of a comic fetch
protocol FetchResult {
    
    /// The bookmark to be used to fetch the next result(s)
    var nextFetchBookmark: Int { get }
}

/// The result of a batch fetch
struct BatchFetchResult: FetchResult {
    /// The comics
    let comics: [Comic]
    
    /// Params used for this fetch
    let params: BatchFetchParams
    
    /// The bookmark to be used to fetch the next batch
    let nextFetchBookmark: Int
}

/// The result of a single comic fetch
struct SingleFetchResult: FetchResult {
    
    /// The comic
    let comic: Comic
    
    /// The bookmark to be used to fetch the next comic(s)
    let nextFetchBookmark: Int
}

/// A data source for comics, can be remote or local
protocol ComicsDataSource {
    
    /// - Returns: A publisher that delivers the most recent comic
    func latestComicPublisher() -> AnyPublisher<SingleFetchResult, Error>
    
    /// - Returns: A publisher that delivers the comic with that id
    /// - Parameter id: The comic id
    func comicPublisher(forComicWithId id: Int) -> AnyPublisher<SingleFetchResult, Error>
    
    /// Provides a publisher that can fetch multiple comics at onces
    /// - Returns: A publisher that delivers a batch of comics, as well as the starting key for the next batch.
    /// - Parameter params: Parameters for the fetch.
    func comicsPublisher(withParams params: BatchFetchParams) -> AnyPublisher<BatchFetchResult, Error>
}