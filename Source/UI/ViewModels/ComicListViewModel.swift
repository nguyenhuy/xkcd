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
    let explainationURL: URL
    let isBookmarked: Bool
    let bookmarkAction: (() -> Void)
}

struct ComicListUIState {
    let itemStates: [ComicItemUIState]
    let errors: [Error]
    let hasMore: Bool
}

protocol ComicListViewModel: ObservableObject {
    /// The UI state of this view model
    var uiState: ComicListUIState { get set }
    
    /// Asks the view model to fetch the next batch of comics
    /// Calling this method when the view model's state is empty will cause it to fetch the first batch.
    /// Calling this method while a batch if fetch is already inflight will do nothing.
    func fetchNextBatch()
    
    /// Asks the view model to refresh its state
    func refresh()
}
