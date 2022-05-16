//
//  xkcdApp.swift
//  xkcd
//
//  Created by Thanh Huy Nguyen on 5/14/22.
//

import SwiftUI

@main
struct xkcdApp: App {
    let latestComicsRepository: ComicRepository
    
    init() {
        latestComicsRepository = ConcreteComicRepository()
    }
    
    var body: some Scene {
        let viewModel = ConcreteComicListViewModel(repository: latestComicsRepository)
        
        WindowGroup {
            MainView(latestComicListViewModel: viewModel)
        }
    }
}
