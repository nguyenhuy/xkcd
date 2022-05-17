//
//  RemoteComicDataSource.swift
//  xkcd
//
//  Created by Thanh Huy Nguyen on 5/10/22.
//

import Foundation
import Combine

struct xkcdFetchBookmark : FetchBookmark {
    static let MIN = 1

    let rawValue: Int
    
    func nextFetchBookmark(currentBatchCount: Int) -> FetchBookmark? {
        let nextRawValue = self.rawValue - currentBatchCount
        guard nextRawValue >= xkcdFetchBookmark.MIN else {
            // We've ran out of comics
            return nil
        }
        
        return xkcdFetchBookmark(rawValue: nextRawValue)
    }
    
    func validBatchSize(requestedBatchSize: Int) -> Int {
        return max(0, min(self.rawValue - xkcdFetchBookmark.MIN + 1, requestedBatchSize))
    }
}

/// The result of a single comic fetch
struct SingleFetchResult {
    
    /// The comic
    let comic: Comic
    
    /// The bookmark to be used to fetch the next comic(s)
    /// No next batch available if nil
    let nextFetchBookmark: FetchBookmark?
}

class RemoteComicDataSource : ImmutableComicDataSource {
    let networkClient: NetworkClient
    let decoder: JSONDecoder
    let apiHost: String
    let infoPath: String
    
    init(networkClient: NetworkClient, decoder: JSONDecoder, apiHost: String, infoPath: String) {
        self.networkClient = networkClient
        self.decoder = decoder
        self.apiHost = apiHost
        self.infoPath = infoPath
    }
    
    convenience init() {
        self.init(networkClient: URLSessionNetworkClient(),
                  decoder: JSONDecoder(),
                  apiHost: "https://xkcd.com",
                  infoPath: "/info.0.json")
    }
    
    func prewarm() {
        // TODO: Maybe ask the network client to make a dummy request to warm up its connection?
    }
    
    func firstComics(size: Int) -> AnyPublisher<BatchFetchResult, Error> {
        guard size > 0 else {
            return Fail(error: CancellationError()).eraseToAnyPublisher()
        }
        
        guard size > 1 else {
            return latestComic()
                .map({ result in
                    BatchFetchResult(comics: [result.comic],
                                     nextFetchBookmark: result.nextFetchBookmark)
                })
                .eraseToAnyPublisher()
        }
        
        // First, fetch the latest comic
        return latestComic()
            .map { [weak self] result -> AnyPublisher<BatchFetchResult, Error> in
                // Got the latest comic, turn it into a "batch" to "zip" later on
                let firstBatch = BatchFetchResult(comics: [result.comic], nextFetchBookmark: nil)
                let firstBatchPublisher = Result<BatchFetchResult, Error>.success(firstBatch)
                    .publisher
                    .eraseToAnyPublisher()
                guard let self = self, let bookmark = result.nextFetchBookmark else {
                    return firstBatchPublisher
                }
                
                // Fetch remaining ones
                let nextBatchPublisher = self.comics(withParams: BatchFetchParams(bookmark: bookmark,
                                                                                  batchSize: size - 1))
                
                // Zip the results
                return Publishers.Zip(firstBatchPublisher, nextBatchPublisher)
                    .map { (first, next) in
                        BatchFetchResult(comics: first.comics + next.comics,
                                         nextFetchBookmark: next.nextFetchBookmark)
                    }
                    .eraseToAnyPublisher()
            }
            .switchToLatest()
            .eraseToAnyPublisher()
    }
    
    func comics(withParams params: BatchFetchParams) -> AnyPublisher<BatchFetchResult, Error> {
        guard let bookmark = params.bookmark as? xkcdFetchBookmark else {
            return Fail(error: CancellationError()).eraseToAnyPublisher()
        }
        
        let startingId = bookmark.rawValue
        let batchSize = bookmark.validBatchSize(requestedBatchSize: params.batchSize)
        
        guard batchSize > 0 else {
            return Fail(error: CancellationError()).eraseToAnyPublisher()
        }
        
        guard batchSize > 1 else {
            return self.comic(withId: startingId)
                .map({ result in
                    BatchFetchResult(comics: [result.comic],
                                     nextFetchBookmark: result.nextFetchBookmark)
                })
                .eraseToAnyPublisher()
        }
        
        var publishers = [AnyPublisher<SingleFetchResult, Error>]()
        for i in 0..<batchSize {
            let comicId = startingId - i
            publishers.append(self.comic(withId: comicId))
        }
        
        return Publishers.MergeMany(publishers)
            .collect()
            .tryMap({ results in
                guard results.count == batchSize else {
                    // Get fewer comics than requested
                    // Can't return any of them because they may not be continuous
                    throw URLError(.badServerResponse)
                }
                
                // results aren't in any particular order so we need to sort it
                let comics = results
                    .map { $0.comic }
                    .sorted { $0.id > $1.id }
                let nextBookmark = bookmark.nextFetchBookmark(currentBatchCount: results.count)
                return BatchFetchResult(comics: comics,
                                        nextFetchBookmark: nextBookmark)
            })
            .eraseToAnyPublisher()
    }
    
    func contains(comicWithId id: Int) -> AnyPublisher<Bool, Never> {
        return comic(withId: id).map { _ in true}.replaceError(with: false).eraseToAnyPublisher()
    }
    
    func refresh() {
        // This data source is stateless so there is nothing to refresh
    }
    
    private func latestComic() -> AnyPublisher<SingleFetchResult, Error> {
        guard let url = URL(string: apiHost + infoPath) else {
            return Fail(error: URLError(.badServerResponse)).eraseToAnyPublisher()
        }
        return self.comic(forUrl: url)
    }
    
    private func comic(withId id: Int) -> AnyPublisher<SingleFetchResult, Error> {
        guard let url = URL(string: apiHost + "/\(id)" + infoPath) else {
            return Fail(error: URLError(.badServerResponse)).eraseToAnyPublisher()
        }
        return self.comic(forUrl: url)
    }
    
    private func comic(forUrl url: URL) -> AnyPublisher<SingleFetchResult, Error> {
        return networkClient.dataTaskPublisher(for: url)
            .map{ $0.data }
            .decode(type: Comic.self, decoder: decoder)
            .map({ comic in
                let currentBookmark = xkcdFetchBookmark(rawValue: comic.id)
                let nextBookmark = currentBookmark.nextFetchBookmark(currentBatchCount: 1)
                return SingleFetchResult(comic: comic, nextFetchBookmark: nextBookmark)
            })
            .eraseToAnyPublisher()
    }
}
