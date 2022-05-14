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
        
        var expectedResult: SingleFetchResult?
        
        let expectation = self.expectation(description: "Awaiting result")
        let cancellable = dataSource.latestComic().sink { _ in
            expectation.fulfill()
        } receiveValue: { result in
            expectedResult = result
        }

        
        waitForExpectations(timeout: 1)
        cancellable.cancel()
        
        let unwrappedResult = try XCTUnwrap(expectedResult)
        XCTAssertEqual(unwrappedResult.comic.id, expectedComicId)
    }
    
    
}
