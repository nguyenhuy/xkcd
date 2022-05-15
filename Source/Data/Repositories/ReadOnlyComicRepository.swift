//
//  ReadOnlyComicRepository.swift
//  xkcd
//
//  Created by Thanh Huy Nguyen on 5/10/22.
//

import Foundation
import Combine

class ReadOnlyComicRepository : ComicRepository {
    @Published var comics = [Comic]()
    var comicsPublisher: Published<[Comic]>.Publisher { $comics }
    
    @Published var errors = [Error]()
    var errorsPublisher: Published<[Error]>.Publisher { $errors }
    
    let dataSource: ComicDataSource
    let firstBatchSize: Int
    let normalBatchSize: Int
    
    var currentFetch: AnyCancellable?
    var nextFetchBookmark: FetchBookmark?
    
    convenience init() {
        self.init(dataSource: RemoteComicDataSource(),
                  firstBatchSize: 5,
                  normalBatchSize: 10)
    }
    
    init(dataSource: ComicDataSource,
         firstBatchSize: Int,
         normalBatchSize: Int) {
        self.dataSource = dataSource
        self.firstBatchSize = firstBatchSize
        self.normalBatchSize = normalBatchSize
    }
    
    func prewarm() {
        self.fetchFirstBatch(forced: true)
    }
    
    func fetchNextBatch() {
        self.fetchBatch(withSize: self.normalBatchSize)
    }
    
    private func fetchFirstBatch(forced: Bool = false) {
        if (self.isFetching() && !forced) {
            return
        }
        
        guard self.didFetchFirstBatch() == false else {
            // Make sure to not fetch first batch repeatedly
            return
        }
        
        self.currentFetch = self.dataSource.latestComic()
            .receive(on: RunLoop.main)
            .sink(receiveCompletion: { [weak self] completion in
                guard let self = self else { return }
                
                self.currentFetch = nil
                
                switch completion {
                case .finished:
                    self.fetchBatch(withSize: self.firstBatchSize - 1,
                                     forced: forced)
                    break
                case .failure(let error):
                    self.errors.append(error)
                }
            }, receiveValue: { [weak self] result in
                guard let self = self else { return }
                
                self.comics.append(result.comic)
                self.nextFetchBookmark = result.nextFetchBookmark
            })
    }
    
    private func fetchBatch(withSize size: Int, forced: Bool = false) {
        if (self.isFetching() && !forced) {
            // There is an inflight fetch, wait for it
            return
        }
        
        guard self.didReachEnd() == false else {
            // Data source ran out of comics
            return
        }
        
        guard self.didFetchFirstBatch() else {
            // Make sure to fetch first batch first
            self.fetchFirstBatch()
            return
        }
        
        guard let nextBookmark = self.nextFetchBookmark else {
            // Bookmark must be available at this point. Throw an internal error otherwise
            self.errors.append(URLError(.resourceUnavailable))
            return
        }
        
        let params = BatchFetchParams(bookmark: nextBookmark,
                                      batchSize: size)
        
        self.currentFetch = self.dataSource.comics(withParams: params)
            .receive(on: RunLoop.main)
            .sink(receiveCompletion: { [weak self] completion in
                guard let self = self else { return }
                
                self.currentFetch = nil
                
                switch completion {
                case .finished:
                    break
                case .failure(let error):
                    self.errors.append(error)
                }
            }, receiveValue: { [weak self] result in
                guard let self = self else { return }
                
                self.comics.append(contentsOf: result.comics)
                self.nextFetchBookmark = result.nextFetchBookmark
            })
    }
    
    private func isFetching() -> Bool {
        return self.currentFetch != nil
    }
    
    private func didFetchFirstBatch() -> Bool {
        return self.nextFetchBookmark != nil && self.comics.count > 0
    }
    
    private func didReachEnd() -> Bool {
        return self.nextFetchBookmark == nil && self.comics.count > 0
    }
    
    func purge() {
        self.currentFetch = nil
        self.nextFetchBookmark = nil
        self.comics.removeAll()
        self.errors.removeAll()
    }
}
