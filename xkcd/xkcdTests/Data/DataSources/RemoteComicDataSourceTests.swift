//
//  RemoteComicDataSourceTests.swift
//  xkcdTests
//
//  Created by Thanh Huy Nguyen on 5/14/22.
//

import XCTest

class URLSessionMock: URLSessionProtocol {
    var requestedUrls = [URL]()
    let expectedResponses: [URL : NSString]
    
    init(expectedResponses: [URL : NSString]) {
        self.expectedResponses = expectedResponses
    }
    
    override func dataTaskPublisher(for url: URL) -> URLSession.DataTaskPublisher {
        requestedUrls.append(url)
        return func dataTaskPublisher(for url: URL) -> URLSession.DataTaskPublisher
    }
}

class RemoteComicDataSourceTests: XCTestCase {
    let apiHost = "http://test.com"
    let infoPath = "info.json"
    let decoder = JSONDecoder()
    var urlSession: URLSession?
    var dataSource: RemoteComicDataSource?

    override func setUpWithError() throws {
        let urlSession = URLSession.shared
        self.urlSession = urlSession
        
        
        
        dataSource = RemoteComicDataSource(withUrlSession: urlSession, decoder: decoder, apiHost: apiHost, infoPath: infoPath)
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testExample() throws {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
        // Any test you write for XCTest can be annotated as throws and async.
        // Mark your test throws to produce an unexpected failure when your test encounters an uncaught error.
        // Mark your test async to allow awaiting for asynchronous code to complete. Check the results with assertions afterwards.
    }

}
