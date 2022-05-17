//
//  ComicDetailView.swift
//  xkcd
//
//  Created by Thanh Huy Nguyen on 5/15/22.
//

import Foundation
import SwiftUI

struct ComicDetailView: View {
    let uiState: ComicItemUIState
    
    var body: some View {
        VStack(alignment: .leading) {
            AsyncImage(url: uiState.imageURL) { image in
                image
                    .resizable()
                    .scaledToFit()
            } placeholder: {
                Color(uiColor: .lightGray)
            }
            .frame(maxWidth: .infinity,
                   maxHeight: .infinity)
            Divider()
            Text(uiState.description)
                .frame(maxWidth: .infinity)
            HStack {
                Button {
                    uiState.bookmarkAction()
                } label: {
                    Text("Bookmark")
                }.disabled(uiState.isBookmarked)
                Spacer()
                NavigationLink(destination: ComicExplainationView(uiState: uiState)) {
                    Text("Explain!")
                }
            }
            .frame(maxWidth: .infinity)
            .padding()
        }
        .padding()
        .navigationBarTitle(Text(uiState.title),
                            displayMode: .inline)
    }
}
