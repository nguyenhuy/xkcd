//
//  ComicRepository.swift
//  xkcd
//
//  Created by Thanh Huy Nguyen on 5/10/22.
//

import Foundation
import Combine

/// A repository for comics. Comics can be from multiple sources (remote, local caches, etc).
protocol ComicRepository {
    
    /// A publisher that delivers the comics that this repository provides.
    var comicsPublisher: Published<[Comic]>.Publisher { get }
    
    /// A publisher that delivers errors that this repository encouters.
    var errorsPublisher: Published<[Error]>.Publisher { get }
    
    /// Tells the repository to prime itself because it'll be asked for some comics very shortly.
    /// For examples, it can tell its data source(s) to warm up HTTP connection(s) to backend API or local file/DB.
    func prewarm()
    
    /// Asks the repository to fetch the next batch of comics
    /// Calling this method when the repository is empty will cause it to fetch the first batch.
    /// Calling this method while a batch if fetch is already inflight will do nothing.
    func fetchNextBatch()
    
    /// Whether this repository has more comics to fetch
    /// - Returns: true if has more, false otherwise
    func hasMore() -> Bool
    
    /// Tells the repository to purge its data.
    /// The next fetchNextBatch() will fetch the first page.
    func purge()
}
