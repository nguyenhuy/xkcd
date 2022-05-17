//
//  ComicList.swift
//  xkcd
//
//  Created by Thanh Huy Nguyen on 5/15/22.
//

import SwiftUI
import Combine

struct ComicRow: View {
    let uiState: ComicItemUIState
    
    var body: some View {
        VStack {
            AsyncImage(url: uiState.imageURL) { image in
                image.resizable()
                    .scaledToFit()
            } placeholder: {
                Color(uiColor: .lightGray)
            }
            .frame(maxWidth: .infinity,
                   idealHeight: 200)
            Text("\(uiState.id): \(uiState.title)")
        }
    }
}

struct ComicList<ViewModel>: View where ViewModel: ComicListViewModel {
    @ObservedObject var viewModel: ViewModel
    let title: String
    
    var body: some View {
        NavigationView {
            List {
                ForEach(viewModel.uiState.itemStates) { itemState in
                    NavigationLink(destination: ComicDetailView(uiState: itemState)) {
                        ComicRow(uiState: itemState)
                    }
                }
                
                if viewModel.uiState.hasMore {
                    ProgressView("Loading...")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .onAppear() {
                            viewModel.fetchNextBatch()
                        }
                }
            }
            .refreshable {
                viewModel.refresh()
            }
            .navigationTitle(Text(title))
        }
    }
}
