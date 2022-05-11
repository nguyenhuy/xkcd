//
//  MainFeedViewModel.swift
//  xkcd
//
//  Created by Thanh Huy Nguyen on 5/10/22.
//

import Foundation

class MainFeedViewModel {
    let comicsRepository: ComicsRepository
    
    init(comicsRepository: ComicsRepository) {
        self.comicsRepository = comicsRepository
    }
}
