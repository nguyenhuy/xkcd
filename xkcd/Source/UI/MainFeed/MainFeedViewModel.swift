//
//  MainFeedViewModel.swift
//  xkcd
//
//  Created by Thanh Huy Nguyen on 5/10/22.
//

import Foundation

class MainFeedViewModel {
    let comicRepository: ComicRepository
    
    init(comicRepository: ComicRepository) {
        self.comicRepository = comicRepository
    }
}
