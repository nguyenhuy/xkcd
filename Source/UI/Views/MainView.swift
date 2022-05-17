//
//  MainView.swift
//  xkcd
//
//  Created by Thanh Huy Nguyen on 5/14/22.
//

import SwiftUI

struct MainView<ListViewModel>: View where ListViewModel: ComicListViewModel {
    let latestComicListViewModel: ListViewModel
    let bookmarkedComicListViewModel: ListViewModel

    var body: some View {
        TabView {
            ComicList(viewModel: latestComicListViewModel).tabItem() {
                Text("Latest Feed")
                Image(systemName: "house")
            }
            ComicList(viewModel: bookmarkedComicListViewModel).tabItem() {
                Text("Bookmarks")
                Image(systemName: "bookmark")
            }
        }
    }
}
