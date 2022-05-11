//
//  ComicsRemoteDataSource.swift
//  xkcd
//
//  Created by Thanh Huy Nguyen on 5/10/22.
//

import Foundation
import Combine

class ComicsRemoteDataSource : ComicsDataSource {
    var urlSession: URLSession
    let decoder: JSONDecoder
    let apiHost: String
    let infoPath: String
    
    init(withUrlSession urlSession: URLSession, decoder: JSONDecoder, apiHost: String, infoPath: String) {
        self.urlSession = urlSession
        self.decoder = decoder
        self.apiHost = apiHost
        self.infoPath = infoPath
    }
    
    convenience init() {
        self.init(withUrlSession: URLSession.shared, decoder: JSONDecoder(), apiHost: "https://xkcd.com", infoPath: "/info.0.json")
    }
    
    func latestComicPublisher() -> AnyPublisher<SingleFetchResult, Error> {
        guard let url = URL(string: apiHost + infoPath) else {
            fatalError("Failed to construct URL")
        }
        return urlSession.dataTaskPublisher(for: url)
            .map{ $0.data }
            .decode(type: Comic.self, decoder: decoder)
            .map({ comic in
                SingleFetchResult(comic: comic, nextFetchBookmark: ComicsRemoteDataSource.nextFetchBookmark(after: comic.id))
            })
            .receive(on: RunLoop.main)
            .eraseToAnyPublisher()
    }
    
    func comicPublisher(forComicWithId id: Int) -> AnyPublisher<SingleFetchResult, Error> {
        guard let url = URL(string: apiHost + "/\(id)" + infoPath) else {
            fatalError("Failed to construct URL")
        }
        return urlSession.dataTaskPublisher(for: url)
            .map{ $0.data }
            .decode(type: Comic.self, decoder: decoder)
            .map({ comic in
                SingleFetchResult(comic: comic, nextFetchBookmark: ComicsRemoteDataSource.nextFetchBookmark(after: comic.id))
            })
            .receive(on: RunLoop.main)
            .eraseToAnyPublisher()
    }
    
    func comicsPublisher(withParams params: BatchFetchParams) -> AnyPublisher<BatchFetchResult, Error> {
        let startingId = params.bookmark
        var batchSize = params.batchSize
        if (batchSize > startingId + 1) {
            batchSize = startingId + 1
        }
        
        guard batchSize > 1 else {
            return self.comicPublisher(forComicWithId: startingId)
                .map({ result in
                    BatchFetchResult(comics: [result.comic],
                                     params: params,
                                     nextFetchBookmark: result.nextFetchBookmark)
                })
                .eraseToAnyPublisher()
        }
        
        var publishers = [AnyPublisher<SingleFetchResult, Error>]()
        for i in 0..<batchSize {
            let comicId = startingId - i
            publishers.append(self.comicPublisher(forComicWithId: comicId))
        }
        
        return Publishers.MergeMany(publishers)
            .collect()
            .map({ results in
                let sortedResults = results.sorted { a, b in
                    a.comic.id > b.comic.id
                }
                
                guard let last = sortedResults.last else {
                    fatalError("Failed to fetch comics: no comic to merge")
                }
                
                return BatchFetchResult(comics: sortedResults.map { $0.comic },
                                        params: params,
                                        nextFetchBookmark: last.nextFetchBookmark)
            })
            .eraseToAnyPublisher()
    }
    
    static func nextFetchBookmark(after comicId: Int) -> Int {
        return min(comicId - 1, 0)
    }

}
