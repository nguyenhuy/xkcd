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
        self.cancellable = repository.comicsPublisher
            .map ({ comics in
                comics.map { comic in
                    ComicItemUIState(id: comic.id,
                                     title: comic.title,
                                     imageURL: comic.imageURL,
                                     description: comic.alternativeText,
                                     explainationURL: URL(string: "https://www.explainxkcd.com/wiki/index.php/\(comic.id)")!,
                                     isBookmarked: false,
                                     bookmarkAction: {[weak self] in
                        _ = self?.repository.bookmark(comic: comic)
                    })
                }
            })
            .map({ states -> [ComicItemUIState] in
                states.map { state in
                    var updatedState = state
                    _ = self.repository.isComicBookmarked(comicId: state.id)
                        .sink { isBookmarked in
                            updatedState = ComicItemUIState(id: state.id,
                                                            title: state.title,
                                                            imageURL: state.imageURL,
                                                            description: state.description,
                                                            explainationURL: state.explainationURL,
                                                            isBookmarked: isBookmarked,
                                                            bookmarkAction: state.bookmarkAction)
                        }
                    return updatedState
                }
            })
            .map({[weak self] comicItemStates in
                guard let self = self else { return ComicListUIState(itemStates: [], errors: [], hasMore: false) }
                
                let errors = self.uiState.errors
                let hasMore = self.repository.hasMore()
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
        repository.refresh()
    }
}
