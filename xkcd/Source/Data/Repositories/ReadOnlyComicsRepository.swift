//
//  ReadOnlyComicsRepository.swift
//  xkcd
//
//  Created by Thanh Huy Nguyen on 5/10/22.
//

import Foundation
import Combine

class ReadOnlyComicsRepository : ComicsRepository {
    static let FIRST_PAGE_SIZE = 5
    static let NORMAL_PAGE_SIZE = 10
    
    @Published var comics = [Comic]()
    var comicsPublisher: Published<[Comic]>.Publisher { $comics }
    
    @Published var errors = [Error]()
    var errorsPublisher: Published<[Error]>.Publisher { $errors }
    
    let remoteDataSource: ComicsDataSource
    
    var currentFetch: AnyCancellable?
    var nextFetchBookmark: FetchBookmark?
    
    convenience init() {
        self.init(withRemoteDataSource: ComicsRemoteDataSource())
    }
    
    init(withRemoteDataSource remoteDataSource: ComicsDataSource) {
        self.remoteDataSource = remoteDataSource
    }
    
    func prewarm() {
        self.fetchFirstBatch()
    }
    
    func fetchNextBatch() {
        self.fetchBatch(withSize: ReadOnlyComicsRepository.NORMAL_PAGE_SIZE)
    }
    
    private func fetchFirstBatch() {
        if (self.isFetching()) {
            return
        }
        
        guard self.didFetchFirstPage() == false else {
            // Make sure to not fetch first page repeatedly
            return
        }
        
        self.currentFetch = self.remoteDataSource.latestComicPublisher()
            .receive(on: RunLoop.main)
            .sink(receiveCompletion: { [weak self] completion in
                switch completion {
                case .finished:
                    self?.fetchBatch(withSize: ReadOnlyComicsRepository.FIRST_PAGE_SIZE - 1)
                    break
                case .failure(let error):
                    self?.errors.append(error)
                }
                self?.currentFetch = nil
            }, receiveValue: { [weak self] result in
                self?.comics.append(result.comic)
                self?.nextFetchBookmark = result.nextFetchBookmark
        })
    }
    
    private func fetchBatch(withSize size: Int) {
        if (self.isFetching()) {
            return
        }

        guard self.didFetchFirstPage(), let nextBookmark = self.nextFetchBookmark else {
            // Make sure to fetch first page first
            self.fetchFirstBatch()
            return
        }
        
        let params = BatchFetchParams(bookmark: nextBookmark,
                                      batchSize: size)
        
        self.currentFetch = self.remoteDataSource.comicsPublisher(withParams: params)
            .receive(on: RunLoop.main)
            .sink(receiveCompletion: { [weak self] completion in
                switch completion {
                case .finished:
                    break
                case .failure(let error):
                    self?.errors.append(error)
                }
                self?.currentFetch = nil
            }, receiveValue: { [weak self] result in
                self?.comics.append(contentsOf: result.comics)
                self?.nextFetchBookmark = result.nextFetchBookmark
        })
    }
    
    private func isFetching() -> Bool {
        return self.currentFetch != nil
    }
    
    private func didFetchFirstPage() -> Bool {
        return self.nextFetchBookmark != nil && self.comics.count > 0
    }
    
    func purge() {
        self.currentFetch = nil
        self.nextFetchBookmark = nil
        self.comics.removeAll()
        self.errors.removeAll()
    }
}
