//
//  ConcreteComicListViewModel.swift
//  xkcd
//
//  Created by Thanh Huy Nguyen on 5/15/22.
//

import Foundation
import Combine

class ConcreteComicListViewModel: ComicListViewModel {
    @Published var uiState: ComicListUIState
    private let repository: ComicRepository
    private var cancellable: AnyCancellable?
    
    init(repository: ComicRepository) {
        self.repository = repository
        self.uiState = ComicListUIState(itemStates: [], errors: [], hasMore: false)
        
        let itemStatesPublisher = repository.comicsPublisher
            .map { comics in
                comics.map { comic in
                    ComicItemUIState(id: comic.id,
                                     title: comic.title,
                                     imageURL: comic.imageURL,
                                     description: comic.alternativeText)
                }
            }
        
        cancellable = Publishers.Zip(itemStatesPublisher, repository.errorsPublisher)
            .map({[weak self] (comicItemStates, errors) in
                let hasMore = self?.repository.hasMore() ?? false
                return ComicListUIState(itemStates: comicItemStates,
                                        errors: errors,
                                        hasMore: hasMore)
            })
            .sink(receiveCompletion: { [weak self] completion in
                self?.objectWillChange.send()
            }, receiveValue: { [weak self] newState in
                self?.uiState = newState
            })
        
        repository.prewarm()
    }
    
    func fetchNextBatch() {
        repository.fetchNextBatch()
    }
    
    func refresh() {
        repository.purge()
        repository.fetchNextBatch()
    }
}
