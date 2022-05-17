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
        
        repository.prewarm()
        
        buildUIState(from: repository.comicsPublisher)
    }
    
    func fetchNextBatch() {
        repository.fetchNextBatch()
    }
    
    func refresh() {
        repository.refresh()
    }
    
    private func buildUIState(from publisher: Published<[Comic]>.Publisher) {
        cancellable = publisher.map { comics in
            comics.map {[weak self] comic in
                ComicItemUIState(id: comic.id,
                                 title: comic.title,
                                 imageURL: comic.imageURL,
                                 description: comic.alternativeText,
                                 explainationURL: URL(string: "https://www.explainxkcd.com/wiki/index.php/\(comic.id)")!,
                                 isBookmarked: false,
                                 bookmarkAction: self?.bookmarkAction(for: comic) ?? {})
            }
        }
        .map { states -> [ComicItemUIState] in
            states.map {[weak self] state in
                var updatedState = state
                _ = self?.repository.isComicBookmarked(comicId: state.id)
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
        }
        .map {[weak self] comicItemStates in
            guard let self = self else { return ComicListUIState(itemStates: [], errors: [], hasMore: false) }
                            
            let errors = self.uiState.errors
            let hasMore = self.repository.hasMore
            return ComicListUIState(itemStates: comicItemStates,
                                    errors: errors,
                                    hasMore: hasMore)
        }
        .sink(receiveCompletion: { [weak self] completion in
            self?.objectWillChange.send()
        }, receiveValue: { [weak self] newState in
            self?.uiState = newState
        })
    }
    
    private func bookmarkAction(for comic: Comic) -> (() -> Void){
        return {[weak self] in
            _ = self?.repository.bookmark(comic: comic)
                .sink(receiveCompletion: { _ in }, receiveValue: {[weak self] success in
                    guard success, let self = self else { return }
                    // Rebuild UI state
                    self.buildUIState(from: self.repository.comicsPublisher)
                })
        }
    }
}
