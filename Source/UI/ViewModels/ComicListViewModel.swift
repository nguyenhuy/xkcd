//
//  ComicListViewModel.swift
//  xkcd
//
//  Created by Thanh Huy Nguyen on 5/15/22.
//

import Foundation
import Combine

struct ComicItemUIState: Identifiable {
    let id: Int
    let title: String
    let imageURL: URL
    let description: String
}

struct ComicListUIState {
    let comics: [ComicItemUIState]
    let errors: [Error]
    let hasMore: Bool
}

class ComicListViewModel<Repository>: ObservableObject where Repository: ComicRepository {
    @Published var uiState: ComicListUIState
    private let repository: Repository
    private var cancellable: AnyCancellable?
    
    init(repository: Repository) {
        self.repository = repository
        self.uiState = ComicListUIState(comics: [], errors: [], hasMore: false)
        
        let itemStatesPublisher = repository.comics.publisher
            .map { comic in
                ComicItemUIState(id: comic.id,
                                 title: comic.title,
                                 imageURL: comic.imageURL,
                                 description: comic.alternativeText)
            }
        
        cancellable = Publishers.Zip(itemStatesPublisher.collect(), repository.errors.publisher.collect())
            .map({[weak self] (comicItemStates, errors) in
                let hasMore = self?.repository.hasMore() ?? false
                return ComicListUIState(comics: comicItemStates,
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
