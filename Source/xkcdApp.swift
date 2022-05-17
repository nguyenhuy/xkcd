//
//  xkcdApp.swift
//  xkcd
//
//  Created by Thanh Huy Nguyen on 5/14/22.
//

import SwiftUI

@main
struct xkcdApp: App {
    let latestComicRepository: ComicRepository
    let bookmarkedComicRepository: ComicRepository
    
    init() {
        let remoteDataSource = RemoteComicDataSource()
        let bookmarksDataSource = LocalComicDataSource()
        
        latestComicRepository = ConcreteComicRepository(comicDataSource: remoteDataSource,
                                                        bookmarkedComicDataSource: bookmarksDataSource,
                                                        firstBatchSize: 5,
                                                        normalBatchSize: 10)
        
        bookmarkedComicRepository = ConcreteComicRepository(comicDataSource: bookmarksDataSource,
                                                            bookmarkedComicDataSource: bookmarksDataSource,
                                                            firstBatchSize: 10,
                                                            normalBatchSize: 20)
    }
    
    var body: some Scene {
        let latestComicViewModel = ConcreteComicListViewModel(repository: latestComicRepository)
        let bookmarkedComicViewModel = ConcreteComicListViewModel(repository: bookmarkedComicRepository)
        
        WindowGroup {
            MainView(latestComicListViewModel: latestComicViewModel,
                     bookmarkedComicListViewModel: bookmarkedComicViewModel)
        }
    }
}
