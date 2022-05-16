//
//  MainView.swift
//  xkcd
//
//  Created by Thanh Huy Nguyen on 5/14/22.
//

import SwiftUI

struct MainView<LatestComicListViewModel>: View where LatestComicListViewModel: ComicListViewModel {
    let latestComicListViewModel: LatestComicListViewModel

    var body: some View {
        TabView {
            ComicList(viewModel: latestComicListViewModel).tabItem() {
                Text("Latest Feed")
                Image(systemName: "house")
            }
        }
    }
}
