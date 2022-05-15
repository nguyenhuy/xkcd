//
//  RemoteComicDataSourceTests.swift
//  xkcdTests
//
//  Created by Thanh Huy Nguyen on 5/14/22.
//

import XCTest
@testable import xkcd
import Combine

let ComicJSONFixture = "{\"month\": \"5\", \"num\": ID_TO_BE_REPLACED, \"link\": \"\", \"year\": \"2022\", \"news\": \"\", \"safe_title\": \"Maps\", \"transcript\": \"\", \"alt\": \"OpenStreetMap was always pretty good but is also now *really* good? And Apple Maps's new zoomed-in design in certain cities like NYC and London is just gorgeous. It's cool how there are all these good maps now!\", \"img\": \"https://imgs.xkcd.com/comics/maps.png\", \"title\": \"Maps\", \"day\": \"9\"}"

class NetworkClientMock: NetworkClient {
    var requestedUrls = [URL]()
    var returnedPublishers = [URL : AnyPublisher<URLSession.DataTaskPublisher.Output, URLError>]()
    
    func dataTaskPublisher(for url: URL) -> AnyPublisher<URLSession.DataTaskPublisher.Output, URLError> {
        requestedUrls.append(url)
        guard let publisher = returnedPublishers[url] else {
            fatalError("Unexpected URL")
        }
        return publisher
    }
    
    func mockPublisher(for comicWithId: Int) -> AnyPublisher<URLSession.DataTaskPublisher.Output, URLError> {
        let JSONString = ComicJSONFixture.replacingOccurrences(of: "ID_TO_BE_REPLACED", with: String(comicWithId))
        let data = Data(JSONString.utf8)
        let response = URLResponse()
        return Result.success((data: data, response: response)).publisher.eraseToAnyPublisher()
    }
}

class RemoteComicDataSourceTests: XCTestCase {
    let apiHost = "http://test.com"
    let infoPath = "/info.json"
    let decoder = JSONDecoder()
    var networkClient: NetworkClientMock!
    var dataSource: RemoteComicDataSource!
    
    override func setUpWithError() throws {
        networkClient = NetworkClientMock()
        dataSource = RemoteComicDataSource(networkClient: networkClient, decoder: decoder, apiHost: apiHost, infoPath: infoPath)
    }
    
    func testFetchLatestComit() throws {
        let expectedComicId = 1234
        let url = URL(string: apiHost + infoPath)!
        let publisher = networkClient.mockPublisher(for: expectedComicId)
        networkClient.returnedPublishers[url] = publisher
        
        let result = try waitForPublisher(publisher: dataSource.latestComic())

        XCTAssertEqual(result.comic.id, expectedComicId)
    }
    
    func testFetchedComicsAreSorted() throws {
        let startingId = 1000
        let batchSize = 10
        for i in 0..<batchSize {
            let id = startingId - i
            let url = URL(string: apiHost + "/\(id)" + infoPath)!
            let publisher = networkClient.mockPublisher(for: id)
            networkClient.returnedPublishers[url] = publisher
        }
        
        let params = BatchFetchParams(bookmark: xkcdFetchBookmark(rawValue: startingId),
                                      batchSize: batchSize)
        let result = try waitForPublisher(publisher: dataSource.comics(withParams: params))
        let returnedIds = result.comics.map() { $0.id }
        
        XCTAssertEqual(returnedIds.count, batchSize)
        XCTAssertEqual(returnedIds.first, startingId)
        // Test that the returned comics are sorted
        for i in 1..<batchSize {
            XCTAssert(returnedIds[i - 1] > returnedIds[i])
        }
    }
    
    func testFetchFewerComicsThanAvailable() throws {
        let startingId = 20
        let batchSize = 10
        for i in 0..<batchSize {
            let id = startingId - i
            let url = URL(string: apiHost + "/\(id)" + infoPath)!
            let publisher = networkClient.mockPublisher(for: id)
            networkClient.returnedPublishers[url] = publisher
        }
        
        let params = BatchFetchParams(bookmark: xkcdFetchBookmark(rawValue: startingId),
                                      batchSize: batchSize)
        let result = try waitForPublisher(publisher: dataSource.comics(withParams: params))
        let returnedIds = result.comics.map() { $0.id }
        
        XCTAssertEqual(returnedIds.count, batchSize)
        XCTAssertNotNil(result.nextFetchBookmark)
    }
    
    func testFetchAllRemainingComics() throws {
        let startingId = 5
        let batchSize = 5
        for i in 0..<batchSize {
            let id = startingId - i
            let url = URL(string: apiHost + "/\(id)" + infoPath)!
            let publisher = networkClient.mockPublisher(for: id)
            networkClient.returnedPublishers[url] = publisher
        }
        
        let params = BatchFetchParams(bookmark: xkcdFetchBookmark(rawValue: startingId),
                                      batchSize: batchSize)
        let result = try waitForPublisher(publisher: dataSource.comics(withParams: params))
        let returnedIds = result.comics.map() { $0.id }
        
        XCTAssertEqual(returnedIds.count, batchSize)
        XCTAssertNil(result.nextFetchBookmark)
    }
    
    func testFetchMoreComicsThanAvailable() throws {
        let startingId = 5
        let givenBatchSize = 10
        let expectedBatchSize = 5
        for i in 0..<expectedBatchSize {
            let id = startingId - i
            let url = URL(string: apiHost + "/\(id)" + infoPath)!
            let publisher = networkClient.mockPublisher(for: id)
            networkClient.returnedPublishers[url] = publisher
        }
        
        let params = BatchFetchParams(bookmark: xkcdFetchBookmark(rawValue: startingId),
                                      batchSize: givenBatchSize)
        let result = try waitForPublisher(publisher: dataSource.comics(withParams: params))
        let returnedIds = result.comics.map() { $0.id }
        
        XCTAssertEqual(returnedIds.count, expectedBatchSize)
        XCTAssertNil(result.nextFetchBookmark)
    }
    
    func testFetchMultipleBatchesWithFilledLastBatch() throws {
        let expectedNumberOfComics = 20
        let startingId = expectedNumberOfComics
        let batchSize = 10
        let numberOfBatches = Int(ceil(Double(startingId) / Double(batchSize)))
        for i in 0..<startingId {
            let id = startingId - i
            let url = URL(string: apiHost + "/\(id)" + infoPath)!
            let publisher = networkClient.mockPublisher(for: id)
            networkClient.returnedPublishers[url] = publisher
        }
        
        var comics = [Comic]()
        var bookmark: FetchBookmark? = xkcdFetchBookmark(rawValue: startingId)
        for _ in 0..<numberOfBatches {
            if let currentBookmark = bookmark {
                let params = BatchFetchParams(bookmark: currentBookmark, batchSize: batchSize)
                let result = try waitForPublisher(publisher: dataSource.comics(withParams: params))
                comics.append(contentsOf: result.comics)
                bookmark = result.nextFetchBookmark
            }
        }

        XCTAssertEqual(comics.count, expectedNumberOfComics)
        // Test that the returned comics are sorted
        for i in 1..<expectedNumberOfComics {
            XCTAssert(comics[i - 1].id > comics[i].id)
        }
        XCTAssertNil(bookmark)
    }
    
    func testFetchMultipleBatchesWithHalfFilledLastBatch() throws {
        let expectedNumberOfComics = 23
        let startingId = expectedNumberOfComics
        let batchSize = 10
        let numberOfBatches = Int(ceil(Double(startingId) / Double(batchSize)))
        for i in 0..<startingId {
            let id = startingId - i
            let url = URL(string: apiHost + "/\(id)" + infoPath)!
            let publisher = networkClient.mockPublisher(for: id)
            networkClient.returnedPublishers[url] = publisher
        }
        
        var comics = [Comic]()
        var bookmark: FetchBookmark? = xkcdFetchBookmark(rawValue: startingId)
        for _ in 0..<numberOfBatches {
            if let currentBookmark = bookmark {
                let params = BatchFetchParams(bookmark: currentBookmark, batchSize: batchSize)
                let result = try waitForPublisher(publisher: dataSource.comics(withParams: params))
                comics.append(contentsOf: result.comics)
                bookmark = result.nextFetchBookmark
            }
        }

        XCTAssertEqual(comics.count, expectedNumberOfComics)
        // Test that the returned comics are sorted
        for i in 1..<expectedNumberOfComics {
            XCTAssert(comics[i - 1].id > comics[i].id)
        }
        XCTAssertNil(bookmark)
    }
    
    private func waitForPublisher<T: Publisher>(publisher: T) throws -> T.Output {
        var expectedResult: T.Output?
        let expectation = self.expectation(description: "Awaiting result")
        
        let cancellable = publisher.sink { _ in
            expectation.fulfill()
        } receiveValue: { result in
            expectedResult = result
        }

        waitForExpectations(timeout: 1)
        cancellable.cancel()
        
        return try XCTUnwrap(expectedResult)
    }
}
