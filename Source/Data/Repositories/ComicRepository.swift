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
    
    /// A publisher that delivers whether this repository has and can fetch more comics.
    var hasMorePublisher: Published<Bool>.Publisher { get }
    
    /// Tells the repository to prime itself because it'll be asked for some comics very shortly.
    /// For examples, it can tell its data source(s) to warm up HTTP connection(s) to backend API or local file/DB.
    func prewarm()
    
    /// Asks the repository to fetch the next batch of comics
    /// Calling this method when the repository is empty will cause it to fetch the first batch.
    /// Calling this method while a batch if fetch is already inflight will do nothing.
    func fetchNextBatch()
    
    /// Provides a publisher that can answer whether a comic is bookmarked
    /// - Parameter comicId: id of the comic to check
    /// - Returns: A publisher that delivers the answer
    func isComicBookmarked(comicId id: Int) -> AnyPublisher<Bool, Never>
    
    /// Bookmarks a comic
    /// - Parameter comic: The comic to bookmark
    /// - Returns: A publisher that delivers the result of this operation
    func bookmark(comic: Comic) -> AnyPublisher<Bool, Error>
    
    /// Tells the repository to refresh its data.
    func refresh()
    
    
}
