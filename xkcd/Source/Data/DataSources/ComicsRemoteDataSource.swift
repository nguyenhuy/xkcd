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
    
    func latestComicPublisher() -> AnyPublisher<Comic, Error> {
        guard let url = URL(string: apiHost + infoPath) else {
            fatalError("Failed to construct URL")
        }
        return urlSession.dataTaskPublisher(for: url)
            .map{ $0.data }
            .decode(type: Comic.self, decoder: decoder)
            .receive(on: RunLoop.main)
            .eraseToAnyPublisher()
    }
    
    func comicPublisher(forComicWithId id: Int) -> AnyPublisher<Comic, Error> {
        guard let url = URL(string: apiHost + "/\(id)" + infoPath) else {
            fatalError("Failed to construct URL")
        }
        return urlSession.dataTaskPublisher(for: url)
            .map{ $0.data }
            .decode(type: Comic.self, decoder: decoder)
            .receive(on: RunLoop.main)
            .eraseToAnyPublisher()
    }
    
    func comicsPublisher(withParams params: BatchFetchParams) -> AnyPublisher<BatchFetchResult, Error> {
        let startingKey = params.startingKey
        var batchSize = params.batchSize
        if (batchSize > startingKey + 1) {
            batchSize = startingKey + 1
        }
        
        guard batchSize > 1 else {
            return self.comicPublisher(forComicWithId: params.startingKey)
                .map({ comic in
                    BatchFetchResult(comics: [comic],
                                     params: params,
                                     nextBatchStartingKey: self.nextBatchStartingKey(withLastComicId: comic.id))
                })
                .eraseToAnyPublisher()
        }
        
        var publishers = [AnyPublisher<Comic, Error>]()
        for i in 0..<batchSize {
            let comicId = startingKey - i
            publishers.append(self.comicPublisher(forComicWithId: comicId))
        }
        
        return Publishers.MergeMany(publishers)
            .collect()
            .map({ comics in
                let sortedComics = comics.sorted { a, b in
                    a.id > b.id
                }
                
                guard let last = sortedComics.last else {
                    fatalError("Failed to fetch comics: no comic to merge")
                }
                
                return BatchFetchResult(comics: sortedComics,
                                        params: params,
                                        nextBatchStartingKey: self.nextBatchStartingKey(withLastComicId: last.id))
            })
            .eraseToAnyPublisher()
    }
    
    func nextBatchStartingKey(withLastComicId lastId: Int) -> Int {
        return min(lastId - 1, 0)
    }

}
