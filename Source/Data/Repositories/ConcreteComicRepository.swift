//
//  ReadOnlyComicRepository.swift
//  xkcd
//
//  Created by Thanh Huy Nguyen on 5/10/22.
//

import Foundation
import Combine

class ConcreteComicRepository : ComicRepository {
    @Published var comics = [Comic]()
    var comicsPublisher: Published<[Comic]>.Publisher { $comics }
    
    @Published var errors = [Error]()
    var errorsPublisher: Published<[Error]>.Publisher { $errors }
    
    @Published var hasMore = false
    var hasMorePublisher: Published<Bool>.Publisher { $hasMore }
    
    let comicDataSource: ImmutableComicDataSource
    let bookmarkedComicDataSource: MutableComicDataSource
    let firstBatchSize: Int
    let normalBatchSize: Int
    
    var currentFetch: AnyCancellable?
    var nextFetchBookmark: FetchBookmark?
    var didFetchFirstBatch: Bool
    
    
    convenience init() {
        self.init(comicDataSource: RemoteComicDataSource(),
                  bookmarkedComicDataSource: LocalComicDataSource(),
                  firstBatchSize: 5,
                  normalBatchSize: 10)
    }
    
    init(comicDataSource: ImmutableComicDataSource,
         bookmarkedComicDataSource: MutableComicDataSource,
         firstBatchSize: Int,
         normalBatchSize: Int) {
        self.comicDataSource = comicDataSource
        self.bookmarkedComicDataSource = bookmarkedComicDataSource
        self.firstBatchSize = firstBatchSize
        self.normalBatchSize = normalBatchSize
        didFetchFirstBatch = false
    }
    
    func prewarm() {
        comicDataSource.prewarm()
        bookmarkedComicDataSource.prewarm()
        fetchFirstBatch(forced: true)
    }
    
    private func fetchFirstBatch(forced: Bool = false) {
        if (self.isFetching() && !forced) {
            return
        }
        
        guard !didFetchFirstBatch else {
            // Make sure to not fetch first batch repeatedly
            return
        }
        
        consume(publisher: comicDataSource.firstComics(size: firstBatchSize))
    }
    
    func fetchNextBatch() {
        if (self.isFetching()) {
            // There is an inflight fetch, wait for it
            return
        }
        
        guard hasMore else {
            // Data source ran out of comics
            return
        }
        
        guard didFetchFirstBatch else {
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
                                      batchSize: normalBatchSize)
        
        consume(publisher: comicDataSource.comics(withParams: params))
    }
    
    private func consume(publisher: AnyPublisher<BatchFetchResult, Error>) {
        self.currentFetch = publisher
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
                self.didFetchFirstBatch = true
                self.hasMore = self.nextFetchBookmark != nil
            })
    }
    
    private func isFetching() -> Bool {
        return self.currentFetch != nil
    }
    
    func isComicBookmarked(comicId id: Int) -> AnyPublisher<Bool, Never> {
        return bookmarkedComicDataSource.contains(comicWithId: id)
    }
    
    func bookmark(comic: Comic) -> AnyPublisher<Bool, Error> {
        return bookmarkedComicDataSource.append(comics: [comic])
    }
    
    func refresh() {
        currentFetch = nil
        nextFetchBookmark = nil
        didFetchFirstBatch = false
        hasMore = false
        
        comics.removeAll()
        errors.removeAll()
        
        comicDataSource.refresh()
        bookmarkedComicDataSource.refresh()
        
        fetchFirstBatch(forced: true)
    }
}
