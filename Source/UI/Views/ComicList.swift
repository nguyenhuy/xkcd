//
//  ComicList.swift
//  xkcd
//
//  Created by Thanh Huy Nguyen on 5/15/22.
//

import SwiftUI
import Combine

struct ComicRow: View {
    let itemState: ComicItemUIState
    
    var body: some View {
        VStack {
            AsyncImage(url: itemState.imageURL) { image in
                image.resizable()
                    .scaledToFit()
            } placeholder: {
                Color(uiColor: .lightGray)
            }
            .frame(maxWidth: .infinity,
                   idealHeight: 200)
            Text("\(itemState.id): \(itemState.title)")
        }
    }
}

struct ComicList<ViewModel>: View where ViewModel: ComicListViewModel {
    @ObservedObject var viewModel: ViewModel
    
    var body: some View {
        NavigationView {
            List {
                ForEach(viewModel.uiState.itemStates) { itemState in
                    ComicRow(itemState: itemState)
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
            .navigationTitle(Text("Latest"))
        }
    }
}
