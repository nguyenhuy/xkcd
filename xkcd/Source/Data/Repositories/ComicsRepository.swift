//
//  ComicsRepository.swift
//  xkcd
//
//  Created by Thanh Huy Nguyen on 5/10/22.
//

import Foundation
import Combine

/// A repository for comics. Comics can be from multiple sources (remote, local caches, etc).
protocol ComicsRepository {
    
    /// A publisher that delivers the comics that this repository provides.
    var comicsPublisher: Published<[Comic]>.Publisher { get }
    
    /// A publisher that delivers errors that this repository encouters.
    var errorsPublisher: Published<[Error]>.Publisher { get }
    
    /// Tells the repository to prime itself because it'll be asked for some comics very shortly.
    /// For examples, it can warming a HTTP connection to backend API, or open a file/DB connection.
    func prewarm()
    
    /// Asks the repository to fetch the next batch of comics
    /// Calling this when the repository is empty will cause it to fetch the first batch.
    func fetchNextBatch()
    
    /// Tells the repository to purge its data.
    /// The next fetchNextBatch() will fetch the first page.
    func purge()
}
