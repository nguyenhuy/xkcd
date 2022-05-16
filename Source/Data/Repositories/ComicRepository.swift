//
//  ComicRepository.swift
//  xkcd
//
//  Created by Thanh Huy Nguyen on 5/10/22.
//

import Foundation
import Combine

/// A repository for comics. Comics can be from multiple sources (remote, local caches, etc).
protocol ComicRepository: ObservableObject {
    
    /// The comics that this repository provides.
    var comics: [Comic] { get set }
    
    /// The errors that this repository encouters.
    var errors: [Error] { get set }
    
    /// Tells the repository to prime itself because it'll be asked for some comics very shortly.
    /// For examples, it can warming a HTTP connection to backend API, or open a file/DB connection.
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
