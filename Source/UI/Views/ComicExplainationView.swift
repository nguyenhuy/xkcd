//
//  ComicExplainationView.swift
//  xkcd
//
//  Created by Thanh Huy Nguyen on 5/15/22.
//

import Foundation
import SwiftUI
import WebKit

struct ComicExplainationView: View {
    let uiState: ComicItemUIState
    
    var body: some View {
        WebView(url: uiState.explainationURL)
            .navigationBarTitle("\(uiState.title) explained",
                                displayMode: .inline)
    }
}

// Reference: https://onmyway133.com/posts/how-to-use-webview-in-swiftui/
struct WebView: UIViewRepresentable {
    typealias UIViewType = WKWebView

    let url: URL
    
    func makeUIView(context: Context) -> WKWebView {
        let view = WKWebView()
        view.load(URLRequest(url: url))
        return view
    }
    
    func updateUIView(_ uiView: WKWebView, context: Context) { }
}
