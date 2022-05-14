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
        return min(self.rawValue - xkcdFetchBookmark.MIN + 1, requestedBatchSize)
    }
}

class RemoteComicDataSource : ComicDataSource {
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
        self.init(networkClient: URLSessionNetworkClient(), decoder: JSONDecoder(), apiHost: "https://xkcd.com", infoPath: "/info.0.json")
    }
    
    func latestComic() -> AnyPublisher<SingleFetchResult, Error> {
        guard let url = URL(string: apiHost + infoPath) else {
            return Fail(error: URLError(.badServerResponse)).eraseToAnyPublisher()
        }
        return self.comic(forUrl: url)
    }
    
    func comics(withParams params: BatchFetchParams) -> AnyPublisher<BatchFetchResult, Error> {
        guard let bookmark = params.bookmark as? xkcdFetchBookmark else {
            return Fail(error: CancellationError()).eraseToAnyPublisher()
        }
        
        let startingId = bookmark.rawValue
        let batchSize = bookmark.validBatchSize(requestedBatchSize: params.batchSize)
        
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
                let sortedResults = results.sorted { a, b in
                    a.comic.id > b.comic.id
                }
                
                guard results.count == batchSize, let last = sortedResults.last else {
                    throw URLError(.badServerResponse)
                }
                
                return BatchFetchResult(comics: sortedResults.map { $0.comic },
                                        nextFetchBookmark: last.nextFetchBookmark)
            })
            .eraseToAnyPublisher()
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
