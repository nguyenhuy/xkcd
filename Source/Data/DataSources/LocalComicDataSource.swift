//
//  LocalComicDataSource.swift
//  xkcd
//
//  Created by Thanh Huy Nguyen on 5/16/22.
//

import Foundation
import Combine

struct LocalFetchBookmark : FetchBookmark {
    let rawValue: Int
    
    func nextFetchBookmark(currentBatchCount: Int, totalCount: Int) -> FetchBookmark? {
        let nextRawValue = self.rawValue + currentBatchCount
        guard nextRawValue < totalCount else {
            // We've ran out of comics
            return nil
        }
        
        return LocalFetchBookmark(rawValue: nextRawValue)
    }
    
    func validBatchSize(totalCount: Int, requestedBatchSize: Int) -> Int {
        return max(0, min(totalCount - rawValue, requestedBatchSize))
    }
}

class LocalComicDataSource: MutableComicDataSource {
    var comics = [Comic]()
    
    func prewarm() {
    }
    
    func firstComics(size: Int) -> AnyPublisher<BatchFetchResult, Error> {
        let firstBatchBookmark = LocalFetchBookmark(rawValue: 0)
        return comics(withParams: BatchFetchParams(bookmark: firstBatchBookmark,
                                                   batchSize: size))
    }
    
    func comics(withParams params: BatchFetchParams) -> AnyPublisher<BatchFetchResult, Error> {
        guard let bookmark = params.bookmark as? LocalFetchBookmark else {
            return Fail(error: CancellationError()).eraseToAnyPublisher()
        }
        
        let validBatchSize = bookmark.validBatchSize(totalCount: comics.count,
                                                     requestedBatchSize: params.batchSize)
        guard validBatchSize > 0 else {
            return Fail(error: CancellationError()).eraseToAnyPublisher()
        }
        
        let startingIdx = bookmark.rawValue
        let resultingComics = Array(comics[startingIdx..<startingIdx + validBatchSize])
        let nextBookmark = bookmark.nextFetchBookmark(currentBatchCount: validBatchSize,
                                                      totalCount: comics.count)
        let result = BatchFetchResult(comics: resultingComics,
                                      nextFetchBookmark: nextBookmark)
        return Result.success(result).publisher.eraseToAnyPublisher()
    }
    
    func contains(comicWithId id: Int) -> AnyPublisher<Bool, Never> {
        let contains = comics.contains { comic in
            comic.id == id
        }
        return Result.success(contains).publisher.eraseToAnyPublisher()
    }
    
    func append(comics: [Comic]) -> AnyPublisher<Bool, Error> {
        self.comics.append(contentsOf: comics)
        return Result.success(true).publisher.eraseToAnyPublisher()
    }
    
    func refresh() {
    }
    
}
